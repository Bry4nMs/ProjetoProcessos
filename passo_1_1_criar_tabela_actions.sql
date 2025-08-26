-- =====================================================
-- PASSO 1.1: CRIAÇÃO DA TABELA ACTIONS
-- Funcionalidade: Controle de Ações
-- =====================================================

-- Criar tabela actions para armazenar as ações que agrupam processos
CREATE TABLE IF NOT EXISTS public.actions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    action_code text NOT NULL UNIQUE,
    year integer NOT NULL,
    thematic_area_id integer REFERENCES public.thematic_areas(id),
    expense_nature text CHECK (expense_nature IN ('Custeio', 'Investimento')),
    responsible_force_id integer REFERENCES public.responsible_forces(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE
);

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índice para busca por código da ação (único)
CREATE INDEX IF NOT EXISTS idx_actions_action_code ON public.actions(action_code);

-- Índice para busca por ano
CREATE INDEX IF NOT EXISTS idx_actions_year ON public.actions(year);

-- Índice para busca por área temática
CREATE INDEX IF NOT EXISTS idx_actions_thematic_area_id ON public.actions(thematic_area_id);

-- Índice para busca por força responsável
CREATE INDEX IF NOT EXISTS idx_actions_responsible_force_id ON public.actions(responsible_force_id);

-- Índice para busca por usuário criador
CREATE INDEX IF NOT EXISTS idx_actions_user_id ON public.actions(user_id);

-- Índice para busca por data de criação
CREATE INDEX IF NOT EXISTS idx_actions_created_at ON public.actions(created_at);

-- =====================================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- =====================================================

-- Habilitar RLS na tabela actions
ALTER TABLE public.actions ENABLE ROW LEVEL SECURITY;

-- Política para SELECT: todos os usuários autenticados podem ver todas as ações
CREATE POLICY "Usuários autenticados podem ver ações" ON public.actions
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Política para INSERT: usuários autenticados podem criar ações
CREATE POLICY "Usuários autenticados podem criar ações" ON public.actions
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Política para UPDATE: usuários autenticados podem atualizar ações
CREATE POLICY "Usuários autenticados podem atualizar ações" ON public.actions
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Política para DELETE: usuários autenticados podem excluir ações
CREATE POLICY "Usuários autenticados podem excluir ações" ON public.actions
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- =====================================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =====================================================

COMMENT ON TABLE public.actions IS 'Tabela de ações que agrupam um ou mais processos';
COMMENT ON COLUMN public.actions.id IS 'Identificador único da ação (UUID)';
COMMENT ON COLUMN public.actions.name IS 'Nome descritivo da ação';
COMMENT ON COLUMN public.actions.action_code IS 'Código único da ação no formato AA.B.C.D.EEE';
COMMENT ON COLUMN public.actions.year IS 'Ano da ação';
COMMENT ON COLUMN public.actions.thematic_area_id IS 'Referência para a área temática';
COMMENT ON COLUMN public.actions.expense_nature IS 'Natureza da despesa: Custeio ou Investimento';
COMMENT ON COLUMN public.actions.responsible_force_id IS 'Referência para a força responsável';
COMMENT ON COLUMN public.actions.created_at IS 'Data e hora de criação da ação';
COMMENT ON COLUMN public.actions.updated_at IS 'Data e hora da última atualização';
COMMENT ON COLUMN public.actions.user_id IS 'Usuário que criou a ação';

-- =====================================================
-- TRIGGER PARA ATUALIZAR updated_at
-- =====================================================

-- Função para atualizar o campo updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at na tabela actions
DROP TRIGGER IF EXISTS trigger_update_actions_updated_at ON public.actions;
CREATE TRIGGER trigger_update_actions_updated_at
    BEFORE UPDATE ON public.actions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VERIFICAÇÃO DA CRIAÇÃO
-- =====================================================

-- Verificar se a tabela foi criada corretamente
SELECT 'Tabela actions criada com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'actions' AND table_schema = 'public');

-- Verificar se as políticas RLS foram aplicadas
SELECT 'Políticas RLS aplicadas com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'actions');

-- Listar as colunas da tabela para verificação
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'actions' AND table_schema = 'public'
ORDER BY ordinal_position;