<template>
  <div class="relative inline-block text-left">
    <!-- Botão do sino -->
    <button @click="togglePanel" class="relative focus:outline-none">
      <svg class="w-7 h-7 text-slate-300 hover:text-teal-400 transition" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
      </svg>
      <span v-if="unreadCount > 0" class="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full px-1.5 py-0.5 border-2 border-white animate-pulse">{{ unreadCount }}</span>
    </button>
    <!-- Painel de notificações -->
    <div v-if="showPanel" class="origin-top-right absolute right-0 mt-2 w-80 rounded-lg shadow-lg bg-slate-900/95 ring-1 ring-black/10 z-50">
      <div class="p-4 border-b border-white/10 flex items-center justify-between">
        <span class="font-bold text-teal-400 text-lg">Notificações</span>
        <button @click="markAllAsRead" :disabled="markLoading" class="text-xs text-teal-400 hover:underline disabled:opacity-50">
          Marcar todas como lidas
        </button>
      </div>
      <div class="max-h-96 overflow-y-auto divide-y divide-white/10">
        <div v-if="notifications.length === 0" class="p-6 text-center text-slate-400">Nenhuma notificação.</div>
        <div v-for="n in notifications" :key="n.id" class="p-4 flex flex-col gap-1 bg-white/5 hover:bg-teal-500/10 transition">
          <span :class="['text-sm', n.is_read ? 'text-slate-400' : 'text-white font-semibold']">{{ n.message }}</span>
          <span class="text-xs text-slate-500">{{ formatarData(n.created_at) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '../services/supabase'
import { useAuth } from '../composables/useAuth'

interface Notification {
  id: string
  user_id: string
  process_id?: string | null
  step_id?: string | null
  message: string
  created_at: string
  is_read: boolean
}

const notifications = ref<Notification[]>([])
const showPanel = ref(false)
const { user, fetchUser } = useAuth()
const markLoading = ref(false);

const unreadCount = computed(() => notifications.value.filter(n => !n.is_read).length)

function formatarData(data: string) {
  if (!data) return ''
  return new Date(data).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' })
}

async function fetchNotifications() {
  let usuario = user.value
  if (!usuario) usuario = await fetchUser()
  if (!usuario) return
  const { data } = await supabase
    .from('notifications')
    .select('*')
    .eq('user_id', usuario.id)
    .order('created_at', { ascending: false })
  if (data) notifications.value = data
}

async function markAllAsRead() {
  if (markLoading.value) return;
  markLoading.value = true;
  let usuario = user.value
  if (!usuario) usuario = await fetchUser()
  if (!usuario) {
    markLoading.value = false;
    return
  }
  const unreadIds = notifications.value.filter(n => !n.is_read).map(n => n.id)
  if (unreadIds.length === 0) {
    markLoading.value = false;
    return
  }
  const { error } = await supabase
    .from('notifications')
    .update({ is_read: true })
    .in('id', unreadIds)
  if (!error) {
    notifications.value = notifications.value.map(n => ({ ...n, is_read: true }))
  }
  markLoading.value = false;
}

function togglePanel() {
  showPanel.value = !showPanel.value
  if (showPanel.value) {
    markAllAsRead()
  }
}

let channel: ReturnType<typeof supabase.channel> | null = null

onMounted(async () => {
  await fetchNotifications()
  let usuario = user.value
  if (!usuario) usuario = await fetchUser()
  if (!usuario) return
  channel = supabase.channel('notifications_' + usuario.id)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: `user_id=eq.${usuario.id}`
      },
      (payload) => {
        if (payload.new) {
          notifications.value.unshift(payload.new as Notification)
        }
      }
    )
    .subscribe()
})

onUnmounted(() => {
  if (channel) {
    channel.unsubscribe()
  }
})
</script>

<style scoped>
/* Badge animado */
.animate-pulse {
  animation: pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
</style>
