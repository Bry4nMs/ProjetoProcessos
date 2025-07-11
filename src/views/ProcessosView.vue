<template>
  <AppLayout>
    <div class="min-h-screen flex justify-center items-stretch px-8">
      <div class="w-full max-w-7xl mx-auto space-y-8">
        <!-- Gráficos de Sumário -->
        <div class="flex justify-center flex-wrap gap-8">
          <ProcessosGraficos :processos="processos" />
        </div>
        <!-- Filtros -->
        <div class="w-full flex justify-center">
          <div class="w-full bg-white/10 backdrop-blur-md border border-white/20 shadow-xl rounded-lg flex flex-wrap items-center gap-4 px-6 py-3 mb-8">
            <div class="flex flex-col min-w-[180px]">
              <label class="text-slate-200 font-semibold mb-1">Pesquisar por Nome</label>
              <input
                v-model="filtroNome"
                type="text"
                placeholder="Digite o nome da ação"
                class="px-2 py-1 rounded border border-white/20 bg-slate-900 text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-400 w-full"
              />
            </div>
            <div class="flex flex-col min-w-[120px]">
              <label class="text-slate-200 font-semibold mb-1">Ano do FAF</label>
              <select
                v-model="filtroAno"
                class="px-2 py-1 rounded border border-white/30 bg-slate-900 text-white focus:outline-none focus:ring-2 focus:ring-teal-400 w-full appearance-none"
                style="background-image: url('data:image/svg+xml;utf8,<svg fill=\'white\' height=\'20\' viewBox=\'0 0 20 20\' width=\'20\' xmlns=\'http://www.w3.org/2000/svg\'><path d=\'M7.293 7.293a1 1 0 011.414 0L10 8.586l1.293-1.293a1 1 0 111.414 1.414l-2 2a1 1 0 01-1.414 0l-2-2a1 1 0 010-1.414z\'/></svg>'); background-repeat: no-repeat; background-position: right 0.5rem center; background-size: 1.25em 1.25em;"
              >
                <option value="">Todos</option>
                <option v-for="ano in anos" :key="ano" :value="ano">{{ ano }}</option>
              </select>
            </div>
            <div class="flex flex-col min-w-[140px]">
              <label class="text-slate-200 font-semibold mb-1">Força</label>
              <select
                v-model="filtroForca"
                class="px-2 py-1 rounded border border-white/30 bg-slate-900 text-white focus:outline-none focus:ring-2 focus:ring-teal-400 w-full appearance-none"
                style="background-image: url('data:image/svg+xml;utf8,<svg fill=\'white\' height=\'20\' viewBox=\'0 0 20 20\' width=\'20\' xmlns=\'http://www.w3.org/2000/svg\'><path d=\'M7.293 7.293a1 1 0 011.414 0L10 8.586l1.293-1.293a1 1 0 111.414 1.414l-2 2a1 1 0 01-1.414 0l-2-2a1 1 0 010-1.414z\'/></svg>'); background-repeat: no-repeat; background-position: right 0.5rem center; background-size: 1.25em 1.25em;"
              >
                <option value="">Todas</option>
                <option v-for="forca in forcasResponsaveis" :key="forca.id" :value="forca.id">
                  {{ forca.code }}
                </option>
              </select>
            </div>
            <div class="flex flex-col min-w-[140px]">
              <label class="text-slate-200 font-semibold mb-1">Área Temática</label>
              <select
                v-model="filtroArea"
                class="px-2 py-1 rounded border border-white/30 bg-slate-900 text-white focus:outline-none focus:ring-2 focus:ring-teal-400 w-full appearance-none"
                style="background-image: url('data:image/svg+xml;utf8,<svg fill=\'white\' height=\'20\' viewBox=\'0 0 20 20\' width=\'20\' xmlns=\'http://www.w3.org/2000/svg\'><path d=\'M7.293 7.293a1 1 0 011.414 0L10 8.586l1.293-1.293a1 1 0 111.414 1.414l-2 2a1 1 0 01-1.414 0l-2-2a1 1 0 010-1.414z\'/></svg>'); background-repeat: no-repeat; background-position: right 0.5rem center; background-size: 1.25em 1.25em;"
              >
                <option value="">Todas</option>
                <option v-for="area in areasTematicas" :key="area.id" :value="area.id">
                  {{ area.code }}
                </option>
              </select>
            </div>
            <div class="flex flex-col min-w-[160px]">
              <label class="text-slate-200 font-semibold mb-1">Data de Criação</label>
              <input
                v-model="filtroData"
                type="date"
                class="px-2 py-1 rounded border border-white/20 bg-slate-900 text-white focus:outline-none focus:ring-2 focus:ring-teal-400 w-full custom-date-input"
              />
            </div>
            <div class="flex items-center gap-2 min-w-[170px] mt-5 md:mt-0">
              <input
                id="chkConcluidos"
                v-model="mostrarConcluidos"
                type="checkbox"
                class="accent-teal-500 w-5 h-5 border-white/20 bg-white/10"
              />
              <label for="chkConcluidos" class="text-slate-200 font-semibold select-none"
                >Mostrar Concluídos</label
              >
            </div>
            <div class="flex-1 flex justify-end min-w-[200px]">
              <router-link
                to="/processos/novo"
                class="px-4 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded font-bold shadow hover:from-teal-700 hover:to-cyan-600 transition"
              >
                + Novo Processo
              </router-link>
            </div>
          </div>
        </div>
        <!-- Título -->
        <h1 class="text-3xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-4">Página de Processos</h1>
        <p class="text-slate-300 mb-6">Aqui você pode gerenciar seus processos.</p>
        <!-- Cards de Processo -->
        <div class="flex justify-center w-full">
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
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
import {
  buscarEtapasDoProcesso,
  buscarForcasResponsaveis,
  buscarAreasTematicas,
} from '../services/auth'

// Opções de Ano do FAF (igual CadastroProcessoView.vue)
const anoAtual = new Date().getFullYear()
const anos = Array.from({ length: anoAtual - 2019 + 1 }, (_, i) => 2019 + i)

const forcasResponsaveis = ref<{ id: number; code: string; name: string }[]>([])
const areasTematicas = ref<{ id: number; code: string; name: string }[]>([])
const filtroNome = ref('')
const filtroAno = ref('')
const filtroForca = ref('')
const filtroArea = ref('')
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
  forca_code: string
  area_code: string
  responsible_forces?: { id: number; code: string }
  thematic_areas?: { id: number; code: string }
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
    .select('*, responsible_forces(id, code), thematic_areas(id, code)')
    .order('created_at', { ascending: false })
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
          forca_code: proc.responsible_forces?.code || '',
          area_code: proc.thematic_areas?.code || '',
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

onMounted(async () => {
  await carregarProcessos()
  const { data: forcas } = await buscarForcasResponsaveis()
  if (forcas) forcasResponsaveis.value = forcas
  const { data: areas } = await buscarAreasTematicas()
  if (areas) areasTematicas.value = areas
})

const processosFiltrados = computed(() => {
  return processos.value.filter((proc) => {
    const nomeMatch = (proc.nome_acao || proc.area_code || '')
      .toLowerCase()
      .includes(filtroNome.value.toLowerCase())
    const anoMatch = !filtroAno.value || proc.ano_faf === Number(filtroAno.value)
    const forcaMatch =
      !filtroForca.value || proc.responsible_forces?.id === Number(filtroForca.value)
    const areaMatch = !filtroArea.value || proc.thematic_areas?.id === Number(filtroArea.value)
    const dataMatch =
      !filtroData.value ||
      (proc.data_encaminhamento_aprovacao &&
        proc.data_encaminhamento_aprovacao === filtroData.value)
    const statusMatch = mostrarConcluidos.value ? true : proc.status !== 'Concluído'
    return nomeMatch && anoMatch && forcaMatch && areaMatch && dataMatch && statusMatch
  })
})
</script>

<style scoped>
/* Melhora a visibilidade do ícone do calendário no input de data */
.custom-date-input::-webkit-calendar-picker-indicator {
  filter: invert(1) sepia(1) saturate(5) hue-rotate(140deg);
  opacity: 1;
  cursor: pointer;
}
.custom-date-input:focus::-webkit-calendar-picker-indicator {
  filter: invert(70%) sepia(1) saturate(8) hue-rotate(140deg) brightness(1.5);
}
.custom-date-input::-webkit-input-placeholder {
  color: #94a3b8;
  opacity: 1;
}
.custom-date-input::placeholder {
  color: #94a3b8;
  opacity: 1;
}
/* Firefox */
.custom-date-input::-moz-placeholder {
  color: #94a3b8;
  opacity: 1;
}
.custom-date-input::-ms-input-placeholder {
  color: #94a3b8;
  opacity: 1;
}
</style>
