-- =====================================================
-- PASSO 2.2: FUNÇÃO RPC PARA BUSCAR REGISTROS DE AÇÃO
-- Funcionalidade: Controle de Ações
-- Retorna dados completos de uma ação e seus processos
-- =====================================================

-- Função principal para buscar registros de uma ação
CREATE OR REPLACE FUNCTION public.get_records_for_action(p_action_id UUID)
RETURNS JSON AS $$
DECLARE
    v_action_data JSON;
    v_processes_data JSON;
    v_statistics JSON;
    v_result JSON;
BEGIN
    -- Buscar dados da ação
    SELECT json_build_object(
        'id', a.id,
        'name', a.name,
        'action_code', a.action_code,
        'year', a.year,
        'expense_nature', a.expense_nature,
        'created_at', a.created_at,
        'updated_at', a.updated_at,
        'user_id', a.user_id,
        'thematic_area', json_build_object(
            'id', ta.id,
            'code', ta.code
        ),
        'responsible_force', json_build_object(
            'id', rf.id,
            'code', rf.code
        )
    ) INTO v_action_data
    FROM public.actions a
    LEFT JOIN public.thematic_areas ta ON a.thematic_area_id = ta.id
    LEFT JOIN public.responsible_forces rf ON a.responsible_force_id = rf.id
    WHERE a.id = p_action_id;
    
    -- Verificar se a ação existe
    IF v_action_data IS NULL THEN
        RETURN json_build_object('error', 'Ação não encontrada');
    END IF;
    
    -- Buscar processos vinculados à ação
    SELECT json_agg(
        json_build_object(
            'id', p.id,
            'name', p.name,
            'process_number', p.process_number,
            'description', p.description,
            'created_at', p.created_at,
            'updated_at', p.updated_at,
            'current_step', p.current_step,
            'total_steps', p.total_steps,
            'progress_percentage', ROUND((p.current_step::DECIMAL / NULLIF(p.total_steps, 0)) * 100, 2),
            'status', CASE 
                WHEN p.current_step >= p.total_steps THEN 'Concluído'
                WHEN p.current_step > 0 THEN 'Em Andamento'
                ELSE 'Não Iniciado'
            END,
            'thematic_area', json_build_object(
                'id', ta.id,
                'code', ta.code
            ),
            'responsible_force', json_build_object(
                'id', rf.id,
                'code', rf.code
            )
        )
    ) INTO v_processes_data
    FROM public.processes p
    LEFT JOIN public.thematic_areas ta ON p.thematic_area_id = ta.id
    LEFT JOIN public.responsible_forces rf ON p.responsible_force_id = rf.id
    WHERE p.action_id = p_action_id
    ORDER BY p.created_at DESC;
    
    -- Se não há processos, retornar array vazio
    IF v_processes_data IS NULL THEN
        v_processes_data := '[]'::JSON;
    END IF;
    
    -- Calcular estatísticas
    SELECT json_build_object(
        'total_processes', COUNT(*),
        'completed_processes', COUNT(*) FILTER (WHERE current_step >= total_steps),
        'in_progress_processes', COUNT(*) FILTER (WHERE current_step > 0 AND current_step < total_steps),
        'not_started_processes', COUNT(*) FILTER (WHERE current_step = 0),
        'average_progress', ROUND(AVG(
            CASE 
                WHEN total_steps > 0 THEN (current_step::DECIMAL / total_steps) * 100
                ELSE 0
            END
        ), 2),
        'completion_rate', ROUND(
            (COUNT(*) FILTER (WHERE current_step >= total_steps)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 2
        )
    ) INTO v_statistics
    FROM public.processes
    WHERE action_id = p_action_id;
    
    -- Se não há processos, definir estatísticas zeradas
    IF v_statistics IS NULL THEN
        v_statistics := json_build_object(
            'total_processes', 0,
            'completed_processes', 0,
            'in_progress_processes', 0,
            'not_started_processes', 0,
            'average_progress', 0,
            'completion_rate', 0
        );
    END IF;
    
    -- Montar resultado final
    v_result := json_build_object(
        'action', v_action_data,
        'processes', v_processes_data,
        'statistics', v_statistics,
        'generated_at', NOW()
    );
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', 'Erro ao buscar registros da ação: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNÇÃO PARA LISTAR TODAS AS AÇÕES COM ESTATÍSTICAS
-- =====================================================

-- Função para listar todas as ações com estatísticas resumidas
CREATE OR REPLACE FUNCTION public.get_all_actions_with_stats(
    p_year INTEGER DEFAULT NULL,
    p_thematic_area_id INTEGER DEFAULT NULL,
    p_responsible_force_id INTEGER DEFAULT NULL,
    p_expense_nature TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_actions JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', a.id,
            'name', a.name,
            'action_code', a.action_code,
            'year', a.year,
            'expense_nature', a.expense_nature,
            'created_at', a.created_at,
            'updated_at', a.updated_at,
            'thematic_area', json_build_object(
                'id', ta.id,
                'code', ta.code
            ),
            'responsible_force', json_build_object(
                'id', rf.id,
                'code', rf.code
            ),
            'statistics', json_build_object(
                'total_processes', COALESCE(stats.total_processes, 0),
                'completed_processes', COALESCE(stats.completed_processes, 0),
                'completion_rate', COALESCE(stats.completion_rate, 0)
            )
        )
        ORDER BY a.created_at DESC
    ) INTO v_actions
    FROM public.actions a
    LEFT JOIN public.thematic_areas ta ON a.thematic_area_id = ta.id
    LEFT JOIN public.responsible_forces rf ON a.responsible_force_id = rf.id
    LEFT JOIN (
        SELECT 
            action_id,
            COUNT(*) as total_processes,
            COUNT(*) FILTER (WHERE current_step >= total_steps) as completed_processes,
            ROUND(
                (COUNT(*) FILTER (WHERE current_step >= total_steps)::DECIMAL / NULLIF(COUNT(*), 0)) * 100, 2
            ) as completion_rate
        FROM public.processes
        WHERE action_id IS NOT NULL
        GROUP BY action_id
    ) stats ON a.id = stats.action_id
    WHERE 
        (p_year IS NULL OR a.year = p_year)
        AND (p_thematic_area_id IS NULL OR a.thematic_area_id = p_thematic_area_id)
        AND (p_responsible_force_id IS NULL OR a.responsible_force_id = p_responsible_force_id)
        AND (p_expense_nature IS NULL OR a.expense_nature = p_expense_nature);
    
    -- Se não há ações, retornar array vazio
    IF v_actions IS NULL THEN
        v_actions := '[]'::JSON;
    END IF;
    
    RETURN json_build_object(
        'actions', v_actions,
        'generated_at', NOW()
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', 'Erro ao buscar ações: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNÇÃO PARA BUSCAR PROCESSOS SEM AÇÃO VINCULADA
-- =====================================================

-- Função para listar processos que não estão vinculados a nenhuma ação
CREATE OR REPLACE FUNCTION public.get_processes_without_action()
RETURNS JSON AS $$
DECLARE
    v_processes JSON;
BEGIN
    SELECT json_agg(
        json_build_object(
            'id', p.id,
            'name', p.name,
            'process_number', p.process_number,
            'description', p.description,
            'created_at', p.created_at,
            'current_step', p.current_step,
            'total_steps', p.total_steps,
            'progress_percentage', ROUND((p.current_step::DECIMAL / NULLIF(p.total_steps, 0)) * 100, 2),
            'thematic_area', json_build_object(
                'id', ta.id,
                'code', ta.code
            ),
            'responsible_force', json_build_object(
                'id', rf.id,
                'code', rf.code
            )
        )
        ORDER BY p.created_at DESC
    ) INTO v_processes
    FROM public.processes p
    LEFT JOIN public.thematic_areas ta ON p.thematic_area_id = ta.id
    LEFT JOIN public.responsible_forces rf ON p.responsible_force_id = rf.id
    WHERE p.action_id IS NULL;
    
    -- Se não há processos, retornar array vazio
    IF v_processes IS NULL THEN
        v_processes := '[]'::JSON;
    END IF;
    
    RETURN json_build_object(
        'processes', v_processes,
        'generated_at', NOW()
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', 'Erro ao buscar processos sem ação: ' || SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- EXEMPLOS DE USO E TESTES
-- =====================================================

-- Exemplos de uso das funções (comentado para não executar automaticamente)
/*
-- Buscar registros de uma ação específica
SELECT public.get_records_for_action('uuid-da-acao-aqui');

-- Listar todas as ações com estatísticas
SELECT public.get_all_actions_with_stats();

-- Listar ações filtradas por ano
SELECT public.get_all_actions_with_stats(2024);

-- Listar ações filtradas por área temática
SELECT public.get_all_actions_with_stats(NULL, 1);

-- Buscar processos sem ação vinculada
SELECT public.get_processes_without_action();
*/

-- =====================================================
-- VERIFICAÇÃO DA CRIAÇÃO
-- =====================================================

-- Verificar se as funções foram criadas corretamente
SELECT 'Função get_records_for_action criada com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_records_for_action');

SELECT 'Função get_all_actions_with_stats criada com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_all_actions_with_stats');

SELECT 'Função get_processes_without_action criada com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_processes_without_action');

-- =====================================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =====================================================

COMMENT ON FUNCTION public.get_records_for_action(UUID) IS 'Busca dados completos de uma ação e seus processos vinculados';
COMMENT ON FUNCTION public.get_all_actions_with_stats(INTEGER, INTEGER, INTEGER, TEXT) IS 'Lista todas as ações com estatísticas resumidas e filtros opcionais';
COMMENT ON FUNCTION public.get_processes_without_action() IS 'Lista processos que não estão vinculados a nenhuma ação';

-- =====================================================
-- OBSERVAÇÕES IMPORTANTES
-- =====================================================

/*
Essas funções RPC fornecem:

1. get_records_for_action(action_id):
   - Dados completos da ação
   - Lista de processos vinculados
   - Estatísticas de progresso
   - Informações de área temática e força responsável

2. get_all_actions_with_stats(filtros opcionais):
   - Lista todas as ações com estatísticas resumidas
   - Filtros por ano, área temática, força responsável e natureza da despesa
   - Contadores de processos e taxa de conclusão

3. get_processes_without_action():
   - Lista processos não vinculados a ações
   - Útil para identificar processos que precisam ser agrupados

Todas as funções retornam JSON para facilitar o consumo no frontend.
*/