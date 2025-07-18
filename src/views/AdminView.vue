<template>
  <AppLayout>
    <div class="min-h-screen flex flex-col items-center px-8 py-8">
      <div class="w-full max-w-4xl bg-white/10 backdrop-blur-md border border-white/20 rounded-lg shadow-xl p-10">
        <h1 class="text-3xl font-bold bg-gradient-to-r from-teal-400 to-cyan-300 bg-clip-text text-transparent mb-6">Regras de Automação</h1>
        <div class="flex justify-between items-center mb-6">
          <button @click="abrirModalCriar" class="px-4 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded font-bold shadow hover:from-teal-700 hover:to-cyan-600 transition">
            + Criar Nova Regra
          </button>
        </div>
        <table class="w-full text-left bg-white/5 rounded-lg overflow-hidden">
          <thead>
            <tr class="text-teal-300 border-b border-white/10">
              <th class="py-2 px-3">Nome da Regra</th>
              <th class="py-2 px-3">Gatilho</th>
              <th class="py-2 px-3">Ação</th>
              <th class="py-2 px-3">Ativo</th>
              <th class="py-2 px-3">Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="regra in regras" :key="regra.id" class="border-b border-white/10 hover:bg-white/10">
              <td class="py-2 px-3">{{ regra.rule_name }}</td>
              <td class="py-2 px-3">{{ descricaoGatilho(regra) }}</td>
              <td class="py-2 px-3">{{ descricaoAcao(regra) }}</td>
              <td class="py-2 px-3">
                <input type="checkbox" v-model="regra.is_active" @change="toggleAtivo(regra)" />
              </td>
              <td class="py-2 px-3 flex gap-2">
                <button @click="abrirModalEditar(regra)" class="text-teal-400 hover:underline">Editar</button>
                <button @click="excluirRegra(regra.id)" class="text-red-400 hover:underline">Excluir</button>
              </td>
            </tr>
            <tr v-if="regras.length === 0">
              <td colspan="5" class="text-center text-slate-400 py-6">Nenhuma regra cadastrada.</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Modal de Criação/Edição -->
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40">
        <div class="bg-gradient-to-br from-slate-900/95 to-blue-900/95 backdrop-blur-md border border-white/20 text-white rounded-xl shadow-2xl p-8 max-w-2xl w-full relative max-h-[90vh] overflow-y-auto">
          <button class="absolute top-2 right-2 p-2 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors" @click="fecharModal">
            <svg xmlns='http://www.w3.org/2000/svg' class='w-6 h-6' fill='none' viewBox='0 0 24 24' stroke='currentColor' stroke-width='2'><path stroke-linecap='round' stroke-linejoin='round' d='M18 6L6 18M6 6l12 12'/></svg>
          </button>
          <h2 class="text-2xl font-bold mb-4">{{ editandoRegra ? 'Editar Regra' : 'Criar Nova Regra' }}</h2>
          <form @submit.prevent="handleSaveRule">
            <div class="mb-4">
              <label class="block text-slate-300 mb-1">Nome da Regra</label>
              <input v-model="form.rule_name" type="text" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" required />
            </div>
            <div class="mb-4">
              <label class="block text-slate-300 mb-1">Gatilho (Quando...)</label>
              <select v-model="form.trigger_type" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" required>
                <option value="">Selecione...</option>
                <option value="on_step_entry">Ao entrar em uma etapa</option>
                <option value="after_delay">Após um tempo em uma etapa</option>
              </select>
            </div>
            <div v-if="form.trigger_type === 'on_step_entry' || form.trigger_type === 'after_delay'" class="mb-4">
              <label class="block text-slate-300 mb-1">Etapa</label>
              <select v-model="form.trigger_step_template_id" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" required>
                <option value="">Selecione a etapa...</option>
                <option v-for="etapa in etapas" :key="etapa.id" :value="etapa.id">{{ etapa.name }}</option>
              </select>
            </div>
            <div v-if="form.trigger_type === 'after_delay'" class="mb-4">
              <label class="block text-slate-300 mb-1">Dias de atraso</label>
              <input v-model.number="form.trigger_delay_days" type="number" min="1" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" required />
            </div>
            <div class="mb-4">
              <label class="block text-slate-300 mb-1">Ação (Então...)</label>
              <select v-model="form.action_type" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" required>
                <option value="">Selecione...</option>
                <option value="assign_user">Atribuir a um usuário</option>
                <option value="send_notification">Enviar uma notificação</option>
              </select>
            </div>
            <div v-if="form.action_type === 'assign_user'" class="mb-4">
              <label class="block text-slate-300 mb-1">Usuário</label>
              <select v-model="form.action_user_id" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" required>
                <option value="">Selecione o usuário...</option>
                <option v-for="user in usuarios" :key="user.id" :value="user.id">{{ user.nome }}</option>
              </select>
            </div>
            <div v-if="form.action_type === 'assign_user'" class="mb-4">
              <label class="block text-slate-300 mb-1">Mensagem da Notificação</label>
              <textarea v-model="form.action_message" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" rows="2" placeholder="Mensagem que será enviada ao usuário ao ser atribuído à etapa."></textarea>
            </div>
            <div v-if="form.action_type === 'send_notification'" class="mb-4">
              <label class="block text-slate-300 mb-1">Destinatário</label>
              <select v-model="form.action_notification_target" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" required>
                <option value="">Selecione...</option>
                <option value="owner">Dono do processo</option>
                <option value="user">Usuário específico</option>
              </select>
              <div v-if="form.action_notification_target === 'user'" class="mt-2">
                <label class="block text-slate-300 mb-1">Usuário Destinatário</label>
                <select v-model="form.action_notification_user_id" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white">
                  <option value="">Selecione o usuário...</option>
                  <option v-for="user in usuarios" :key="user.id" :value="user.id">{{ user.nome }}</option>
                </select>
              </div>
              <label class="block text-slate-300 mb-1 mt-2">Mensagem</label>
              <textarea v-model="form.action_notification_message" class="w-full px-3 py-2 rounded bg-white/10 border border-white/20 text-white" rows="2" required></textarea>
            </div>
            <div v-if="saveError" class="mt-4 text-center p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
              <p class="text-red-400 text-sm font-semibold">{{ saveError }}</p>
            </div>
            <div class="flex justify-end gap-2 mt-6">
              <button type="button" @click="fecharModal" class="px-4 py-2 bg-slate-700 text-white rounded font-bold">Cancelar</button>
              <button type="submit" class="px-4 py-2 bg-gradient-to-r from-teal-600 to-cyan-500 text-white rounded font-bold shadow hover:from-teal-700 hover:to-cyan-600 transition">Salvar</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import AppLayout from '../components/Layout.vue'
import { ref, reactive, onMounted } from 'vue'
import { supabase } from '../services/supabase'

// Tipos explícitos para evitar 'any'
interface Regra {
  id: number;
  rule_name: string;
  trigger_type: string;
  trigger_metadata?: Record<string, unknown>;
  action_type: string;
  action_metadata?: Record<string, unknown>;
  is_active: boolean;
}
interface Etapa { id: number; name: string }
interface Usuario { id: string; nome: string }

const regras = ref<Regra[]>([])
const etapas = ref<Etapa[]>([])
const usuarios = ref<Usuario[]>([])
const showModal = ref(false)
const editandoRegra = ref(false)
const regraEditadaId = ref<number | null>(null)
const saveError = ref('');

const form = reactive({
  rule_name: '',
  trigger_type: '',
  trigger_step_template_id: '',
  trigger_delay_days: null as number | null,
  action_type: '',
  action_user_id: '',
  action_message: '', // <-- novo campo
  action_notification_target: '',
  action_notification_user_id: '',
  action_notification_message: '',
  is_active: true,
})

function resetForm() {
  form.rule_name = ''
  form.trigger_type = ''
  form.trigger_step_template_id = ''
  form.trigger_delay_days = null
  form.action_type = ''
  form.action_user_id = ''
  form.action_message = '' // <-- novo campo
  form.action_notification_target = ''
  form.action_notification_user_id = ''
  form.action_notification_message = ''
  form.is_active = true
  regraEditadaId.value = null
}

function abrirModalCriar() {
  resetForm()
  editandoRegra.value = false
  showModal.value = true
}

function abrirModalEditar(regra: Regra) {
  resetForm()
  editandoRegra.value = true
  regraEditadaId.value = regra.id
  form.rule_name = regra.rule_name
  form.trigger_type = regra.trigger_type
  if (regra.trigger_metadata) {
    const meta = regra.trigger_metadata as Record<string, unknown>
    form.trigger_step_template_id = meta.step_template_id as string || ''
    form.trigger_delay_days = meta.delay_days as number || null
  }
  form.action_type = regra.action_type
  if (regra.action_metadata) {
    const meta = regra.action_metadata as Record<string, unknown>
    form.action_user_id = meta.user_id as string || ''
    form.action_message = meta.message as string || '' // <-- novo campo
    form.action_notification_target = meta.target as string || ''
    form.action_notification_user_id = meta.user_id as string || ''
    form.action_notification_message = meta.message as string || ''
  }
  form.is_active = regra.is_active
  showModal.value = true
}

function fecharModal() {
  showModal.value = false
}

async function fetchRules() {
  const { data } = await supabase.from('automation_rules').select('*').order('id', { ascending: false })
  regras.value = data || []
}

async function fetchEtapas() {
  const { data } = await supabase.from('step_templates').select('id, name').order('id')
  etapas.value = data || []
}

async function fetchUsuarios() {
  const { data } = await supabase.from('profiles').select('id, nome').order('nome')
  usuarios.value = data || []
}

function descricaoGatilho(regra: Regra): string {
  const metadata = regra.trigger_metadata as Record<string, unknown>;
  if (!metadata) return '-';

  const etapaId = metadata.step_template_id;
  const etapa = etapas.value.find(e => e.id === etapaId);
  const nomeEtapa = etapa ? `'${etapa.name}'` : `ID ${etapaId}`;

  if (regra.trigger_type === 'on_step_entry') {
    return `Ao entrar na etapa ${nomeEtapa}`;
  }
  if (regra.trigger_type === 'after_delay') {
    return `Após ${metadata.delay_days} dias na etapa ${nomeEtapa}`;
  }
  return 'Gatilho desconhecido';
}

function descricaoAcao(regra: Regra): string {
  const metadata = regra.action_metadata as Record<string, unknown>;
  if (!metadata) return '-';

  if (regra.action_type === 'assign_user') {
    const usuarioId = metadata.user_id;
    const usuario = usuarios.value.find(u => u.id === usuarioId);
    const nomeUsuario = usuario ? `'${usuario.nome}'` : `ID ${usuarioId}`;
    return `Atribuir ao usuário ${nomeUsuario}`;
  }

  if (regra.action_type === 'send_notification') {
    let destinatario = '';
    if (metadata.target === 'owner') {
      destinatario = 'dono do processo';
    } else if (metadata.target === 'user') {
      const usuarioId = metadata.user_id;
      const usuario = usuarios.value.find(u => u.id === usuarioId);
      destinatario = usuario ? `usuário '${usuario.nome}'` : `usuário ID ${usuarioId}`;
    }
    return `Notificar ${destinatario}: "${metadata.message}"`;
  }
  return 'Ação desconhecida';
}

async function handleSaveRule() {
  saveError.value = '';
  // Montar metadados
  let trigger_metadata: Record<string, unknown> = {};
  if (form.trigger_type === 'on_step_entry') {
    trigger_metadata = { step_template_id: Number(form.trigger_step_template_id) };
  } else if (form.trigger_type === 'after_delay') {
    trigger_metadata = { step_template_id: Number(form.trigger_step_template_id), delay_days: form.trigger_delay_days };
  }
  let action_metadata: Record<string, unknown> = {};
  if (form.action_type === 'assign_user') {
    action_metadata = { user_id: form.action_user_id };
    if (form.action_message) action_metadata.message = form.action_message;
  } else if (form.action_type === 'send_notification') {
    action_metadata = { target: form.action_notification_target, user_id: form.action_notification_user_id, message: form.action_notification_message };
  }
  const payload = {
    rule_name: form.rule_name,
    trigger_type: form.trigger_type,
    trigger_metadata,
    action_type: form.action_type,
    action_metadata,
    is_active: form.is_active,
  };
  let res;
  if (editandoRegra.value && regraEditadaId.value) {
    res = await supabase.from('automation_rules').update(payload).eq('id', regraEditadaId.value);
  } else {
    res = await supabase.from('automation_rules').insert([payload]);
  }
  if (res.error) {
    console.error("Erro ao salvar regra:", res.error);
    saveError.value = `Falha ao salvar: ${res.error.message}`;
  } else {
    showModal.value = false;
    await fetchRules();
  }
}

async function excluirRegra(id: number) {
  if (!window.confirm('Tem certeza que deseja excluir esta regra?')) return
  await supabase.from('automation_rules').delete().eq('id', id)
  await fetchRules()
}

async function toggleAtivo(regra: Regra) {
  await supabase.from('automation_rules').update({ is_active: regra.is_active }).eq('id', regra.id)
}

onMounted(async () => {
  await fetchRules()
  await fetchEtapas()
  await fetchUsuarios()
})
</script>

<style scoped>
table {
  border-collapse: separate;
  border-spacing: 0;
}
th, td {
  border-right: 1px solid #1e293b;
}
th:last-child, td:last-child {
  border-right: none;
}

/* Melhora contraste do <select> e <option> no modal */
select, select option {
  background-color: #1e293b !important; /* Fundo escuro */
  color: #fff !important;               /* Texto branco */
}
select:focus {
  border-color: #14b8a6;
  box-shadow: 0 0 0 2px #14b8a6aa;
}
option[value=''] {
  color: #94a3b8 !important; /* Placeholder mais claro */
}
</style>
