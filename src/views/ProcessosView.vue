<template>
  <AppLayout>
    <div class="min-h-screen flex justify-center items-stretch bg-abyss-deep px-8">
      <div class="w-full bg-white shadow-lg p-10 rounded-xl">
        <ProcessosGraficos :processos="processos" />
        <div class="w-full flex justify-center">
          <div
            class="w-full bg-white border border-abyss-primary rounded-lg shadow flex flex-wrap items-center gap-4 px-6 py-3 mb-8"
          >
            <div class="flex flex-col min-w-[180px]">
              <label class="text-abyss-dark font-semibold mb-1">Pesquisar por Nome</label>
              <input
                v-model="filtroNome"
                type="text"
                placeholder="Digite o nome da ação"
                class="px-2 py-1 rounded border border-abyss-primary bg-white text-abyss-dark placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-abyss-primary w-full"
              />
            </div>
            <div class="flex flex-col min-w-[120px]">
              <label class="text-abyss-dark font-semibold mb-1">Ano do FAF</label>
              <select
                v-model="filtroAno"
                class="px-2 py-1 rounded border border-abyss-primary bg-white text-abyss-dark focus:outline-none focus:ring-2 focus:ring-abyss-primary w-full"
              >
                <option value="">Todos</option>
                <option v-for="ano in anos" :key="ano" :value="ano">{{ ano }}</option>
              </select>
            </div>
            <div class="flex flex-col min-w-[140px]">
              <label class="text-abyss-dark font-semibold mb-1">Força</label>
              <select
                v-model="filtroForca"
                class="px-2 py-1 rounded border border-abyss-primary bg-white text-abyss-dark focus:outline-none focus:ring-2 focus:ring-abyss-primary w-full"
              >
                <option value="">Todas</option>
                <option v-for="forca in forcas" :key="forca" :value="forca">{{ forca }}</option>
              </select>
            </div>
            <div class="flex flex-col min-w-[160px]">
              <label class="text-abyss-dark font-semibold mb-1">Data de Criação</label>
              <input
                v-model="filtroData"
                type="date"
                class="px-2 py-1 rounded border border-abyss-primary bg-white text-abyss-dark focus:outline-none focus:ring-2 focus:ring-abyss-primary w-full"
              />
            </div>
            <div class="flex items-center gap-2 min-w-[170px] mt-5 md:mt-0">
              <input
                id="chkConcluidos"
                v-model="mostrarConcluidos"
                type="checkbox"
                class="accent-abyss-primary w-5 h-5"
              />
              <label for="chkConcluidos" class="text-abyss-dark font-semibold select-none"
                >Mostrar Concluídos</label
              >
            </div>
          </div>
        </div>
        <div class="w-full flex justify-end mt-0 mb-2">
          <router-link
            to="/processos/novo"
            class="px-4 py-2 bg-abyss-primary text-abyss-black rounded font-bold shadow hover:bg-abyss-secondary transition"
          >
            +Novo Processo
          </router-link>
        </div>
        <h1 class="text-3xl font-bold text-abyss-primary mb-4">Página de Processos</h1>
        <p class="text-abyss-secondary mb-6">Aqui você pode gerenciar seus processos.</p>
        <div class="flex justify-center w-full">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            <ProcessoCard
              v-for="(processo, idx) in processosFiltrados"
              :key="idx"
              :processo="processo"
              :total-etapas="processo.totalEtapas"
              @atualizar-processo="carregarProcessos()"
            />
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import AppLayout from '../components/Layout.vue'
import ProcessoCard from '../components/ProcessoCard.vue'
import ProcessosGraficos from '../components/ProcessosGraficos.vue'
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'
import { buscarEtapasDoProcesso } from '../services/auth'

// Opções de Ano do FAF (igual CadastroProcessoView.vue)
const anoAtual = new Date().getFullYear()
const anos = Array.from({ length: anoAtual - 2019 + 1 }, (_, i) => 2019 + i)

// Opções de Força (igual CadastroProcessoView.vue)
const forcas = ['PMGO', 'PCGO', 'CBMGO', 'DGPP', 'SPTC', 'SSP']

const filtroNome = ref('')
const filtroAno = ref('')
const filtroForca = ref('')
const filtroData = ref('')
const mostrarConcluidos = ref(true)

interface Processo {
  id: string
  user_id: string
  area_tematica?: string
  ano_faf?: number
  tipo_natureza_despesa?: string
  forca_responsavel?: string
  valor_inicial_padrao?: number
  data_encaminhamento_aprovacao?: string
  codigo_transferegov?: string
  qtd_itens?: number
  descricao_itens?: string
  destinacao_itens?: string
  valor_rendimentos?: number
  valor_economicidade?: number
  valor_total_destinado?: number
  descricao_geral?: string
  nome_acao?: string
  status: string
  etapaAtual: number
  totalEtapas: number
}
const { user, fetchUser } = useAuth()
const processos = ref<Processo[]>([])
const loadingProcessos = ref(false)

async function carregarProcessos() {
  loadingProcessos.value = true
  let usuario = user.value
  if (!usuario) {
    usuario = await fetchUser()
  }
  if (!usuario) {
    processos.value = []
    loadingProcessos.value = false
    return
  }
  const { data } = await supabase
    .from('processes')
    .select('*')
    .order('created_at', { ascending: false })
  // Para cada processo, buscar o status e etapa atual reais
  if (data) {
    processos.value = await Promise.all(
      data.map(async (proc) => {
        const { data: etapas } = await buscarEtapasDoProcesso(proc.id)
        let etapaAtual = 0
        let totalEtapas = 0
        if (etapas && etapas.length > 0) {
          etapaAtual = etapas.findIndex((e: { is_current: boolean }) => e.is_current)
          if (etapaAtual === -1) etapaAtual = 0
          totalEtapas = etapas.length
        }
        return {
          ...proc,
          etapaAtual,
          totalEtapas,
          status: proc.status || 'Em Andamento',
        }
      }),
    )
  } else {
    processos.value = []
  }
  loadingProcessos.value = false
}

onMounted(() => {
  carregarProcessos()
})

const processosFiltrados = computed(() => {
  return processos.value.filter((proc) => {
    const nomeMatch = (proc.nome_acao || proc.area_tematica || '')
      .toLowerCase()
      .includes(filtroNome.value.toLowerCase())
    const anoMatch = !filtroAno.value || proc.ano_faf === Number(filtroAno.value)
    const forcaMatch = !filtroForca.value || proc.forca_responsavel === filtroForca.value
    const dataMatch =
      !filtroData.value ||
      (proc.data_encaminhamento_aprovacao &&
        proc.data_encaminhamento_aprovacao === filtroData.value)
    // Adapte status conforme sua tabela
    const statusMatch = mostrarConcluidos.value ? true : proc.status !== 'Concluído'
    return nomeMatch && anoMatch && forcaMatch && dataMatch && statusMatch
  })
})
</script>
