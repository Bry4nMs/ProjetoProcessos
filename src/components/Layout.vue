<template>
  <div class="min-h-screen bg-abyss-black flex flex-col">
    <Menu />
    <main class="flex-1 flex flex-col items-center justify-center">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
import Menu from './Menu.vue'
</script>
