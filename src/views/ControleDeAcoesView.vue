<template>
  <Layout>
    <div class="min-h-screen flex justify-center items-stretch px-8">
      <div class="w-full max-w-7xl mx-auto space-y-8">
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
            <div class="flex flex-col min-w-[180px]">
              <label class="text-slate-200 font-semibold mb-1">Código da Ação</label>
              <input
                v-model="filtroCodigo"
                type="text"
                placeholder="Digite o código da ação"
                class="px-2 py-1 rounded border border-white/20 bg-slate-900 text-white placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-400 w-full"
              />
            </div>
            <div class="flex flex-col min-w-[120px]">
              <label class="text-slate-200 font-semibold mb-1">Ano</label>
              <select
                v-model="filtroAno"
                class="px-2 py-1 rounded border border-white/30 bg-slate-900 text-white focus:outline-none focus:ring-2 focus:ring-teal-400 w-full appearance-none"
                style="background-image: url('data:image/svg+xml;utf8,<svg fill=\'white\' height=\'20\' viewBox=\'0 0 20 20\' width=\'20\' xmlns=\'http://www.w3.org/2000/svg\'><path d=\'M7.293 7.293a1 1 0 011.414 0L10 8.586l1.293-1.293a1 1 0 111.414 1.414l-2 2a1 1 0 01-1.414 0l-2-2a1 1 0 010-1.414z\'/></svg>'); background-repeat: no-repeat; background-position: right 0.5rem center; background-size: 1.25em 1.25em;"
              >
                <option value="">Todos</option>
                <option v-for="ano in anos" :key="ano" :value="ano">{{ ano }}</option>
              </select>
            </div>
            <div class="flex-1 flex justify-end min-w-[200px]">
              <button
                @click="abrirModalNovaAcao"
                class="px-4 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded font-bold shadow hover:from-teal-700 hover:to-cyan-600 transition"
              >
                + Nova Ação
              </button>
            </div>
          </div>
        </div>

        <!-- Título -->
        <div class="flex items-center justify-between mb-4">
          <h1 class="text-3xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">
            Controle de Ações
          </h1>
        </div>

        <!-- Loading -->
        <div v-if="loadingAcoes" class="flex justify-center items-center py-12">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-400"></div>
        </div>

        <!-- Tabela de Ações -->
        <div v-else class="w-full overflow-x-auto">
          <table class="w-full border-collapse bg-white/5 backdrop-blur-md border border-white/20 shadow-xl rounded-lg">
            <thead>
              <tr class="bg-slate-800 text-left">
                <th class="px-4 py-3 text-slate-300 font-semibold">Código</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Nome da Ação</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Ano</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Área Temática</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Força Responsável</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Natureza</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Processos</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Taxa Conclusão</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Ações</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="acoesFiltradas.length === 0">
                <td colspan="9" class="px-4 py-6 text-center text-slate-400">
                  {{ loadingAcoes ? 'Carregando...' : 'Nenhuma ação encontrada' }}
                </td>
              </tr>
              <tr
                v-for="acao in acoesFiltradas"
                :key="acao.id"
                class="border-b border-slate-700 hover:bg-slate-800/50 transition-colors"
              >
                <td class="px-4 py-3 text-white font-mono text-sm">{{ acao.action_code }}</td>
                <td class="px-4 py-3 text-white font-medium">{{ acao.name }}</td>
                <td class="px-4 py-3 text-white">{{ acao.year }}</td>
                <td class="px-4 py-3">
                  <span class="bg-teal-600/20 text-teal-300 px-2 py-1 rounded-full text-xs font-semibold">
                    {{ acao.thematic_area?.code || 'N/A' }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span class="bg-blue-600/20 text-blue-300 px-2 py-1 rounded-full text-xs font-semibold">
                    {{ acao.responsible_force?.code || 'N/A' }}
                  </span>
                </td>
                <td class="px-4 py-3">
                  <span
                    :class="{
                      'bg-green-600/20 text-green-300': acao.expense_nature === 'Custeio',
                      'bg-purple-600/20 text-purple-300': acao.expense_nature === 'Investimento'
                    }"
                    class="px-2 py-1 rounded-full text-xs font-semibold"
                  >
                    {{ acao.expense_nature }}
                  </span>
                </td>
                <td class="px-4 py-3 text-center">
                  <span class="text-white font-semibold">{{ acao.statistics?.total_processes || 0 }}</span>
                </td>
                <td class="px-4 py-3">
                  <div class="flex items-center gap-2">
                    <div class="w-16 bg-slate-700 rounded-full h-2">
                      <div
                        class="bg-gradient-to-r from-teal-500 to-cyan-400 h-2 rounded-full"
                        :style="{ width: `${acao.statistics?.completion_rate || 0}%` }"
                      ></div>
                    </div>
                    <span class="text-xs text-slate-400">{{ acao.statistics?.completion_rate || 0 }}%</span>
                  </div>
                </td>
                <td class="px-4 py-3">
                  <div class="flex gap-2">
                    <button
                      @click="visualizarAcao(acao)"
                      class="px-3 py-1 bg-blue-600/20 text-blue-300 rounded text-xs font-semibold hover:bg-blue-600/30 transition"
                      title="Visualizar detalhes"
                    >
                      Ver
                    </button>
                    <button
                      @click="editarAcao(acao)"
                      class="px-3 py-1 bg-yellow-600/20 text-yellow-300 rounded text-xs font-semibold hover:bg-yellow-600/30 transition"
                      title="Editar ação"
                    >
                      Editar
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Seção de Processos da Ação Selecionada -->
        <div v-if="acaoSelecionada" class="mt-8">
          <div class="bg-white/10 backdrop-blur-md border border-white/20 shadow-xl rounded-lg p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-2xl font-bold text-white">
                Processos da Ação: {{ acaoSelecionada.name }}
                <span class="text-sm text-slate-400 font-normal">({{ acaoSelecionada.action_code }})</span>
              </h2>
              <button
                @click="fecharDetalhesAcao"
                class="text-slate-400 hover:text-white transition"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <!-- Estatísticas da Ação -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
              <div class="bg-slate-800/50 rounded-lg p-4">
                <div class="text-2xl font-bold text-white">{{ processosAcao.length }}</div>
                <div class="text-sm text-slate-400">Total de Processos</div>
              </div>
              <div class="bg-slate-800/50 rounded-lg p-4">
                <div class="text-2xl font-bold text-green-400">{{ processosAcaoConcluidos.length }}</div>
                <div class="text-sm text-slate-400">Concluídos</div>
              </div>
              <div class="bg-slate-800/50 rounded-lg p-4">
                <div class="text-2xl font-bold text-yellow-400">{{ processosAcaoAndamento.length }}</div>
                <div class="text-sm text-slate-400">Em Andamento</div>
              </div>
              <div class="bg-slate-800/50 rounded-lg p-4">
                <div class="text-2xl font-bold text-slate-400">{{ processosAcaoNaoIniciados.length }}</div>
                <div class="text-sm text-slate-400">Não Iniciados</div>
              </div>
            </div>

            <!-- Lista de Processos -->
            <div v-if="loadingProcessosAcao" class="flex justify-center py-8">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-400"></div>
            </div>
            <div v-else-if="processosAcao.length === 0" class="text-center py-8 text-slate-400">
              Nenhum processo vinculado a esta ação.
            </div>
            <div v-else class="overflow-x-auto">
              <table class="w-full border-collapse">
                <thead>
                  <tr class="bg-slate-800 text-left">
                    <th class="px-4 py-3 text-slate-300 font-semibold">Processo SEI</th>
                    <th class="px-4 py-3 text-slate-300 font-semibold">Nome</th>
                    <th class="px-4 py-3 text-slate-300 font-semibold">Status</th>
                    <th class="px-4 py-3 text-slate-300 font-semibold">Progresso</th>
                    <th class="px-4 py-3 text-slate-300 font-semibold">Criado em</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="processo in processosAcao"
                    :key="processo.id"
                    class="border-b border-slate-700 hover:bg-slate-800/50 transition-colors"
                  >
                    <td class="px-4 py-3 text-white font-mono text-sm">{{ processo.process_number || 'N/A' }}</td>
                    <td class="px-4 py-3 text-white">{{ processo.name }}</td>
                    <td class="px-4 py-3">
                      <span
                        :class="{
                          'bg-green-600/20 text-green-300': processo.status === 'Concluído',
                          'bg-yellow-600/20 text-yellow-300': processo.status === 'Em Andamento',
                          'bg-slate-600/20 text-slate-300': processo.status === 'Não Iniciado'
                        }"
                        class="px-2 py-1 rounded-full text-xs font-semibold"
                      >
                        {{ processo.status }}
                      </span>
                    </td>
                    <td class="px-4 py-3">
                      <div class="flex items-center gap-2">
                        <div class="w-20 bg-slate-700 rounded-full h-2">
                          <div
                            class="bg-gradient-to-r from-teal-500 to-cyan-400 h-2 rounded-full"
                            :style="{ width: `${processo.progress_percentage || 0}%` }"
                          ></div>
                        </div>
                        <span class="text-xs text-slate-400">{{ processo.progress_percentage || 0 }}%</span>
                      </div>
                    </td>
                    <td class="px-4 py-3 text-slate-400 text-sm">
                      {{ formatarData(processo.created_at) }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de Formulário de Ação -->
    <ActionFormModal
      v-if="showActionModal"
      :show="showActionModal"
      :acao="acaoParaEdicao"
      :forcas-responsaveis="forcasResponsaveis"
      :areas-tematicas="areasTematicas"
      @close="fecharModalAcao"
      @acao-salva="handleAcaoSalva"
    />
  </Layout>
</template>

<script setup lang="ts">
import Layout from '../components/Layout.vue'
import ActionFormModal from '../components/ActionFormModal.vue'
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'
import {
  buscarForcasResponsaveis,
  buscarAreasTematicas,
} from '../services/auth'

// Interfaces
// Em ControleDeAcoesView.vue

interface Action {
  id: string;
  name: string;
  action_code: string;
  year: number;
  expense_nature: string;
  // IDs para formulários e relacionamentos
  thematic_area_id: number;
  responsible_force_id: number;
  // Objetos aninhados (opcionais) para exibição
  thematic_area?: { id: number; code: string };
  responsible_force?: { id: number; code: string };
  // Estatísticas (opcionais)
  statistics?: {
    total_processes: number;
    completed_processes: number;
    completion_rate: number;
  };
  // Campos padrão
  created_at: string;
  updated_at: string;
  user_id: string;
}

interface ProcessoAcao {
  id: string
  name: string
  process_number: string
  description: string
  created_at: string
  current_step: number
  total_steps: number
  progress_percentage: number
  status: string
  thematic_area?: { id: number; code: string }
  responsible_force?: { id: number; code: string }
}

// Composables
const { user, fetchUser } = useAuth()

// Opções de Ano
const anoAtual = new Date().getFullYear()
const anos = Array.from({ length: anoAtual - 2019 + 1 }, (_, i) => 2019 + i)

// Estados
const acoes = ref<Action[]>([])
const loadingAcoes = ref(false)
const forcasResponsaveis = ref<{ id: number; code: string; name: string }[]>([])
const areasTematicas = ref<{ id: number; code: string; name: string }[]>([])

// Filtros
const filtroNome = ref('')
const filtroCodigo = ref('')
const filtroAno = ref('')
const filtroForca = ref('');
const filtroArea = ref('');
const filtroNatureza = ref('');

// Modal de Ação
const showActionModal = ref(false)
const acaoParaEdicao = ref<Action | null>(null)

// Detalhes da Ação Selecionada
const acaoSelecionada = ref<Action | null>(null)
const processosAcao = ref<ProcessoAcao[]>([])
const loadingProcessosAcao = ref(false)

// Funções de carregamento
// Em ControleDeAcoesView.vue -> <script setup>

// Em ControleDeAcoesView.vue
// Em ControleDeAcoesView.vue -> <script setup>

// SUBSTITUA SUA FUNÇÃO carregarAcoes POR ESTA:
async function carregarAcoes() {
  loadingAcoes.value = true;
  try {
    let usuario = user.value;
    if (!usuario) {
      usuario = await fetchUser();
    }
    if (!usuario) {
      acoes.value = [];
      return;
    }

    const { data, error } = await supabase.rpc('get_all_actions_with_stats', {
      p_year: filtroAno.value ? Number(filtroAno.value) : null,
      p_thematic_area_id: filtroArea.value ? Number(filtroArea.value) : null,
      p_responsible_force_id: filtroForca.value ? Number(filtroForca.value) : null,
      p_expense_nature: filtroNatureza.value || null
    });

    if (error) throw error; // Lança o erro para ser pego pelo catch

    acoes.value = data?.actions || [];
  } catch (error) {
    console.error('Erro ao carregar ações:', error);
    acoes.value = [];
  } finally {
    loadingAcoes.value = false;
  }
}

async function carregarProcessosAcao(actionId: string) {
  loadingProcessosAcao.value = true
  try {
    const { data, error } = await supabase.rpc('get_records_for_action', {
      p_action_id: actionId
    })

    if (error) {
      console.error('Erro ao carregar processos da ação:', error)
      processosAcao.value = []
      return
    }

    processosAcao.value = data?.processes || []
  } catch (error) {
    console.error('Erro ao carregar processos da ação:', error)
    processosAcao.value = []
  } finally {
    loadingProcessosAcao.value = false
  }
}

// Computed
// Em ControleDeAcoesView.vue -> <script setup>

// SUBSTITUA SEU COMPUTED ATUAL POR ESTE
const acoesFiltradas = computed(() => {
  return acoes.value.filter((acao) => {
    const nomeMatch = !filtroNome.value || acao.name.toLowerCase().includes(filtroNome.value.toLowerCase());
    const codigoMatch = !filtroCodigo.value || acao.action_code.toLowerCase().includes(filtroCodigo.value.toLowerCase());
    const anoMatch = !filtroAno.value || acao.year === Number(filtroAno.value);

    return nomeMatch && codigoMatch && anoMatch;
  });
});

watch([filtroAno, filtroForca, filtroArea, filtroNatureza], () => {
  carregarAcoes();
});

const processosAcaoConcluidos = computed(() => {
  return processosAcao.value.filter(p => p.status === 'Concluído')
})

const processosAcaoAndamento = computed(() => {
  return processosAcao.value.filter(p => p.status === 'Em Andamento')
})

const processosAcaoNaoIniciados = computed(() => {
  return processosAcao.value.filter(p => p.status === 'Não Iniciado')
})

// Funções de ação
function abrirModalNovaAcao() {
  acaoParaEdicao.value = null
  showActionModal.value = true
}

function editarAcao(acao: Action) {
  acaoParaEdicao.value = acao
  showActionModal.value = true
}

function fecharModalAcao() {
  showActionModal.value = false
  acaoParaEdicao.value = null
}

function visualizarAcao(acao: Action) {
  acaoSelecionada.value = acao
  carregarProcessosAcao(acao.id)
}

function fecharDetalhesAcao() {
  acaoSelecionada.value = null
  processosAcao.value = []
}

function handleAcaoSalva() {
  fecharModalAcao()
  carregarAcoes()
}

// Funções utilitárias
function formatarData(data: string) {
  return new Date(data).toLocaleDateString('pt-BR')
}

// Lifecycle
onMounted(async () => {
  await carregarAcoes()
  const { data: forcas } = await buscarForcasResponsaveis()
  if (forcas) forcasResponsaveis.value = forcas
  const { data: areas } = await buscarAreasTematicas()
  if (areas) areasTematicas.value = areas
})
</script>
