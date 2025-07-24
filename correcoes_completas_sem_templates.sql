-- CORREÇÕES COMPLETAS PARA ALINHAR O CÓDIGO COM O SCHEMA DO BANCO
-- Execute estes comandos no seu banco de dados Supabase

-- 1. Adicionar a coluna 'nome_acao' que estava faltando
ALTER TABLE public.processes 
ADD COLUMN IF NOT EXISTS nome_acao character varying;

-- 2. Adicionar a coluna 'status' que está sendo usada no código mas não existe no schema
ALTER TABLE public.processes 
ADD COLUMN IF NOT EXISTS status character varying DEFAULT 'Em Andamento';

-- 3. Verificar se a sequência step_templates_id_seq existe, se não, criar
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

-- 4. Comentários para documentar as colunas
COMMENT ON COLUMN public.processes.nome_acao IS 'Nome da ação do processo';
COMMENT ON COLUMN public.processes.status IS 'Status atual do processo (Em Andamento, Concluído, etc.)';

-- 5. Verificar se o bucket 'documents' existe no storage
-- (Execute isso no SQL Editor do Supabase se necessário)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', true)
-- ON CONFLICT (id) DO NOTHING; 