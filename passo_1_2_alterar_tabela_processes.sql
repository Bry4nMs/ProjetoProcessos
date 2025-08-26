-- =====================================================
-- PASSO 1.2: ALTERAÇÃO DA TABELA PROCESSES
-- Funcionalidade: Controle de Ações
-- Adicionar coluna action_id para vincular processos às ações
-- =====================================================

-- Adicionar coluna action_id à tabela processes
ALTER TABLE public.processes 
ADD COLUMN IF NOT EXISTS action_id uuid;

-- Criar foreign key constraint para referenciar a tabela actions
ALTER TABLE public.processes 
ADD CONSTRAINT fk_processes_action_id 
FOREIGN KEY (action_id) REFERENCES public.actions(id) 
ON DELETE SET NULL;

-- =====================================================
-- ÍNDICE PARA PERFORMANCE
-- =====================================================

-- Criar índice para melhorar performance nas consultas por action_id
CREATE INDEX IF NOT EXISTS idx_processes_action_id ON public.processes(action_id);

-- =====================================================
-- COMENTÁRIO PARA DOCUMENTAÇÃO
-- =====================================================

COMMENT ON COLUMN public.processes.action_id IS 'Referência para a ação que agrupa este processo (opcional)';

-- =====================================================
-- VERIFICAÇÃO DA ALTERAÇÃO
-- =====================================================

-- Verificar se a coluna foi adicionada corretamente
SELECT 'Coluna action_id adicionada com sucesso!' as status 
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'processes' 
    AND table_schema = 'public' 
    AND column_name = 'action_id'
);

-- Verificar se a foreign key constraint foi criada
SELECT 'Foreign key constraint criada com sucesso!' as status 
WHERE EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_processes_action_id' 
    AND table_name = 'processes' 
    AND table_schema = 'public'
);

-- Listar as colunas da tabela processes para verificação
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'processes' AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- OBSERVAÇÕES IMPORTANTES
-- =====================================================

/*
Esta alteração permite que:
1. Um processo possa ser vinculado a uma ação (opcional)
2. Uma ação possa ter múltiplos processos vinculados
3. Se uma ação for excluída, os processos vinculados terão action_id = NULL
4. A relação é opcional, mantendo compatibilidade com processos existentes
*/