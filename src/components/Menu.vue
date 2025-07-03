<template>
  <nav class="flex gap-4 bg-abyss-dark p-4 rounded-lg shadow items-center">
    <router-link
      to="/"
      class="text-abyss-primary hover:text-abyss-secondary font-semibold transition"
    >
      Processos
    </router-link>
    <a href="#" class="text-abyss-primary hover:text-abyss-secondary font-semibold transition"
      >Minha Conta</a
    >
    <div class="flex-1"></div>
    <template v-if="user">
      <span class="text-abyss-primary font-semibold mr-4"
        >Olá, {{ user.user_metadata?.name || user.email }}</span
      >
      <button
        @click="handleLogout"
        class="px-3 py-1 bg-abyss-primary text-white rounded shadow hover:bg-abyss-secondary transition"
      >
        Sair
      </button>
    </template>
  </nav>
</template>

<script setup lang="ts">
import { useAuth } from '../composables/useAuth'
import { useRouter } from 'vue-router'

const { user, logout } = useAuth()
const router = useRouter()

async function handleLogout() {
  await logout()
  router.push('/login')
}
</script>

<script lang="ts">
export default {
  name: 'AppMenu',
}
</script>
