-- ATUALIZAR ESTRUTURA DA TABELA PROCESSES
-- Execute este script se a tabela já existe e precisa ser atualizada

-- 1. Renomear colunas existentes
ALTER TABLE public.processes 
RENAME COLUMN tipo_natureza TO tipo_natureza_despesa;

ALTER TABLE public.processes 
RENAME COLUMN valor TO valor_inicial_padrao;

ALTER TABLE public.processes 
RENAME COLUMN data_criacao TO data_encaminhamento_aprovacao;

-- 2. Verificar se as colunas foram renomeadas corretamente
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'processes' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Atualizar comentários das colunas
COMMENT ON COLUMN public.processes.tipo_natureza_despesa IS 'Tipo de natureza da despesa (Custeio, Investimento)';
COMMENT ON COLUMN public.processes.valor_inicial_padrao IS 'Valor inicial padrão do processo';
COMMENT ON COLUMN public.processes.data_encaminhamento_aprovacao IS 'Data de encaminhamento para aprovação do MJSP';

-- 4. Verificar se tudo está correto
SELECT 'Estrutura atualizada com sucesso!' as status; 