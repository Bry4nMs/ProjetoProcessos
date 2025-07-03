<script setup lang="ts">
import AppLayout from '../components/Layout.vue'
import { ref } from 'vue'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'

const anoAtual = new Date().getFullYear()
const anos = Array.from({ length: anoAtual - 2019 + 1 }, (_, i) => 2019 + i)

// Campos do formulário
const nomeAcao = ref('')
const areaTematica = ref('')
const codigoTransferegov = ref('')
const anoFaf = ref('')
const tipoNatureza = ref('')
const forcaResponsavel = ref('')
const dataCriacao = ref('')
const quantidadeItens = ref('')
const descricaoItens = ref('')
const destinacaoItens = ref('')
const valor = ref('')
const valorRendimentos = ref('')
const valorEconomicidade = ref('')
const valorTotal = ref('')
const descricaoGeral = ref('')
const feedback = ref('')
const loading = ref(false)
const arquivos = ref<File[]>([])

const { user, fetchUser } = useAuth()

async function registrarProcesso() {
  feedback.value = ''
  loading.value = true
  let usuario = user.value
  if (!usuario) {
    usuario = await fetchUser()
  }
  if (!usuario) {
    feedback.value = 'Usuário não autenticado.'
    loading.value = false
    return
  }
  // 1. Cadastrar processo
  const { data, error } = await supabase
    .from('processes')
    .insert([
      {
        user_id: usuario.id,
        area_tematica: areaTematica.value,
        ano_faf: anoFaf.value ? Number(anoFaf.value) : null,
        tipo_natureza: tipoNatureza.value,
        forca_responsavel: forcaResponsavel.value,
        valor: valor.value ? Number(valor.value) : null,
        data_criacao: dataCriacao.value || null,
        codigo_transferegov: codigoTransferegov.value,
        qtd_itens: quantidadeItens.value ? Number(quantidadeItens.value) : null,
        descricao_itens: descricaoItens.value,
        destinacao_itens: destinacaoItens.value,
        valor_rendimentos: valorRendimentos.value ? Number(valorRendimentos.value) : null,
        valor_economicidade: valorEconomicidade.value ? Number(valorEconomicidade.value) : null,
        valor_total_destinado: valorTotal.value ? Number(valorTotal.value) : null,
        descricao_geral: descricaoGeral.value,
        nome_acao: nomeAcao.value,
      },
    ])
    .select('id')
  if (error || !data || !data[0]?.id) {
    feedback.value = 'Erro ao registrar processo: ' + (error?.message || 'ID não retornado')
    loading.value = false
    return
  }
  const processoId = data[0].id
  // 2. Upload dos arquivos e vinculação na tabela documents
  for (const file of arquivos.value) {
    const filePath = `${processoId}/${Date.now()}_${file.name}`
    const { error: uploadError } = await supabase.storage.from('documents').upload(filePath, file)
    if (!uploadError) {
      const fileUrl = supabase.storage.from('documents').getPublicUrl(filePath).data.publicUrl
      await supabase.from('documents').insert([
        {
          process_id: processoId,
          filename: file.name,
          file_url: fileUrl,
        },
      ])
    } else {
      feedback.value += `\nFalha ao enviar ${file.name}: ${uploadError.message}`
    }
  }
  feedback.value = 'Processo cadastrado com sucesso!'
  limparFormulario()
  arquivos.value = []
  loading.value = false
}

function limparFormulario() {
  nomeAcao.value = ''
  areaTematica.value = ''
  codigoTransferegov.value = ''
  anoFaf.value = ''
  tipoNatureza.value = ''
  forcaResponsavel.value = ''
  dataCriacao.value = ''
  quantidadeItens.value = ''
  descricaoItens.value = ''
  destinacaoItens.value = ''
  valor.value = ''
  valorRendimentos.value = ''
  valorEconomicidade.value = ''
  valorTotal.value = ''
  descricaoGeral.value = ''
}
</script>

<template>
  <AppLayout>
    <div class="max-w-3xl mx-auto bg-white rounded-lg shadow-lg p-8 mt-8">
      <h1 class="text-2xl font-bold text-abyss-primary mb-6">Cadastro de Novo Processo</h1>
      <form class="flex flex-col gap-6" @submit.prevent="registrarProcesso">
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold">Nome da Ação</label>
          <input
            v-model="nomeAcao"
            type="text"
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            placeholder="Digite o nome da ação"
          />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Área Temática</label>
            <select
              v-model="areaTematica"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option>VPSP</option>
              <option>ECV</option>
              <option>FISP</option>
              <option>EVM</option>
              <option>MQV</option>
              <option>RMVI</option>
            </select>
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Código Transferegov</label>
            <input
              v-model="codigoTransferegov"
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="Digite o código"
            />
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Ano do FAF</label>
            <select
              v-model="anoFaf"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option v-for="ano in anos" :key="ano">{{ ano }}</option>
            </select>
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold"
              >Tipo de Natureza de Despesa</label
            >
            <select
              v-model="tipoNatureza"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option>Custeio</option>
              <option>Investimento</option>
            </select>
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Força Responsável</label>
            <select
              v-model="forcaResponsavel"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            >
              <option value="">Selecione</option>
              <option>PMGO</option>
              <option>PCGO</option>
              <option>CBMGO</option>
              <option>DGPP</option>
              <option>SPTC</option>
              <option>SSP</option>
            </select>
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold"
              >Data de Encaminhamento para Aprovação do MJSP</label
            >
            <input
              v-model="dataCriacao"
              type="date"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            />
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Quantidade de Itens</label>
            <input
              v-model="quantidadeItens"
              type="number"
              min="0"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Descrição dos Itens</label>
            <textarea
              v-model="descricaoItens"
              rows="2"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
            ></textarea>
          </div>
        </div>
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold">Destinação dos Itens</label>
          <textarea
            v-model="destinacaoItens"
            rows="2"
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          ></textarea>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Valor Inicial Padrão</label>
            <input
              v-model="valor"
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Valor de Rendimentos</label>
            <input
              v-model="valorRendimentos"
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold">Valor de Economicidade</label>
            <input
              v-model="valorEconomicidade"
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
          <div>
            <label class="block text-abyss-dark mb-1 font-semibold"
              >Valor Total Destinado à Ação</label
            >
            <input
              v-model="valorTotal"
              type="text"
              class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary"
              placeholder="R$ 0,00"
            />
          </div>
        </div>
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold">Descrição Geral da Ação</label>
          <textarea
            v-model="descricaoGeral"
            rows="4"
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          ></textarea>
        </div>
        <div>
          <label class="block text-abyss-dark mb-1 font-semibold"
            >Anexar Nota Técnica ou Documento de Aprovação</label
          >
          <input
            type="file"
            multiple
            class="w-full px-4 py-2 rounded bg-white text-abyss-dark border border-abyss-deep file:bg-abyss-primary file:text-abyss-black file:rounded file:px-4 file:py-2 file:mr-4"
            @change="
              (e) => {
                const files = (e.target as HTMLInputElement).files
                arquivos.value = files ? Array.from(files) : []
              }
            "
          />
        </div>
        <div class="flex justify-end">
          <button
            type="submit"
            class="px-6 py-3 bg-abyss-primary text-abyss-black rounded-lg shadow hover:bg-abyss-secondary transition font-bold"
            :disabled="loading"
          >
            Registrar Ação
          </button>
        </div>
        <div
          v-if="feedback"
          class="mt-4 text-center font-semibold"
          :class="feedback.includes('sucesso') ? 'text-green-600' : 'text-red-600'"
        >
          {{ feedback }}
        </div>
      </form>
    </div>
  </AppLayout>
</template>
