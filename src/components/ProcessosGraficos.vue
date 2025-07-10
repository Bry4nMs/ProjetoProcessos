<template>
  <div class="w-full max-w-4xl mx-auto flex flex-col md:flex-row gap-8 mb-8">
    <div class="flex-1 bg-white rounded-lg shadow p-6 flex flex-col items-center justify-center">
      <div class="flex items-center gap-2 mb-2">
        <svg
          class="w-6 h-6 text-green-500"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
        </svg>
        <span class="text-lg font-bold text-green-600">Processos Concluídos</span>
      </div>
      <svg width="64" height="64" viewBox="0 0 36 36" class="mb-2">
        <circle cx="18" cy="18" r="16" fill="#e5f9ee" />
        <circle
          cx="18"
          cy="18"
          r="16"
          fill="none"
          stroke="#22c55e"
          stroke-width="4"
          :stroke-dasharray="concluidoPercent + ', 100'"
          stroke-dashoffset="25"
          stroke-linecap="round"
        />
        <text x="18" y="22" text-anchor="middle" font-size="1em" fill="#22c55e">
          {{ concluidos }}
        </text>
      </svg>
      <span class="text-gray-500">de {{ total }} processos</span>
    </div>
    <div class="flex-1 bg-white rounded-lg shadow p-6 flex flex-col items-center justify-center">
      <div class="flex items-center gap-2 mb-2">
        <svg
          class="w-6 h-6 text-yellow-500"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3" />
          <circle cx="12" cy="12" r="10" />
        </svg>
        <span class="text-lg font-bold text-yellow-600">Processos em Aberto</span>
      </div>
      <svg width="64" height="64" viewBox="0 0 36 36" class="mb-2">
        <circle cx="18" cy="18" r="16" fill="#fef9c3" />
        <circle
          cx="18"
          cy="18"
          r="16"
          fill="none"
          stroke="#eab308"
          stroke-width="4"
          :stroke-dasharray="abertoPercent + ', 100'"
          stroke-dashoffset="25"
          stroke-linecap="round"
        />
        <text x="18" y="22" text-anchor="middle" font-size="1em" fill="#eab308">
          {{ abertos }}
        </text>
      </svg>
      <span class="text-gray-500">de {{ total }} processos</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, defineProps } from 'vue'
const props = defineProps<{ processos: Array<{ status: string }> }>()
const total = computed(() => props.processos.length)
const concluidos = computed(() => props.processos.filter((p) => p.status === 'Concluído').length)
const abertos = computed(() => props.processos.filter((p) => p.status !== 'Concluído').length)
const concluidoPercent = computed(() =>
  total.value === 0 ? 0 : (concluidos.value / total.value) * 100,
)
const abertoPercent = computed(() => (total.value === 0 ? 0 : (abertos.value / total.value) * 100))
</script>

<style scoped>
svg {
  display: block;
}
</style>
