# Instruções para Correção das Funções RPC

Este documento contém instruções para corrigir o erro "column p.forca_responsavel does not exist" que está impedindo a exibição dos processos na aplicação.

## Problema Identificado

O erro ocorre porque as funções RPC estão tentando acessar colunas com nomes incorretos:

- Usando `forca_responsavel` em vez de `responsible_force_id`
- Usando `area_tematica` em vez de `thematic_area_id`

## Solução

Foram criados dois arquivos SQL com as correções necessárias:

### 1. `adicionar_funcoes_rpc.sql`

Este arquivo contém a versão corrigida das funções RPC usando o método de loop em PL/pgSQL. As correções incluem:

- Alteração dos JOINs para usar os nomes corretos das colunas
- Atualização dos campos no objeto JSON retornado para incluir tanto os nomes antigos quanto os novos

### 2. `adicionar_funcoes_rpc_alternativa.sql`

Este arquivo contém uma implementação alternativa usando Common Table Expressions (CTE), que pode ser mais eficiente. Esta versão:

- Calcula o progresso e as etapas em uma única consulta
- Usa os nomes corretos das colunas
- Inclui informações adicionais como `is_favorited`

## Como Aplicar a Correção

1. Acesse o painel de administração do Supabase
2. Vá para a seção "SQL Editor"
3. Copie e cole o conteúdo de um dos arquivos SQL (recomendamos o `adicionar_funcoes_rpc_alternativa.sql`)
4. Execute o script
5. Verifique se as funções foram criadas corretamente

## Verificação

Após aplicar as correções, você deve ver a mensagem:

```
Função get_processes_with_progress criada
Função get_favorited_processes_with_progress criada
```

Em seguida, reinicie o servidor de desenvolvimento e verifique se os processos estão sendo exibidos corretamente na aplicação.

## Observações Importantes

1. As funções mantêm compatibilidade com o código existente, fornecendo tanto os nomes antigos (`forca_responsavel`, `area_tematica`) quanto os novos (`responsible_force_id`, `thematic_area_id`).

2. A versão alternativa (CTE) é mais eficiente e recomendada para uso em produção.

3. Se você precisar fazer alterações adicionais no esquema do banco de dados, certifique-se de atualizar também as funções RPC correspondentes.