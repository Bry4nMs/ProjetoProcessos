-- CONFIGURAÇÃO CORRIGIDA DO SUPABASE PARA O PROJETO DE PROCESSOS
-- Execute este arquivo no SQL Editor do Supabase

-- =====================================================
-- 1. CONFIGURAÇÃO DO STORAGE
-- =====================================================

-- Criar bucket 'documents' se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('documents', 'documents', true, 52428800, ARRAY['application/pdf', 'image/*', 'text/*', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 2. TABELAS PRINCIPAIS
-- =====================================================

-- Tabela de processos (se não existir)
CREATE TABLE IF NOT EXISTS public.processes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_acao character varying,
    area_tematica character varying,
    ano_faf integer,
    tipo_natureza_despesa character varying,
    forca_responsavel character varying,
    valor_inicial_padrao numeric(15,2),
    data_encaminhamento_aprovacao date,
    codigo_transferegov character varying,
    qtd_itens integer,
    descricao_itens text,
    destinacao_itens text,
    valor_rendimentos numeric(15,2),
    valor_economicidade numeric(15,2),
    valor_total_destinado numeric(15,2),
    descricao_geral text,
    status character varying DEFAULT 'Em Andamento',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Tabela de templates de etapas (se não existir)
CREATE TABLE IF NOT EXISTS public.step_templates (
    id integer PRIMARY KEY,
    name character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- Tabela de etapas dos processos (se não existir)
CREATE TABLE IF NOT EXISTS public.process_steps (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    process_id uuid REFERENCES public.processes(id) ON DELETE CASCADE,
    step_template_id integer REFERENCES public.step_templates(id),
    step_order integer NOT NULL,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    is_current boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Tabela de documentos (se não existir)
CREATE TABLE IF NOT EXISTS public.documents (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    process_id uuid REFERENCES public.processes(id) ON DELETE CASCADE,
    filename character varying NOT NULL,
    file_url text NOT NULL,
    file_size integer,
    mime_type character varying,
    storage_path text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- 3. SEQUÊNCIAS
-- =====================================================

-- Sequência para step_templates se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'step_templates_id_seq') THEN
        CREATE SEQUENCE public.step_templates_id_seq
            INCREMENT 1
            START 1
            MINVALUE 1
            MAXVALUE 2147483647
            CACHE 1;
    END IF;
END $$;

-- =====================================================
-- 4. DADOS INICIAIS
-- =====================================================

-- Inserir templates de etapas básicos
INSERT INTO public.step_templates (id, name) VALUES 
    (1, 'Análise Inicial'),
    (2, 'Aprovação Técnica'),
    (3, 'Aprovação Financeira'),
    (4, 'Execução'),
    (5, 'Conclusão')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 5. FUNÇÕES E TRIGGERS
-- =====================================================

-- Função para criar etapas automaticamente quando um processo é criado
CREATE OR REPLACE FUNCTION create_process_steps()
RETURNS TRIGGER AS $$
BEGIN
    -- Inserir etapas baseadas nos templates
    INSERT INTO public.process_steps (process_id, step_template_id, step_order, is_current)
    SELECT 
        NEW.id,
        st.id,
        st.id,
        CASE WHEN st.id = 1 THEN true ELSE false END
    FROM public.step_templates st
    ORDER BY st.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para criar etapas automaticamente
DROP TRIGGER IF EXISTS trigger_create_process_steps ON public.processes;
CREATE TRIGGER trigger_create_process_steps
    AFTER INSERT ON public.processes
    FOR EACH ROW
    EXECUTE FUNCTION create_process_steps();

-- Função RPC para avançar etapas (atômica)
CREATE OR REPLACE FUNCTION avancar_etapa(processo_id uuid)
RETURNS json AS $$
DECLARE
    etapa_atual record;
    proxima_etapa record;
    total_etapas integer;
    etapa_atual_idx integer;
BEGIN
    -- Buscar etapa atual
    SELECT * INTO etapa_atual 
    FROM public.process_steps 
    WHERE process_id = processo_id AND is_current = true;
    
    IF NOT FOUND THEN
        RETURN json_build_object('error', 'Nenhuma etapa atual encontrada');
    END IF;
    
    -- Contar total de etapas
    SELECT COUNT(*) INTO total_etapas 
    FROM public.process_steps 
    WHERE process_id = processo_id;
    
    -- Buscar índice da etapa atual
    SELECT step_order INTO etapa_atual_idx 
    FROM public.process_steps 
    WHERE id = etapa_atual.id;
    
    -- Finalizar etapa atual
    UPDATE public.process_steps 
    SET ended_at = now(), is_current = false 
    WHERE id = etapa_atual.id;
    
    -- Se não for a última etapa, iniciar próxima
    IF etapa_atual_idx < total_etapas THEN
        SELECT * INTO proxima_etapa 
        FROM public.process_steps 
        WHERE process_id = processo_id AND step_order = etapa_atual_idx + 1;
        
        UPDATE public.process_steps 
        SET started_at = now(), is_current = true 
        WHERE id = proxima_etapa.id;
    ELSE
        -- Se for a última etapa, marcar processo como concluído
        UPDATE public.processes 
        SET status = 'Concluído' 
        WHERE id = processo_id;
    END IF;
    
    RETURN json_build_object('success', true);
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. POLÍTICAS DE SEGURANÇA (RLS)
-- =====================================================

-- Habilitar RLS nas tabelas
ALTER TABLE public.processes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.process_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.step_templates ENABLE ROW LEVEL SECURITY;

-- Políticas para processes (todos os usuários podem ver todos os processos)
CREATE POLICY "Todos podem ver processos" ON public.processes
    FOR SELECT USING (true);

CREATE POLICY "Usuários autenticados podem inserir processos" ON public.processes
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Usuários autenticados podem atualizar processos" ON public.processes
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Políticas para process_steps
CREATE POLICY "Todos podem ver etapas" ON public.process_steps
    FOR SELECT USING (true);

CREATE POLICY "Usuários autenticados podem inserir etapas" ON public.process_steps
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Usuários autenticados podem atualizar etapas" ON public.process_steps
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Políticas para documents
CREATE POLICY "Todos podem ver documentos" ON public.documents
    FOR SELECT USING (true);

CREATE POLICY "Usuários autenticados podem inserir documentos" ON public.documents
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Usuários autenticados podem deletar documentos" ON public.documents
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Políticas para step_templates (somente leitura)
CREATE POLICY "Todos podem ver templates" ON public.step_templates
    FOR SELECT USING (true);

-- Políticas para storage
CREATE POLICY "Todos podem ver arquivos" ON storage.objects
    FOR SELECT USING (bucket_id = 'documents');

CREATE POLICY "Usuários autenticados podem inserir arquivos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.uid() IS NOT NULL);

CREATE POLICY "Usuários autenticados podem deletar arquivos" ON storage.objects
    FOR DELETE USING (bucket_id = 'documents' AND auth.uid() IS NOT NULL);

-- =====================================================
-- 7. ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para melhorar performance das consultas
CREATE INDEX IF NOT EXISTS idx_processes_user_id ON public.processes(user_id);
CREATE INDEX IF NOT EXISTS idx_processes_status ON public.processes(status);
CREATE INDEX IF NOT EXISTS idx_processes_created_at ON public.processes(created_at);
CREATE INDEX IF NOT EXISTS idx_process_steps_process_id ON public.process_steps(process_id);
CREATE INDEX IF NOT EXISTS idx_process_steps_is_current ON public.process_steps(is_current);
CREATE INDEX IF NOT EXISTS idx_documents_process_id ON public.documents(process_id);

-- =====================================================
-- 8. COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =====================================================

COMMENT ON TABLE public.processes IS 'Tabela principal de processos';
COMMENT ON COLUMN public.processes.nome_acao IS 'Nome da ação do processo';
COMMENT ON COLUMN public.processes.status IS 'Status atual do processo (Em Andamento, Concluído, etc.)';
COMMENT ON COLUMN public.processes.area_tematica IS 'Área temática do processo (VPSP, ECV, FISP, etc.)';
COMMENT ON COLUMN public.processes.tipo_natureza_despesa IS 'Tipo de natureza da despesa (Custeio, Investimento)';
COMMENT ON COLUMN public.processes.valor_inicial_padrao IS 'Valor inicial padrão do processo';
COMMENT ON COLUMN public.processes.data_encaminhamento_aprovacao IS 'Data de encaminhamento para aprovação do MJSP';
COMMENT ON COLUMN public.processes.forca_responsavel IS 'Força responsável (PMGO, PCGO, CBMGO, etc.)';

COMMENT ON TABLE public.process_steps IS 'Etapas de cada processo';
COMMENT ON COLUMN public.process_steps.is_current IS 'Indica se esta é a etapa atual do processo';
COMMENT ON COLUMN public.process_steps.step_order IS 'Ordem da etapa no processo';

COMMENT ON TABLE public.documents IS 'Documentos anexados aos processos';
COMMENT ON COLUMN public.documents.file_url IS 'URL pública do arquivo no storage';
COMMENT ON COLUMN public.documents.storage_path IS 'Caminho do arquivo no storage do Supabase';
COMMENT ON COLUMN public.documents.file_size IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN public.documents.mime_type IS 'Tipo MIME do arquivo';

COMMENT ON TABLE public.step_templates IS 'Templates de etapas padrão';
COMMENT ON COLUMN public.step_templates.name IS 'Nome da etapa (Análise Inicial, Aprovação Técnica, etc.)';

-- =====================================================
-- 9. VERIFICAÇÕES FINAIS
-- =====================================================

-- Verificar se tudo foi criado corretamente
SELECT 'Storage bucket criado' as status WHERE EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'documents')
UNION ALL
SELECT 'Tabela processes criada' as status WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'processes')
UNION ALL
SELECT 'Tabela process_steps criada' as status WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'process_steps')
UNION ALL
SELECT 'Tabela documents criada' as status WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'documents')
UNION ALL
SELECT 'Tabela step_templates criada' as status WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'step_templates')
UNION ALL
SELECT 'Função avancar_etapa criada' as status WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'avancar_etapa')
UNION ALL
SELECT 'Trigger create_process_steps criado' as status WHERE EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_create_process_steps'); 