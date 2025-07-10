<template>
  <nav class="flex flex-col h-screen w-40 bg-abyss-dark p-6 shadow-lg">
    <router-link
      to="/"
      class="mb-4 text-abyss-primary hover:text-abyss-secondary font-semibold transition"
    >
      Processos
    </router-link>
    <router-link
      to="/analises"
      class="mb-4 text-abyss-primary hover:text-abyss-secondary font-semibold transition"
    >
      Análises
    </router-link>
    <router-link
      to="/minha-conta"
      class="mb-4 text-abyss-primary hover:text-abyss-secondary font-semibold transition"
    >
      Minha Conta
    </router-link>
    <div class="flex-1"></div>
    <template v-if="user">
      <span class="text-abyss-primary font-semibold mb-4 block"
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
