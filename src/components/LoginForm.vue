<script setup lang="ts">
import { ref } from 'vue'
const tab = ref<'login' | 'register'>('login')
</script>

<template>
  <div class="w-full max-w-md mx-auto bg-white rounded-lg shadow-lg p-8 mt-12">
    <div class="flex mb-8 border-b border-abyss-deep">
      <button
        class="flex-1 py-2 text-lg font-semibold focus:outline-none transition border-b-2"
        :class="
          tab === 'login'
            ? 'border-abyss-primary text-abyss-primary'
            : 'border-transparent text-abyss-secondary'
        "
        @click="tab = 'login'"
        type="button"
      >
        Login
      </button>
      <button
        class="flex-1 py-2 text-lg font-semibold focus:outline-none transition border-b-2"
        :class="
          tab === 'register'
            ? 'border-abyss-primary text-abyss-primary'
            : 'border-transparent text-abyss-secondary'
        "
        @click="tab = 'register'"
        type="button"
      >
        Criar Conta
      </button>
    </div>
    <div v-if="tab === 'login'">
      <form class="flex flex-col gap-4">
        <div>
          <label class="block text-abyss-primary mb-1">Email</label>
          <input
            type="email"
            class="w-full px-4 py-2 rounded bg-abyss-black text-white focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          />
        </div>
        <div>
          <label class="block text-abyss-primary mb-1">Senha</label>
          <input
            type="password"
            class="w-full px-4 py-2 rounded bg-abyss-black text-white focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          />
        </div>
      </form>
    </div>
    <div v-else>
      <form class="flex flex-col gap-4">
        <div>
          <label class="block text-abyss-primary mb-1">Nome</label>
          <input
            type="text"
            class="w-full px-4 py-2 rounded bg-abyss-black text-white focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          />
        </div>
        <div>
          <label class="block text-abyss-primary mb-1">Email</label>
          <input
            type="email"
            class="w-full px-4 py-2 rounded bg-abyss-black text-white focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          />
        </div>
        <div>
          <label class="block text-abyss-primary mb-1">Senha</label>
          <input
            type="password"
            class="w-full px-4 py-2 rounded bg-abyss-black text-white focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          />
        </div>
        <div>
          <label class="block text-abyss-primary mb-1">Confirmar Senha</label>
          <input
            type="password"
            class="w-full px-4 py-2 rounded bg-abyss-black text-white focus:outline-none focus:ring-2 focus:ring-abyss-primary"
          />
        </div>
      </form>
    </div>
  </div>
</template>
