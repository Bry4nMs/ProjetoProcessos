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

const regras = ref<any[]>([])
const etapas = ref<any[]>([])
const usuarios = ref<any[]>([])
const showModal = ref(false)
const editandoRegra = ref(false)
const regraEditadaId = ref<number | null>(null)

const form = reactive({
  rule_name: '',
  trigger_type: '',
  trigger_step_template_id: '',
  trigger_delay_days: null as number | null,
  action_type: '',
  action_user_id: '',
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

function abrirModalEditar(regra: any) {
  resetForm()
  editandoRegra.value = true
  regraEditadaId.value = regra.id
  form.rule_name = regra.rule_name
  form.trigger_type = regra.trigger_type
  if (regra.trigger_metadata) {
    const meta = regra.trigger_metadata
    form.trigger_step_template_id = meta.step_template_id || ''
    form.trigger_delay_days = meta.delay_days || null
  }
  form.action_type = regra.action_type
  if (regra.action_metadata) {
    const meta = regra.action_metadata
    form.action_user_id = meta.user_id || ''
    form.action_notification_target = meta.target || ''
    form.action_notification_user_id = meta.user_id || ''
    form.action_notification_message = meta.message || ''
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

function descricaoGatilho(regra: any) {
  if (regra.trigger_type === 'on_step_entry') {
    return `Ao entrar na etapa ID ${regra.trigger_metadata?.step_template_id}`
  }
  if (regra.trigger_type === 'after_delay') {
    return `Após ${regra.trigger_metadata?.delay_days} dias na etapa ID ${regra.trigger_metadata?.step_template_id}`
  }
  return '-'
}

function descricaoAcao(regra: any) {
  if (regra.action_type === 'assign_user') {
    return `Atribuir ao usuário ID ${regra.action_metadata?.user_id}`
  }
  if (regra.action_type === 'send_notification') {
    return `Notificar ${regra.action_metadata?.target} - "${regra.action_metadata?.message}"`
  }
  return '-'
}

async function handleSaveRule() {
  // Montar metadados
  let trigger_metadata: any = {}
  if (form.trigger_type === 'on_step_entry') {
    trigger_metadata = { step_template_id: Number(form.trigger_step_template_id) }
  } else if (form.trigger_type === 'after_delay') {
    trigger_metadata = { step_template_id: Number(form.trigger_step_template_id), delay_days: form.trigger_delay_days }
  }
  let action_metadata: any = {}
  if (form.action_type === 'assign_user') {
    action_metadata = { user_id: form.action_user_id }
  } else if (form.action_type === 'send_notification') {
    action_metadata = { target: form.action_notification_target, user_id: form.action_notification_user_id, message: form.action_notification_message }
  }
  const payload = {
    rule_name: form.rule_name,
    trigger_type: form.trigger_type,
    trigger_metadata,
    action_type: form.action_type,
    action_metadata,
    is_active: form.is_active,
  }
  let res
  if (editandoRegra.value && regraEditadaId.value) {
    res = await supabase.from('automation_rules').update(payload).eq('id', regraEditadaId.value)
  } else {
    res = await supabase.from('automation_rules').insert([payload])
  }
  if (!res.error) {
    showModal.value = false
    await fetchRules()
  }
}

async function excluirRegra(id: number) {
  if (!window.confirm('Tem certeza que deseja excluir esta regra?')) return
  await supabase.from('automation_rules').delete().eq('id', id)
  await fetchRules()
}

async function toggleAtivo(regra: any) {
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
</style>
