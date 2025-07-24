-- VERSÃO ALTERNATIVA DAS FUNÇÕES RPC USANDO CTE (MAIS EFICIENTE)
-- Execute este script no SQL Editor do Supabase

-- Função para buscar todos os processos com informações de progresso (versão CTE)
CREATE OR REPLACE FUNCTION public.get_processes_with_progress(p_user_id UUID)
RETURNS SETOF json AS $$
BEGIN
    RETURN QUERY
    WITH progress_data AS (
        SELECT
            ps.process_id,
            COUNT(*)::bigint AS total_etapas,
            COALESCE(
                (SELECT ps_current.step_order - 1
                 FROM process_steps AS ps_current
                 WHERE ps_current.process_id = ps.process_id AND ps_current.is_current = true
                 LIMIT 1),
                0
            )::bigint AS etapa_atual_index,
            COALESCE(
                (SELECT st.name
                 FROM process_steps AS ps_current
                 JOIN step_templates AS st ON ps_current.step_template_id = st.id
                 WHERE ps_current.process_id = ps.process_id AND ps_current.is_current = true
                 LIMIT 1),
                ''
            ) AS etapa_atual_nome
        FROM
            process_steps AS ps
        GROUP BY
            ps.process_id
    )
    SELECT
        json_build_object(
            'id', p.id,
            'user_id', p.user_id,
            'nome_acao', p.nome_acao,
            'thematic_area_id', p.thematic_area_id,
            'area_tematica', p.thematic_area_id,
            'ano_faf', p.ano_faf,
            'tipo_natureza_despesa', p.tipo_natureza_despesa,
            'responsible_force_id', p.responsible_force_id,
            'forca_responsavel', p.responsible_force_id,
            'valor_inicial_padrao', p.valor_inicial_padrao,
            'data_encaminhamento_aprovacao', p.data_encaminhamento_aprovacao,
            'codigo_transferegov', p.codigo_transferegov,
            'qtd_itens', p.qtd_itens,
            'descricao_itens', p.descricao_itens,
            'destinacao_itens', p.destinacao_itens,
            'valor_rendimentos', p.valor_rendimentos,
            'valor_economicidade', p.valor_economicidade,
            'valor_total_destinado', p.valor_total_destinado,
            'descricao_geral', p.descricao_geral,
            'status', p.status,
            'created_at', p.created_at,
            'updated_by', p.updated_by,
            'deleted_at', p.deleted_at,
            'totalEtapas', COALESCE(pd.total_etapas, 0),
            'etapaAtual', COALESCE(pd.etapa_atual_index, 0),
            'etapaAtualNome', pd.etapa_atual_nome,
            'responsible_forces', json_build_object('id', rf.id, 'code', rf.code),
            'thematic_areas', json_build_object('id', ta.id, 'code', ta.code),
            'is_favorited', EXISTS(SELECT 1 FROM user_favorites uf WHERE uf.process_id = p.id AND uf.user_id = p_user_id)
        )
    FROM
        processes AS p
    LEFT JOIN
        progress_data AS pd ON p.id = pd.process_id
    LEFT JOIN
        responsible_forces AS rf ON p.responsible_force_id = rf.id
    LEFT JOIN
        thematic_areas AS ta ON p.thematic_area_id = ta.id
    WHERE
        p.deleted_at IS NULL
    ORDER BY
        p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Função para buscar processos favoritados com informações de progresso (versão CTE)
CREATE OR REPLACE FUNCTION public.get_favorited_processes_with_progress(p_user_id UUID)
RETURNS SETOF json AS $$
BEGIN
    RETURN QUERY
    WITH progress_data AS (
        SELECT
            ps.process_id,
            COUNT(*)::bigint AS total_etapas,
            COALESCE(
                (SELECT ps_current.step_order - 1
                 FROM process_steps AS ps_current
                 WHERE ps_current.process_id = ps.process_id AND ps_current.is_current = true
                 LIMIT 1),
                0
            )::bigint AS etapa_atual_index,
            COALESCE(
                (SELECT st.name
                 FROM process_steps AS ps_current
                 JOIN step_templates AS st ON ps_current.step_template_id = st.id
                 WHERE ps_current.process_id = ps.process_id AND ps_current.is_current = true
                 LIMIT 1),
                ''
            ) AS etapa_atual_nome
        FROM
            process_steps AS ps
        GROUP BY
            ps.process_id
    )
    SELECT
        json_build_object(
            'id', p.id,
            'user_id', p.user_id,
            'nome_acao', p.nome_acao,
            'thematic_area_id', p.thematic_area_id,
            'area_tematica', p.thematic_area_id,
            'ano_faf', p.ano_faf,
            'tipo_natureza_despesa', p.tipo_natureza_despesa,
            'responsible_force_id', p.responsible_force_id,
            'forca_responsavel', p.responsible_force_id,
            'valor_inicial_padrao', p.valor_inicial_padrao,
            'data_encaminhamento_aprovacao', p.data_encaminhamento_aprovacao,
            'codigo_transferegov', p.codigo_transferegov,
            'qtd_itens', p.qtd_itens,
            'descricao_itens', p.descricao_itens,
            'destinacao_itens', p.destinacao_itens,
            'valor_rendimentos', p.valor_rendimentos,
            'valor_economicidade', p.valor_economicidade,
            'valor_total_destinado', p.valor_total_destinado,
            'descricao_geral', p.descricao_geral,
            'status', p.status,
            'created_at', p.created_at,
            'updated_by', p.updated_by,
            'deleted_at', p.deleted_at,
            'totalEtapas', COALESCE(pd.total_etapas, 0),
            'etapaAtual', COALESCE(pd.etapa_atual_index, 0),
            'etapaAtualNome', pd.etapa_atual_nome,
            'responsible_forces', json_build_object('id', rf.id, 'code', rf.code),
            'thematic_areas', json_build_object('id', ta.id, 'code', ta.code),
            'is_favorited', true
        )
    FROM
        processes AS p
    JOIN
        user_favorites uf ON p.id = uf.process_id AND uf.user_id = p_user_id
    LEFT JOIN
        progress_data AS pd ON p.id = pd.process_id
    LEFT JOIN
        responsible_forces AS rf ON p.responsible_force_id = rf.id
    LEFT JOIN
        thematic_areas AS ta ON p.thematic_area_id = ta.id
    WHERE
        p.deleted_at IS NULL
    ORDER BY
        p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Verificar se as funções foram criadas corretamente
SELECT 'Função get_processes_with_progress (CTE) criada' as status WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_processes_with_progress');
SELECT 'Função get_favorited_processes_with_progress (CTE) criada' as status WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_favorited_processes_with_progress');