<script setup lang="ts">
import { ref, defineProps, computed, toRef } from 'vue'
import { useEtapaTimer } from '../composables/useEtapaTimer'
import { buscarEtapasDoProcesso, avancarEtapa } from '../services/auth'

const showModal = ref(false)
const showEtapas = ref(false)
interface Etapa {
  nome: string
  descricao: string
  cor: string
  started_at?: string
  ended_at?: string
  is_current?: boolean
  step_order?: number
}
const etapas = ref<Etapa[]>([])
const etapaAtual = ref(0)
const carregandoEtapas = ref(false)
const erroEtapas = ref('')

const props = defineProps({
  processo: {
    type: Object,
    required: true,
  },
})

const emit = defineEmits(['atualizar-processo'])

async function carregarEtapas() {
  carregandoEtapas.value = true
  erroEtapas.value = ''
  etapas.value = []
  etapaAtual.value = 0
  const { data, error } = await buscarEtapasDoProcesso(props.processo.id)
  if (error) {
    erroEtapas.value = 'Erro ao buscar etapas: ' + error.message
  } else if (data && data.length > 0) {
    etapas.value = data.map(
      (e: {
        step_templates?: { name?: string }
        started_at?: string
        ended_at?: string
        is_current?: boolean
        step_order?: number
      }) => ({
        nome: e.step_templates?.name || '',
        descricao: '', // Adapte se quiser descrição
        cor: '#2196f3', // Adapte se quiser cor
        started_at: e.started_at,
        ended_at: e.ended_at,
        is_current: e.is_current,
        step_order: e.step_order,
      }),
    )
    etapaAtual.value = data.findIndex((e: { is_current: boolean }) => e.is_current)
    if (etapaAtual.value === -1) etapaAtual.value = 0
  }
  carregandoEtapas.value = false
}

function formatarValor(valor: number) {
  return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}
function formatarData(data: string) {
  return new Date(data).toLocaleDateString('pt-BR')
}

function abrirEtapas(e) {
  e.stopPropagation()
  showEtapas.value = true
  carregarEtapas()
}
function fecharEtapas() {
  showEtapas.value = false
}

async function passarEtapa(e) {
  e.stopPropagation()
  if (etapas.value.length === 0) return
  const totalEtapas = etapas.value.length
  const idxAtual = etapaAtual.value
  const { error } = await avancarEtapa(props.processo.id, idxAtual, totalEtapas)
  if (!error) {
    await carregarEtapas()
    emit('atualizar-processo')
  }
}

const progresso = computed(() => {
  if (etapas.value.length === 0) return 0
  return (etapaAtual.value / (etapas.value.length - 1)) * 100
})

const etapaAtualRef = toRef(etapaAtual, 'value')
const etapasRef = toRef(etapas, 'value')
const { tempoEtapaAtual, tempoTotal, formatarSegundos } = useEtapaTimer(etapasRef, etapaAtualRef)
</script>

<template>
  <div>
    <!-- Card -->
    <div
      class="bg-white rounded-xl shadow-lg p-6 mb-6 hover:shadow-2xl transition relative border border-abyss-deep w-full h-full min-h-[320px]"
    >
      <!-- Barra de Progresso -->
      <div class="w-full h-2 bg-gray-200 rounded mb-3 overflow-hidden">
        <div
          class="h-2 rounded bg-abyss-primary transition-all"
          :style="{ width: progresso + '%' }"
        ></div>
      </div>
      <div class="flex items-center justify-between mb-2">
        <span class="bg-green-100 text-green-700 text-xs font-bold px-3 py-1 rounded-full">{{
          processo.status
        }}</span>
        <span class="text-gray-400 text-xl">&#9825;</span>
      </div>
      <h2 class="text-xl font-bold text-abyss-dark mb-1">{{ processo.nomeAcao }}</h2>
      <p class="text-gray-600 mb-2">{{ processo.descricao }}</p>
      <div class="flex items-center gap-2 text-sm text-gray-500 mb-2">
        <span class="inline-flex items-center gap-1">
          <svg
            class="w-4 h-4 text-abyss-primary"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M17.657 16.657L13.414 20.9a2 2 0 01-2.828 0l-4.243-4.243a8 8 0 1111.314 0z"
            />
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
            />
          </svg>
          {{ processo.forcaResponsavel }}
        </span>
      </div>
      <div class="flex items-center gap-2 mb-2">
        <span class="text-green-700 font-bold text-lg">{{ formatarValor(processo.valor) }}</span>
      </div>
      <div class="flex flex-wrap gap-2 mb-2">
        <span class="bg-abyss-primary/10 text-abyss-primary text-xs px-2 py-1 rounded">{{
          processo.tipoNatureza
        }}</span>
        <span class="bg-abyss-primary/10 text-abyss-primary text-xs px-2 py-1 rounded">{{
          processo.areaTematica
        }}</span>
      </div>
      <div class="flex items-center justify-between text-xs text-gray-500 mt-4">
        <span>Criado em {{ formatarData(processo.dataCriacao) }}</span>
        <span>Ano FAF: {{ processo.anoFaf }}</span>
      </div>
      <!-- Botões de Etapas -->
      <div class="flex gap-2 mt-4">
        <button
          v-if="processo.status !== 'Concluído'"
          class="px-3 py-1 bg-abyss-primary text-white rounded font-semibold shadow hover:bg-abyss-secondary transition"
          @click.stop="passarEtapa"
          :disabled="processo.etapaAtual >= processo.etapas.length - 1"
        >
          Passar Etapa
        </button>
        <button
          class="px-3 py-1 bg-gray-200 text-abyss-dark rounded font-semibold shadow hover:bg-gray-300 transition"
          @click.stop="abrirEtapas"
        >
          Ver Etapas
        </button>
        <button
          class="px-3 py-1 bg-gray-100 text-abyss-dark rounded font-semibold shadow hover:bg-gray-200 transition"
          @click.stop="
            () => {
              showModal = true
            }
          "
        >
          Ver Detalhes
        </button>
      </div>
    </div>

    <!-- Modal de Etapas -->
    <div
      v-if="showEtapas"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40"
      @click.self="fecharEtapas"
    >
      <div
        class="bg-white rounded-xl shadow-xl p-8 max-w-2xl w-full relative max-h-[80vh] overflow-y-auto"
      >
        <button
          class="absolute top-2 right-2 text-gray-400 hover:text-abyss-primary text-2xl"
          @click="fecharEtapas"
        >
          &times;
        </button>
        <h2 class="text-2xl font-bold text-abyss-primary mb-2">{{ processo.nomeAcao }}</h2>
        <div class="mb-4 text-gray-600">
          Tempo total decorrido:
          <span class="font-semibold">{{ formatarSegundos(tempoTotal) }}</span>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="(etapa, idx) in etapas"
            :key="idx"
            class="flex items-start gap-3 p-3 rounded-lg border border-gray-200 relative"
            :class="{ 'border-abyss-primary bg-abyss-primary/10': idx === etapaAtual }"
          >
            <!-- Círculo colorido -->
            <div
              class="w-8 h-8 rounded-full flex items-center justify-center border-2"
              :style="{
                borderColor: idx <= etapaAtual ? etapa.cor : '#e5e7eb',
                background: idx < etapaAtual ? etapa.cor : '#fff',
                color: idx < etapaAtual ? '#fff' : etapa.cor,
              }"
            >
              <span class="font-bold">{{ idx + 1 }}</span>
            </div>
            <div class="flex-1">
              <div class="font-semibold text-abyss-dark">{{ etapa.nome }}</div>
              <div class="text-xs text-gray-500 mb-1">{{ etapa.descricao }}</div>
              <div v-if="idx === etapaAtual" class="text-xs text-abyss-primary font-bold">
                Tempo nesta etapa: <span>{{ formatarSegundos(tempoEtapaAtual) }}</span>
              </div>
            </div>
            <div
              v-if="idx === etapaAtual"
              class="absolute top-2 right-2 text-xs font-bold text-abyss-primary"
            >
              ATUAL
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Detalhes (antigo) -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40"
    >
      <div class="bg-white rounded-xl shadow-xl p-8 max-w-lg w-full relative">
        <button
          class="absolute top-2 right-2 text-gray-400 hover:text-abyss-primary text-2xl"
          @click="
            () => {
              showModal = false
            }
          "
        >
          &times;
        </button>
        <h2 class="text-xl font-bold text-abyss-dark mb-2">{{ processo.nomeAcao }}</h2>
        <p class="mb-2 text-gray-600">{{ processo.descricao }}</p>
        <div class="mb-2"><b>Área Temática:</b> {{ processo.areaTematica }}</div>
        <div class="mb-2"><b>Ano do FAF:</b> {{ processo.anoFaf }}</div>
        <div class="mb-2"><b>Tipo de Natureza:</b> {{ processo.tipoNatureza }}</div>
        <div class="mb-2"><b>Força Responsável:</b> {{ processo.forcaResponsavel }}</div>
        <div class="mb-2"><b>Valor:</b> {{ formatarValor(processo.valor) }}</div>
        <div class="mb-2"><b>Data de Criação:</b> {{ formatarData(processo.dataCriacao) }}</div>
        <div class="mb-2"><b>Código Transferegov:</b> {{ processo.codigoTransferegov }}</div>
        <div class="mb-2"><b>Quantidade de Itens:</b> {{ processo.quantidadeItens }}</div>
        <div class="mb-2"><b>Descrição dos Itens:</b> {{ processo.descricaoItens }}</div>
        <div class="mb-2"><b>Destinação dos Itens:</b> {{ processo.destinacaoItens }}</div>
        <div class="mb-2">
          <b>Valor de Rendimentos:</b> {{ formatarValor(processo.valorRendimentos) }}
        </div>
        <div class="mb-2">
          <b>Valor de Economicidade:</b> {{ formatarValor(processo.valorEconomicidade) }}
        </div>
        <div class="mb-2">
          <b>Valor Total Destinado à Ação:</b> {{ formatarValor(processo.valorTotal) }}
        </div>
        <div class="mb-2"><b>Descrição Geral:</b> {{ processo.descricaoGeral }}</div>
        <div class="flex justify-end mt-4">
          <button
            class="px-4 py-2 bg-abyss-primary text-abyss-black rounded font-bold shadow hover:bg-abyss-secondary transition"
            @click="
              () => {
                showModal = false
              }
            "
          >
            Fechar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
