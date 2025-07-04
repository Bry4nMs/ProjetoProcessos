# 🔧 SOLUÇÃO: BUCKET EXISTE MAS AINDA HÁ ERROS

## 🚨 Problema Identificado

O bucket `documents` existe no Supabase Storage, mas ainda está ocorrendo o erro `{"statusCode":"404","error":"Bucket not found","message":"Bucket not found"}`.

## 🔍 Diagnóstico

### **PASSO 1: Executar Diagnóstico**

Execute o arquivo `diagnostico_bucket.sql` no SQL Editor do Supabase para identificar o problema específico:

1. Acesse o **painel do Supabase**
2. Vá para **SQL Editor**
3. Execute o arquivo `diagnostico_bucket.sql`
4. Analise os resultados

### **PASSO 2: Verificar Configuração**

O problema pode estar em uma destas áreas:

1. **Bucket não está público**
2. **Políticas de segurança (RLS) incorretas**
3. **RLS desabilitado**
4. **Políticas conflitantes**
5. **Problemas de permissão**

## ✅ Soluções por Tipo de Problema

### **PROBLEMA 1: Bucket não está público**

**Sintoma**: Bucket existe mas `public = false`

**Solução**: Execute no SQL Editor:

```sql
UPDATE storage.buckets
SET public = true
WHERE id = 'documents';
```

### **PROBLEMA 2: Políticas de segurança incorretas**

**Sintoma**: RLS habilitado mas sem políticas específicas para `documents`

**Solução**: Execute o arquivo `verificar_corrigir_bucket.sql`

### **PROBLEMA 3: RLS desabilitado**

**Sintoma**: `rowsecurity = false` na tabela `storage.objects`

**Solução**: Execute no SQL Editor:

```sql
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

### **PROBLEMA 4: Políticas conflitantes**

**Sintoma**: Múltiplas políticas que se contradizem

**Solução**: Execute o arquivo `verificar_corrigir_bucket.sql` que remove políticas antigas

## 🚀 Solução Rápida (Recomendada)

Execute o arquivo `verificar_corrigir_bucket.sql` que:

1. ✅ Verifica a configuração atual
2. ✅ Corrige configurações do bucket
3. ✅ Remove políticas problemáticas
4. ✅ Cria novas políticas corretas
5. ✅ Habilita RLS se necessário
6. ✅ Verifica se tudo está funcionando

## 🔧 Solução Manual

Se preferir fazer manualmente:

### **1. Verificar configuração do bucket**

```sql
SELECT id, name, public, file_size_limit
FROM storage.buckets
WHERE id = 'documents';
```

### **2. Tornar bucket público**

```sql
UPDATE storage.buckets
SET public = true
WHERE id = 'documents';
```

### **3. Habilitar RLS**

```sql
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

### **4. Criar políticas básicas**

```sql
-- Política para visualização
CREATE POLICY "documents_select" ON storage.objects
FOR SELECT USING (bucket_id = 'documents');

-- Política para upload
CREATE POLICY "documents_insert" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'documents'
  AND auth.uid() IS NOT NULL
);
```

## 🧪 Teste da Solução

Após aplicar as correções:

### **1. Teste no Supabase**

1. Vá para **Storage** no painel
2. Clique no bucket `documents`
3. Tente fazer upload de um arquivo pequeno
4. Se funcionar, o bucket está correto

### **2. Teste na aplicação**

1. **Reinicie a aplicação** (`npm run dev`)
2. **Faça login**
3. **Crie um novo processo** com anexo
4. **Verifique se o upload funciona**

## ⚠️ Problemas Comuns

### **Erro: "Policy violation"**

**Causa**: Políticas muito restritivas

**Solução**: Execute `verificar_corrigir_bucket.sql`

### **Erro: "Permission denied"**

**Causa**: Usuário não autenticado ou sem permissões

**Solução**: Verificar se está logado na aplicação

### **Erro: "File too large"**

**Causa**: Arquivo maior que o limite do bucket

**Solução**: Aumentar `file_size_limit` no bucket

## 📋 Checklist de Verificação

- [ ] Bucket `documents` existe
- [ ] Bucket está configurado como público (`public = true`)
- [ ] RLS está habilitado na tabela `storage.objects`
- [ ] Políticas específicas para `documents` existem
- [ ] Upload manual no Supabase funciona
- [ ] Upload via aplicação funciona
- [ ] Visualização de documentos funciona

## 🎯 Próximos Passos

1. **Execute `diagnostico_bucket.sql`** para identificar o problema
2. **Execute `verificar_corrigir_bucket.sql`** para corrigir
3. **Teste o upload** manual no Supabase
4. **Teste o upload** na aplicação
5. **Confirme que tudo está funcionando**

## 📞 Suporte Adicional

Se ainda tiver problemas após executar os scripts:

1. **Compartilhe os resultados** do `diagnostico_bucket.sql`
2. **Verifique os logs** do console do navegador
3. **Teste com arquivos pequenos** primeiro
4. **Verifique se as variáveis de ambiente** estão corretas

---

**🎉 Após seguir estes passos, o problema deve ser resolvido mesmo com o bucket existindo!**
