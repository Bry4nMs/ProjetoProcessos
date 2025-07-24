-- ADICIONAR FUNÇÕES RPC PARA BUSCAR PROCESSOS COM PROGRESSO
-- Execute este script no SQL Editor do Supabase

-- Função para buscar todos os processos com informações de progresso
CREATE OR REPLACE FUNCTION public.get_processes_with_progress(p_user_id UUID)
RETURNS SETOF json AS $$
DECLARE
    processo record;
    etapa_atual record;
    total_etapas integer;
    etapa_atual_idx integer;
    resultado json;
BEGIN
    FOR processo IN 
        SELECT p.*, 
               rf.id as rf_id, rf.code as rf_code, 
               ta.id as ta_id, ta.code as ta_code
        FROM public.processes p
        LEFT JOIN public.responsible_forces rf ON p.responsible_force_id = rf.id
        LEFT JOIN public.thematic_areas ta ON p.thematic_area_id = ta.id
        WHERE p.deleted_at IS NULL
        ORDER BY p.created_at DESC
    LOOP
        -- Contar total de etapas
        SELECT COUNT(*) INTO total_etapas 
        FROM public.process_steps 
        WHERE process_id = processo.id;
        
        -- Buscar etapa atual
        SELECT ps.*, st.name as step_name INTO etapa_atual 
        FROM public.process_steps ps
        LEFT JOIN public.step_templates st ON ps.step_template_id = st.id
        WHERE ps.process_id = processo.id AND ps.is_current = true;
        
        -- Buscar índice da etapa atual
        IF etapa_atual.id IS NOT NULL THEN
            SELECT step_order INTO etapa_atual_idx 
            FROM public.process_steps 
            WHERE id = etapa_atual.id;
        ELSE
            etapa_atual_idx := 0;
        END IF;
        
        -- Construir objeto JSON com todas as informações
        resultado := json_build_object(
            'id', processo.id,
            'user_id', processo.user_id,
            'nome_acao', processo.nome_acao,
            'thematic_area_id', processo.thematic_area_id,
            'area_tematica', processo.thematic_area_id,
            'ano_faf', processo.ano_faf,
            'tipo_natureza_despesa', processo.tipo_natureza_despesa,
            'responsible_force_id', processo.responsible_force_id,
            'forca_responsavel', processo.responsible_force_id,
            'valor_inicial_padrao', processo.valor_inicial_padrao,
            'data_encaminhamento_aprovacao', processo.data_encaminhamento_aprovacao,
            'codigo_transferegov', processo.codigo_transferegov,
            'qtd_itens', processo.qtd_itens,
            'descricao_itens', processo.descricao_itens,
            'destinacao_itens', processo.destinacao_itens,
            'valor_rendimentos', processo.valor_rendimentos,
            'valor_economicidade', processo.valor_economicidade,
            'valor_total_destinado', processo.valor_total_destinado,
            'descricao_geral', processo.descricao_geral,
            'status', processo.status,
            'etapaAtual', etapa_atual_idx,
            'totalEtapas', total_etapas,
            'etapaAtualNome', etapa_atual.step_name,
            'current_step_name', etapa_atual.step_name,
            'responsible_forces', json_build_object('id', processo.rf_id, 'code', processo.rf_code),
            'thematic_areas', json_build_object('id', processo.ta_id, 'code', processo.ta_code)
        );
        
        RETURN NEXT resultado;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Função para buscar processos favoritados com informações de progresso
CREATE OR REPLACE FUNCTION public.get_favorited_processes_with_progress(p_user_id UUID)
RETURNS SETOF json AS $$
DECLARE
    processo record;
    etapa_atual record;
    total_etapas integer;
    etapa_atual_idx integer;
    resultado json;
BEGIN
    FOR processo IN 
        SELECT p.*, 
               rf.id as rf_id, rf.code as rf_code, 
               ta.id as ta_id, ta.code as ta_code
        FROM public.processes p
        LEFT JOIN public.responsible_forces rf ON p.responsible_force_id = rf.id
        LEFT JOIN public.thematic_areas ta ON p.thematic_area_id = ta.id
        JOIN public.user_favorites uf ON p.id = uf.process_id AND uf.user_id = p_user_id
        WHERE p.deleted_at IS NULL
        ORDER BY p.created_at DESC
    LOOP
        -- Contar total de etapas
        SELECT COUNT(*) INTO total_etapas 
        FROM public.process_steps 
        WHERE process_id = processo.id;
        
        -- Buscar etapa atual
        SELECT ps.*, st.name as step_name INTO etapa_atual 
        FROM public.process_steps ps
        LEFT JOIN public.step_templates st ON ps.step_template_id = st.id
        WHERE ps.process_id = processo.id AND ps.is_current = true;
        
        -- Buscar índice da etapa atual
        IF etapa_atual.id IS NOT NULL THEN
            SELECT step_order INTO etapa_atual_idx 
            FROM public.process_steps 
            WHERE id = etapa_atual.id;
        ELSE
            etapa_atual_idx := 0;
        END IF;
        
        -- Construir objeto JSON com todas as informações
        resultado := json_build_object(
            'id', processo.id,
            'user_id', processo.user_id,
            'nome_acao', processo.nome_acao,
            'thematic_area_id', processo.thematic_area_id,
            'area_tematica', processo.thematic_area_id,
            'ano_faf', processo.ano_faf,
            'tipo_natureza_despesa', processo.tipo_natureza_despesa,
            'responsible_force_id', processo.responsible_force_id,
            'forca_responsavel', processo.responsible_force_id,
            'valor_inicial_padrao', processo.valor_inicial_padrao,
            'data_encaminhamento_aprovacao', processo.data_encaminhamento_aprovacao,
            'codigo_transferegov', processo.codigo_transferegov,
            'qtd_itens', processo.qtd_itens,
            'descricao_itens', processo.descricao_itens,
            'destinacao_itens', processo.destinacao_itens,
            'valor_rendimentos', processo.valor_rendimentos,
            'valor_economicidade', processo.valor_economicidade,
            'valor_total_destinado', processo.valor_total_destinado,
            'descricao_geral', processo.descricao_geral,
            'status', processo.status,
            'etapaAtual', etapa_atual_idx,
            'totalEtapas', total_etapas,
            'etapaAtualNome', etapa_atual.step_name,
            'current_step_name', etapa_atual.step_name,
            'responsible_forces', json_build_object('id', processo.rf_id, 'code', processo.rf_code),
            'thematic_areas', json_build_object('id', processo.ta_id, 'code', processo.ta_code)
        );
        
        RETURN NEXT resultado;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- Verificar se as funções foram criadas corretamente
SELECT 'Função get_processes_with_progress criada' as status WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_processes_with_progress');
SELECT 'Função get_favorited_processes_with_progress criada' as status WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_favorited_processes_with_progress');