-- ADICIONAR COLUNA STORAGE_PATH À TABELA DOCUMENTS
-- Execute este script se a tabela documents já existe

-- 1. Adicionar coluna storage_path se não existir
ALTER TABLE public.documents 
ADD COLUMN IF NOT EXISTS storage_path text;

-- 2. Adicionar colunas file_size e mime_type se não existirem
ALTER TABLE public.documents 
ADD COLUMN IF NOT EXISTS file_size integer;

ALTER TABLE public.documents 
ADD COLUMN IF NOT EXISTS mime_type character varying;

-- 3. Tornar storage_path obrigatório (após adicionar)
-- ALTER TABLE public.documents ALTER COLUMN storage_path SET NOT NULL;

-- 4. Adicionar comentários
COMMENT ON COLUMN public.documents.storage_path IS 'Caminho do arquivo no storage do Supabase';
COMMENT ON COLUMN public.documents.file_size IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN public.documents.mime_type IS 'Tipo MIME do arquivo';

-- 5. Verificar estrutura da tabela
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'documents' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 6. Confirmar que tudo foi adicionado
SELECT 'Colunas adicionadas com sucesso!' as status; 