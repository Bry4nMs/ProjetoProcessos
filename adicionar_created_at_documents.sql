-- ADICIONAR COLUNA CREATED_AT À TABELA DOCUMENTS
-- Execute este script se a tabela documents não tem a coluna created_at

-- 1. Adicionar coluna created_at se não existir
ALTER TABLE public.documents 
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now();

-- 2. Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'documents' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Adicionar comentário
COMMENT ON COLUMN public.documents.created_at IS 'Data e hora de criação do documento';

-- 4. Confirmar que tudo foi adicionado
SELECT 'Coluna created_at adicionada com sucesso!' as status; 