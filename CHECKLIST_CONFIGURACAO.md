# ✅ CHECKLIST DE CONFIGURAÇÃO - PROJETO PROCESSOS

## 🚀 CONFIGURAÇÃO RÁPIDA

### **PASSO 1: SUPABASE**

1. [ ] Acessar o painel do Supabase
2. [ ] Ir para **SQL Editor**
3. [ ] Copiar e colar o conteúdo do arquivo `configuracao_completa_supabase.sql`
4. [ ] Executar o script
5. [ ] Verificar se todas as mensagens de sucesso apareceram

### **PASSO 2: VARIÁVEIS DE AMBIENTE**

1. [ ] Criar arquivo `.env` na raiz do projeto
2. [ ] Adicionar as seguintes variáveis:

```env
VITE_SUPABASE_URL=sua_url_do_supabase
VITE_SUPABASE_ANON_KEY=sua_chave_anonima_do_supabase
```

### **PASSO 3: INSTALAÇÃO E EXECUÇÃO**

1. [ ] Executar `npm install`
2. [ ] Executar `npm run dev`
3. [ ] Acessar `http://localhost:5173`

---

## 🔍 VERIFICAÇÕES PÓS-CONFIGURAÇÃO

### **BANCO DE DADOS**

- [ ] Tabela `processes` criada
- [ ] Tabela `process_steps` criada
- [ ] Tabela `documents` criada
- [ ] Tabela `step_templates` criada
- [ ] Função RPC `avancar_etapa` criada
- [ ] Trigger `create_process_steps` configurado

### **STORAGE**

- [ ] Bucket `documents` criado
- [ ] Políticas de segurança aplicadas
- [ ] Upload de arquivos funcionando

### **AUTENTICAÇÃO**

- [ ] Login funcionando
- [ ] Cadastro de usuários funcionando
- [ ] Logout funcionando
- [ ] Proteção de rotas ativa

---

## 🧪 TESTES FUNCIONAIS

### **TESTE 1: CADASTRO DE PROCESSO**

1. [ ] Fazer login
2. [ ] Clicar em "+Novo Processo"
3. [ ] Preencher formulário
4. [ ] Anexar arquivo
5. [ ] Clicar em "Registrar Ação"
6. [ ] Verificar se processo foi criado
7. [ ] Verificar se etapas foram criadas automaticamente

### **TESTE 2: GERENCIAMENTO DE ETAPAS**

1. [ ] Ir para página de processos
2. [ ] Clicar em "Passar Etapa"
3. [ ] Verificar se etapa avançou
4. [ ] Verificar se timer está funcionando
5. [ ] Clicar em "Ver Etapas"
6. [ ] Verificar se modal abre com informações corretas

### **TESTE 3: FILTROS E BUSCA**

1. [ ] Testar filtro por nome
2. [ ] Testar filtro por ano
3. [ ] Testar filtro por força
4. [ ] Testar mostrar/ocultar concluídos
5. [ ] Verificar se gráficos atualizam

### **TESTE 4: DOCUMENTOS**

1. [ ] Fazer upload de PDF
2. [ ] Fazer upload de imagem
3. [ ] Verificar se arquivos aparecem
4. [ ] Testar acesso às URLs públicas

---

## ⚠️ PROBLEMAS COMUNS E SOLUÇÕES

### **ERRO: "Supabase URL or anon key is not set"**

**Solução**: Verificar se o arquivo `.env` existe e tem as variáveis corretas

### **ERRO: "Bucket 'documents' not found"**

**Solução**: Executar novamente o script SQL para criar o bucket

### **ERRO: "Function 'avancar_etapa' does not exist"**

**Solução**: Verificar se a função RPC foi criada no Supabase

### **ERRO: "Policy violation"**

**Solução**: Verificar se as políticas RLS foram aplicadas corretamente

### **ERRO: "Table 'processes' does not exist"**

**Solução**: Executar novamente o script SQL para criar as tabelas

---

## 📞 SUPORTE

Se encontrar problemas:

1. **Verificar logs do console** do navegador
2. **Verificar logs do Supabase** no painel
3. **Executar novamente o script SQL** se necessário
4. **Verificar variáveis de ambiente** no arquivo `.env`

---

## ✅ STATUS FINAL

- [ ] **Aplicação funcionando completamente**
- [ ] **Todos os testes passando**
- [ ] **Upload de arquivos funcionando**
- [ ] **Gerenciamento de etapas funcionando**
- [ ] **Filtros e busca funcionando**
- [ ] **Autenticação funcionando**

**🎉 APLICAÇÃO PRONTA PARA USO!**
