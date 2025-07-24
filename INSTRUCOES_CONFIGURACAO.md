# Instruções de Configuração do Projeto Processos

## Pré-requisitos

- Node.js (versão recomendada: 18.x ou superior)
- NPM (incluído com o Node.js)
- Conta no Supabase (https://supabase.com)

## Configuração do Ambiente

### 1. Configuração do arquivo .env

O projeto requer um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```
VITE_SUPABASE_URL=sua_url_do_supabase
VITE_SUPABASE_ANON_KEY=sua_chave_anonima_do_supabase
```

Para obter esses valores:

1. Acesse o painel do Supabase
2. Selecione seu projeto
3. Vá para Configurações > API
4. Copie a URL do projeto para `VITE_SUPABASE_URL`
5. Copie a chave anônima (anon key) para `VITE_SUPABASE_ANON_KEY`

### 2. Configuração do Banco de Dados Supabase

O projeto requer a execução de scripts SQL para configurar o banco de dados:

1. Acesse o painel do Supabase
2. Vá para o SQL Editor
3. Execute o arquivo `configuracao_completa_supabase.sql` disponível na raiz do projeto

Este script irá:
- Criar o bucket de armazenamento para documentos
- Configurar as tabelas necessárias
- Configurar as políticas de segurança
- Configurar funções RPC necessárias

## Instalação de Dependências

Para instalar todas as dependências do projeto, execute:

```bash
npm install
```

## Executando o Projeto

Para iniciar o servidor de desenvolvimento:

```bash
npm run dev
```

O projeto estará disponível em: http://localhost:5173

## Solução de Problemas

### Erro: "Supabase URL or anon key is not set"

Verifique se:
1. O arquivo `.env` existe na raiz do projeto
2. As variáveis `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` estão definidas corretamente
3. O servidor de desenvolvimento foi reiniciado após a criação/modificação do arquivo `.env`

### Erro: "Bucket not found: documents"

Verifique se:
1. O script SQL foi executado corretamente no Supabase
2. O bucket "documents" foi criado
3. As permissões do bucket estão configuradas corretamente

## Suporte

Se encontrar problemas:

1. Verifique os logs do console do navegador
2. Verifique os logs do Supabase no painel
3. Execute novamente o script SQL se necessário
4. Verifique as variáveis de ambiente no arquivo `.env`