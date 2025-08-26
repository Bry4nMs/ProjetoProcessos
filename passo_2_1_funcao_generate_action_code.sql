-- =====================================================
-- PASSO 2.1: FUNÇÃO RPC PARA GERAR CÓDIGOS DE AÇÃO
-- Funcionalidade: Controle de Ações
-- Formato: AA.B.C.D.EEE
-- AA = Código da Área Temática (2 dígitos)
-- B = Natureza da Despesa (1 dígito: 1=Custeio, 2=Investimento)
-- C = Força Responsável (1 dígito)
-- D = Ano (1 dígito - último dígito do ano)
-- EEE = Sequencial (3 dígitos)
-- =====================================================

-- Função para gerar código único de ação
CREATE OR REPLACE FUNCTION public.generate_action_code(
    p_thematic_area_id INTEGER,
    p_expense_nature TEXT,
    p_responsible_force_id INTEGER,
    p_year INTEGER
)
RETURNS TEXT AS $$
DECLARE
    v_area_code TEXT;
    v_force_code TEXT;
    v_nature_digit CHAR(1);
    v_year_digit CHAR(1);
    v_sequential INTEGER;
    v_action_code TEXT;
    v_base_code TEXT;
BEGIN
    -- Buscar código da área temática (primeiros 2 caracteres)
    SELECT LPAD(SUBSTRING(code FROM 1 FOR 2), 2, '0') INTO v_area_code
    FROM public.thematic_areas 
    WHERE id = p_thematic_area_id;
    
    IF v_area_code IS NULL THEN
        RAISE EXCEPTION 'Área temática não encontrada para ID: %', p_thematic_area_id;
    END IF;
    
    -- Buscar código da força responsável (primeiro caractere)
    SELECT SUBSTRING(code FROM 1 FOR 1) INTO v_force_code
    FROM public.responsible_forces 
    WHERE id = p_responsible_force_id;
    
    IF v_force_code IS NULL THEN
        RAISE EXCEPTION 'Força responsável não encontrada para ID: %', p_responsible_force_id;
    END IF;
    
    -- Converter natureza da despesa para dígito
    CASE p_expense_nature
        WHEN 'Custeio' THEN v_nature_digit := '1';
        WHEN 'Investimento' THEN v_nature_digit := '2';
        ELSE RAISE EXCEPTION 'Natureza da despesa inválida: %. Use "Custeio" ou "Investimento"', p_expense_nature;
    END CASE;
    
    -- Extrair último dígito do ano
    v_year_digit := RIGHT(p_year::TEXT, 1);
    
    -- Montar código base (sem sequencial)
    v_base_code := v_area_code || '.' || v_nature_digit || '.' || v_force_code || '.' || v_year_digit || '.';
    
    -- Buscar próximo sequencial para este padrão
    SELECT COALESCE(MAX(
        CASE 
            WHEN action_code ~ ('^' || REPLACE(v_base_code, '.', '\.') || '[0-9]{3}$') 
            THEN CAST(RIGHT(action_code, 3) AS INTEGER)
            ELSE 0
        END
    ), 0) + 1 INTO v_sequential
    FROM public.actions
    WHERE action_code LIKE v_base_code || '%';
    
    -- Garantir que o sequencial não ultrapasse 999
    IF v_sequential > 999 THEN
        RAISE EXCEPTION 'Limite de ações atingido para este padrão: %', v_base_code;
    END IF;
    
    -- Montar código final
    v_action_code := v_base_code || LPAD(v_sequential::TEXT, 3, '0');
    
    RETURN v_action_code;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao gerar código de ação: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FUNÇÃO AUXILIAR PARA VALIDAR CÓDIGO DE AÇÃO
-- =====================================================

-- Função para validar formato do código de ação
CREATE OR REPLACE FUNCTION public.validate_action_code(p_action_code TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Verificar se o código segue o padrão AA.B.C.D.EEE
    RETURN p_action_code ~ '^[0-9A-Z]{2}\.[1-2]\.[0-9A-Z]\.[0-9]\.[0-9]{3}$';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO PARA DECODIFICAR CÓDIGO DE AÇÃO
-- =====================================================

-- Função para extrair informações de um código de ação
CREATE OR REPLACE FUNCTION public.decode_action_code(p_action_code TEXT)
RETURNS JSON AS $$
DECLARE
    v_parts TEXT[];
    v_result JSON;
BEGIN
    -- Validar formato
    IF NOT public.validate_action_code(p_action_code) THEN
        RETURN json_build_object('error', 'Código de ação inválido');
    END IF;
    
    -- Dividir o código em partes
    v_parts := string_to_array(p_action_code, '.');
    
    -- Montar resultado
    v_result := json_build_object(
        'area_code', v_parts[1],
        'expense_nature_code', v_parts[2],
        'expense_nature', CASE v_parts[2] WHEN '1' THEN 'Custeio' WHEN '2' THEN 'Investimento' END,
        'force_code', v_parts[3],
        'year_digit', v_parts[4],
        'sequential', v_parts[5],
        'full_code', p_action_code
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- EXEMPLOS DE USO E TESTES
-- =====================================================

-- Exemplo de uso da função (comentado para não executar automaticamente)
/*
-- Gerar código para:
-- Área Temática ID 1, Custeio, Força Responsável ID 1, Ano 2024
SELECT public.generate_action_code(1, 'Custeio', 1, 2024) as codigo_gerado;

-- Validar um código
SELECT public.validate_action_code('VP.1.P.4.001') as codigo_valido;

-- Decodificar um código
SELECT public.decode_action_code('VP.1.P.4.001') as codigo_decodificado;
*/

-- =====================================================
-- VERIFICAÇÃO DA CRIAÇÃO
-- =====================================================

-- Verificar se as funções foram criadas corretamente
SELECT 'Função generate_action_code criada com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'generate_action_code');

SELECT 'Função validate_action_code criada com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'validate_action_code');

SELECT 'Função decode_action_code criada com sucesso!' as status 
WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'decode_action_code');

-- =====================================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- =====================================================

COMMENT ON FUNCTION public.generate_action_code(INTEGER, TEXT, INTEGER, INTEGER) IS 'Gera código único de ação no formato AA.B.C.D.EEE';
COMMENT ON FUNCTION public.validate_action_code(TEXT) IS 'Valida se um código de ação segue o formato correto';
COMMENT ON FUNCTION public.decode_action_code(TEXT) IS 'Decodifica um código de ação retornando suas partes em JSON';

-- =====================================================
-- OBSERVAÇÕES IMPORTANTES
-- =====================================================

/*
Formato do código: AA.B.C.D.EEE

Onde:
- AA: Código da área temática (2 caracteres, ex: VP, EC, FI)
- B: Natureza da despesa (1=Custeio, 2=Investimento)
- C: Código da força responsável (1 caractere, ex: P, C, B)
- D: Último dígito do ano (ex: 4 para 2024)
- EEE: Sequencial de 3 dígitos (001, 002, 003...)

Exemplos:
- VP.1.P.4.001 = Área VP, Custeio, PMGO, 2024, primeira ação
- EC.2.C.4.015 = Área EC, Investimento, PCGO, 2024, décima quinta ação
*/