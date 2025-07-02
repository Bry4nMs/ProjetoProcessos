<template>
  <Layout>
    <div class="w-full flex justify-end mb-6">
      <router-link
        to="/processos/novo"
        class="px-4 py-2 bg-abyss-primary text-abyss-black rounded font-bold shadow hover:bg-abyss-secondary transition"
      >
        +Novo Processo
      </router-link>
    </div>
    <ProcessoCard />
    <h1 class="text-3xl font-bold text-abyss-primary mb-4">Página de Processos</h1>
    <p class="text-abyss-secondary">Aqui você pode gerenciar seus processos.</p>
  </Layout>
</template>

<script setup lang="ts">
import Layout from '../components/Layout.vue'
import ProcessoCard from '../components/ProcessoCard.vue'
</script>
