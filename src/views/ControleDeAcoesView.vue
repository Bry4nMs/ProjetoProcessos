<template>
  <Layout>
    <div class="min-h-screen flex justify-center items-stretch px-8">
      <div class="w-full max-w-7xl mx-auto space-y-8">
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

        <div class="flex items-center justify-between mb-4">
          <h1 class="text-3xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent">
            Controle de Ações
          </h1>
        </div>

        <div v-if="loadingAcoes" class="flex justify-center items-center py-12">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-400"></div>
        </div>

        <div v-else class="w-full overflow-x-auto">
          <table class="w-full border-collapse bg-white/5 backdrop-blur-md border border-white/20 shadow-xl rounded-lg">
            <thead>
              <tr class="bg-slate-800 text-left">
                <th class="px-4 py-3 text-slate-300 font-semibold">Código</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Nome da Ação</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Ano</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Processos</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Taxa Conclusão</th>
                <th class="px-4 py-3 text-slate-300 font-semibold">Ações</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="acoesFiltradas.length === 0">
                <td colspan="6" class="px-4 py-6 text-center text-slate-400">
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
                    <button @click="visualizarAcao(acao)" class="px-3 py-1 bg-blue-600/20 text-blue-300 rounded text-xs font-semibold hover:bg-blue-600/30 transition">Ver</button>
                    <button @click="editarAcao(acao)" class="px-3 py-1 bg-yellow-600/20 text-yellow-300 rounded text-xs font-semibold hover:bg-yellow-600/30 transition">Editar</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-if="acaoSelecionada" class="mt-8">
          <div class="bg-white/10 backdrop-blur-md border border-white/20 shadow-xl rounded-lg p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-2xl font-bold text-white">Processos da Ação: {{ acaoSelecionada.name }} <span class="text-sm text-slate-400 font-normal">({{ acaoSelecionada.action_code }})</span></h2>
              <button @click="fecharDetalhesAcao" class="text-slate-400 hover:text-white transition"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg></button>
            </div>
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
            <div class="mb-6"><div class="flex border-b border-slate-700"><button @click="abaAtiva = 'processos'" :class="{'border-teal-400 text-teal-400': abaAtiva === 'processos', 'border-transparent text-slate-400 hover:text-white': abaAtiva !== 'processos'}" class="px-4 py-2 border-b-2 font-medium text-sm transition-colors">Processos Vinculados</button><button @click="alterarAba('registros')" :class="{'border-teal-400 text-teal-400': abaAtiva === 'registros', 'border-transparent text-slate-400 hover:text-white': abaAtiva !== 'registros'}" class="px-4 py-2 border-b-2 font-medium text-sm transition-colors">Registros de Gastos</button></div></div>

            <div v-if="abaAtiva === 'processos'">
              <div class="flex justify-between items-center mb-6"><h3 class="text-lg font-semibold text-white">Processos Vinculados</h3><button @click="abrirLinkProcessModal" class="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-lg transition flex items-center gap-2"><svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>Vincular Processo</button></div>
              <div v-if="loadingProcessosAcao" class="flex justify-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-400"></div></div>
              <div v-else-if="processosAcao.length === 0" class="text-center py-8 text-slate-400">Nenhum processo vinculado a esta ação.</div>
              <div v-else class="overflow-x-auto"><table class="w-full border-collapse"><thead><tr class="bg-slate-800 text-left"><th class="px-4 py-3 text-slate-300 font-semibold">Processo SEI</th><th class="px-4 py-3 text-slate-300 font-semibold">Nome</th><th class="px-4 py-3 text-slate-300 font-semibold">Status</th><th class="px-4 py-3 text-slate-300 font-semibold">Progresso</th><th class="px-4 py-3 text-slate-300 font-semibold">Criado em</th><th class="px-4 py-3 text-slate-300 font-semibold">Ação</th></tr></thead><tbody><tr v-for="processo in processosAcao" :key="processo.id" class="border-b border-slate-700 hover:bg-slate-800/50 transition-colors"><td class="px-4 py-3 text-white font-mono text-sm cursor-pointer" @click="abrirModalProcesso(processo, 'detalhes')">{{ processo.process_number || 'N/A' }}</td><td class="px-4 py-3 text-white cursor-pointer" @click="abrirModalProcesso(processo, 'detalhes')">{{ processo.name }}</td><td class="px-4 py-3 cursor-pointer" @click="abrirModalProcesso(processo, 'detalhes')"><span :class="{'bg-green-600/20 text-green-300': processo.status === 'Concluído','bg-yellow-600/20 text-yellow-300': processo.status === 'Em Andamento','bg-slate-600/20 text-slate-300': processo.status === 'Não Iniciado'}" class="px-2 py-1 rounded-full text-xs font-semibold">{{ processo.status }}</span></td><td class="px-4 py-3 cursor-pointer" @click="abrirModalProcesso(processo, 'detalhes')"><div class="flex items-center gap-2"><div class="w-20 bg-slate-700 rounded-full h-2"><div class="bg-gradient-to-r from-teal-500 to-cyan-400 h-2 rounded-full" :style="{ width: `${processo.progress_percentage || 0}%` }"></div></div><span class="text-xs text-slate-400">{{ processo.progress_percentage || 0 }}%</span></div></td><td class="px-4 py-3 text-slate-400 text-sm cursor-pointer" @click="abrirModalProcesso(processo, 'detalhes')">{{ formatarData(processo.created_at) }}</td><td class="px-4 py-3 text-center"><button @click.stop="abrirModalConfirmacao(processo)" class="p-2 text-slate-400 hover:text-red-500 rounded-full hover:bg-red-500/10 transition"><svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg></button></td></tr></tbody></table></div>
            </div>

            <div v-else-if="abaAtiva === 'registros'">
              <div v-if="loadingRegistros" class="flex justify-center py-8"><div class="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-400"></div></div>
              <div v-else-if="registrosGastos.length === 0" class="text-center py-8 text-slate-400">Nenhum registro de gasto encontrado para esta ação.</div>
              <div v-else class="overflow-x-auto"><table class="w-full border-collapse"><thead><tr class="bg-slate-800 text-left"><th class="px-4 py-3 text-slate-300 font-semibold">Processo SEI</th><th class="px-4 py-3 text-slate-300 font-semibold">Descrição</th><th class="px-4 py-3 text-slate-300 font-semibold">Valor Utilizado</th><th class="px-4 py-3 text-slate-300 font-semibold">Data Aquisição</th><th class="px-4 py-3 text-slate-300 font-semibold">Anexo</th></tr></thead><tbody><tr v-for="registro in registrosGastos" :key="registro.id" class="border-b border-slate-700"><td class="px-4 py-3 text-white font-mono text-sm">{{ registro.process_number || 'N/A' }}</td><td class="px-4 py-3 text-white">{{ registro.description }}</td><td class="px-4 py-3 text-green-400 font-semibold">{{ formatarMoeda(registro.amount_used) }}</td><td class="px-4 py-3 text-slate-400 text-sm">{{ formatarData(registro.acquisition_date) }}</td><td class="px-4 py-3"><a v-if="registro.file_url" :href="registro.file_url" target="_blank" class="text-teal-400 hover:underline">Ver</a></td></tr></tbody></table></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <ActionFormModal v-if="showActionModal" :show="showActionModal" :acao="acaoParaEdicao" :forcas-responsaveis="forcasResponsaveis" :areas-tematicas="areasTematicas" @close="fecharModalAcao" @acao-salva="handleAcaoSalva" />
    <LinkProcessModal v-if="showLinkProcessModal && acaoSelecionada" :show="showLinkProcessModal" :action-id="acaoSelecionada.id" @close="fecharLinkProcessModal" @process-linked="handleProcessLinked" />
    <ProcessoDetalhesModal v-if="processoSelecionado" :show="showDetalhesModal" :processo="processoSelecionado" @close="fecharModalProcesso" @switch-to-etapas="handleSwitchToEtapas" @switch-to-registros="handleSwitchToRegistros" @atualizar-processo="atualizarProcesso" />
    <ProcessoEtapasModal v-if="processoSelecionado" :show="showEtapasModal" :processo="processoSelecionado" @close="fecharModalProcesso" @switch-to-detalhes="handleSwitchToDetalhes" @switch-to-registros="handleSwitchToRegistros" @atualizar-processo="atualizarProcesso" />
    <ProcessoRegistrosModal v-if="processoSelecionado" :show="showRegistrosModal" :processo="processoSelecionado" @close="fecharModalProcesso" @switch-to-detalhes="handleSwitchToDetalhes" @switch-to-etapas="handleSwitchToEtapas" @atualizar-processo="atualizarProcesso" />
    <ConfirmationModal v-if="showConfirmationModal" :show="showConfirmationModal" title="Confirmar Ação" message="Tem certeza que deseja retirar este processo da Ação?" @cancel="fecharModalConfirmacao" @confirm="handleDesvincularConfirmado" />
  </Layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../services/supabase'
import { useFormatters } from '../composables/useFormatters' // ✨ IMPORTAÇÃO ADICIONADA
import {
  buscarForcasResponsaveis,
  buscarAreasTematicas,
} from '../services/auth'
import Layout from '../components/Layout.vue'
import ActionFormModal from '../components/ActionFormModal.vue'
import ProcessoDetalhesModal from '../components/ProcessoDetalhesModal.vue'
import ProcessoEtapasModal from '../components/ProcessoEtapasModal.vue'
import ProcessoRegistrosModal from '../components/ProcessoRegistrosModal.vue'
import LinkProcessModal from '../components/LinkProcessModal.vue'
import ConfirmationModal from '../components/ConfirmationModal.vue'



// Interfaces
interface Action {
  id: string;
  name: string;
  action_code: string;
  year: number;
  expense_nature: string;
  thematic_area_id: number;
  responsible_force_id: number;
  thematic_area?: { id: number; code: string };
  responsible_force?: { id: number; code: string };
  statistics?: {
    total_processes: number;
    completed_processes: number;
    completion_rate: number;
  };
  created_at: string;
  updated_at: string;
  user_id: string;
}
interface ProcessoAcao {
  id: string;
  name: string;
  valor_total_destinado?: number;
  valor_inicial_padrao?: number;
  valor_rendimentos?: number;
  valor_economicidade?: number;
  area_code?: string;
  ano_faf?: number;
  tipo_natureza_despesa?: string;
  forca_code?: string;
  data_encaminhamento_aprovacao?: string;
  created_at: string;
  codigo_transferegov?: string;
  qtd_itens?: number;
  descricao_itens?: string;
  destinacao_itens?: string;
  descricao_geral?: string;
  status: string;
  etapaAtual: number;
  totalEtapas: number;
  progress_percentage: number;
  process_number: string;
}
interface RegistroGasto {
  id: string;
  process_id: string;
  process_number: string | null;
  description: string | null;
  amount_used: number;
  request_date: string | null;
  acquisition_date: string | null;
  file_url?: string | null;
}

// Composables
const route = useRoute();
const router = useRouter();
const { formatarValor: formatarMoeda, formatarData } = useFormatters();
// Opções de Ano
const anoAtual = new Date().getFullYear();
const anos = Array.from({ length: anoAtual - 2019 + 1 }, (_, i) => 2019 + i);

// Estados
const acoes = ref<Action[]>([]);
const loadingAcoes = ref(false);
const forcasResponsaveis = ref<{ id: number; code: string; name: string }[]>([]);
const areasTematicas = ref<{ id: number; code: string; name: string }[]>([]);
const filtroNome = ref('');
const filtroCodigo = ref('');
const filtroAno = ref('');
const showActionModal = ref(false);
const acaoParaEdicao = ref<Action | null>(null);
const processoSelecionado = ref<ProcessoAcao | null>(null);
const showDetalhesModal = ref(false);
const showEtapasModal = ref(false);
const showRegistrosModal = ref(false);
const showLinkProcessModal = ref(false);
const acaoSelecionada = ref<Action | null>(null);
const processosAcao = ref<ProcessoAcao[]>([]);
const loadingProcessosAcao = ref(false);
const abaAtiva = ref<'processos' | 'registros'>('processos');
const registrosGastos = ref<RegistroGasto[]>([]);
const loadingRegistros = ref(false);
const showConfirmationModal = ref(false);
const processoParaDesvincular = ref<ProcessoAcao | null>(null);


// Funções de carregamento
async function carregarAcoes() {
  loadingAcoes.value = true;
  try {
    const { data, error } = await supabase.rpc('get_all_actions_with_stats');
    if (error) throw error;
    acoes.value = data?.actions || [];
  } catch (error) {
    console.error('Erro ao carregar ações:', error);
    acoes.value = [];
  } finally {
    loadingAcoes.value = false;
  }
}

async function buscarDadosDaAcao(actionId: string) {
  loadingProcessosAcao.value = true;
  loadingRegistros.value = true;
  try {
    const { data, error } = await supabase.rpc('get_records_for_action', { p_action_id: actionId });
    if (error) throw error;
    processosAcao.value = data?.processes || [];
    registrosGastos.value = data?.records || [];
  } catch (error) {
    console.error('Erro ao carregar dados da ação:', error);
    processosAcao.value = [];
    registrosGastos.value = [];
  } finally {
    loadingProcessosAcao.value = false;
    loadingRegistros.value = false;
  }
}

function alterarAba(aba: 'processos' | 'registros') {
  abaAtiva.value = aba;
}

// Computed
const acoesFiltradas = computed(() => {
  if (!acoes.value) return [];
  return acoes.value.filter((acao) => {
    const nomeMatch = !filtroNome.value || acao.name.toLowerCase().includes(filtroNome.value.toLowerCase());
    const codigoMatch = !filtroCodigo.value || acao.action_code.toLowerCase().includes(filtroCodigo.value.toLowerCase());
    const anoMatch = !filtroAno.value || acao.year === Number(filtroAno.value);
    return nomeMatch && codigoMatch && anoMatch;
  });
});
const processosAcaoConcluidos = computed(() => processosAcao.value.filter(p => p.status === 'Concluído'));
const processosAcaoAndamento = computed(() => processosAcao.value.filter(p => p.status === 'Em Andamento'));
const processosAcaoNaoIniciados = computed(() => processosAcao.value.filter(p => p.status === 'Não Iniciado'));

// Funções de ação
function abrirModalNovaAcao() {
  acaoParaEdicao.value = null;
  showActionModal.value = true;
}
function editarAcao(acao: Action) {
  acaoParaEdicao.value = acao;
  showActionModal.value = true;
}
function fecharModalAcao() {
  showActionModal.value = false;
  acaoParaEdicao.value = null;
}
const abrirModalProcesso = (processo: ProcessoAcao, tipo: 'detalhes' | 'etapas' | 'registros') => {
  processoSelecionado.value = processo;
  router.push({ query: { ...route.query, processo: processo.id, modal: tipo } });
};

const fecharModalProcesso = () => {
  const newQuery = { ...route.query };
  delete newQuery.processo;
  delete newQuery.modal;

  router.push({ query: newQuery});
}

function handleSwitchToEtapas() {
  if (processoSelecionado.value) router.push({ query: { ...route.query, modal: 'etapas' } });
}
function handleSwitchToDetalhes() {
  if (processoSelecionado.value) router.push({ query: { ...route.query, modal: 'detalhes' } });
}
function handleSwitchToRegistros() {
  if (processoSelecionado.value) router.push({ query: { ...route.query, modal: 'registros' } });
}

function atualizarProcesso() {
  if (acaoSelecionada.value) {
    buscarDadosDaAcao(acaoSelecionada.value.id);
  }
}

const abrirLinkProcessModal = () => { showLinkProcessModal.value = true; };
const fecharLinkProcessModal = () => { showLinkProcessModal.value = false; };
const handleProcessLinked = async () => {
  if (acaoSelecionada.value) {
    await buscarDadosDaAcao(acaoSelecionada.value.id);
  }
  setTimeout(() => { fecharLinkProcessModal(); }, 1500);
};

function visualizarAcao(acao: Action) {
  acaoSelecionada.value = acao;
  abaAtiva.value = 'processos';
  // ✨ CORREÇÃO: Chamando a função com o nome correto
  buscarDadosDaAcao(acao.id);
}
function fecharDetalhesAcao() {
  acaoSelecionada.value = null;
  processosAcao.value = [];
  registrosGastos.value = [];
}
function handleAcaoSalva() {
  fecharModalAcao();
  carregarAcoes();
}

// Em ControleDeAcoesView.vue -> <script setup>

function abrirModalConfirmacao(processo: ProcessoAcao) {
  processoParaDesvincular.value = processo;
  showConfirmationModal.value = true;
}

function fecharModalConfirmacao() {
  showConfirmationModal.value = false;
  processoParaDesvincular.value = null;
}

async function handleDesvincularConfirmado() {
  if (!processoParaDesvincular.value) return;

  const { error } = await supabase.rpc('unlink_process_from_action', {
    p_process_id: processoParaDesvincular.value.id
  });

  if (error) {
    console.error("Erro ao desvincular processo:", error);
    alert("Falha ao desvincular o processo.");
  } else {
    // Sucesso! Recarrega a lista de processos da ação.
    if (acaoSelecionada.value) {
      await buscarDadosDaAcao(acaoSelecionada.value.id);
    }
  }
  fecharModalConfirmacao();
}

// Lifecycle
onMounted(async () => {
  carregarAcoes();
  const { data: forcas } = await buscarForcasResponsaveis();
  if (forcas) forcasResponsaveis.value = forcas;
  const { data: areas } = await buscarAreasTematicas();
  if (areas) areasTematicas.value = areas;
});

watch(
  () => [route.query.processo, route.query.modal],
  // ✨ Nomes dos parâmetros ajustados para serem usados
  ([processoId, modalType]) => {
    if (processoId && typeof processoId === 'string' && modalType && processosAcao.value.length > 0) {
      const processoEncontrado = processosAcao.value.find(p => p.id === processoId);

      if (processoEncontrado) {
        processoSelecionado.value = processoEncontrado;
        showDetalhesModal.value = modalType === 'detalhes';
        showEtapasModal.value = modalType === 'etapas';
        showRegistrosModal.value = modalType === 'registros';
      }
    } else {
      // Limpa o estado se os parâmetros da URL forem removidos
      processoSelecionado.value = null;
      showDetalhesModal.value = false;
      showEtapasModal.value = false;
      showRegistrosModal.value = false;
    }
  },
  { immediate: true, deep: true }
);

</script>
