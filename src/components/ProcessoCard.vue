<script setup lang="ts">
import { ref } from 'vue'

const showModal = ref(false)

// Dados de exemplo para o card
const processo = {
  nomeAcao: 'Merenda Escolar 2025',
  areaTematica: 'Educação',
  anoFaf: 2025,
  tipoNatureza: 'Custeio',
  forcaResponsavel: 'Secretaria de Educação - GO',
  valor: 3500000,
  descricao: 'Fornecimento de alimentação para 50.000 alunos',
  dataCriacao: '2025-05-01',
  codigoTransferegov: '123456',
  quantidadeItens: 20,
  descricaoItens: 'Alimentos variados',
  destinacaoItens: 'Merenda escolar',
  valorRendimentos: 0,
  valorEconomicidade: 0,
  valorTotal: 3500000,
  descricaoGeral: 'Processo concluído com sucesso.',
  status: 'Concluído',
}

function formatarValor(valor: number) {
  return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}
function formatarData(data: string) {
  return new Date(data).toLocaleDateString('pt-BR')
}
</script>

<template>
  <div>
    <!-- Card -->
    <div
      class="bg-white rounded-xl shadow-lg p-6 mb-6 cursor-pointer hover:shadow-2xl transition relative border border-abyss-deep"
      @click="showModal = true"
    >
      <div class="flex items-center justify-between mb-2">
        <span class="bg-green-100 text-green-700 text-xs font-bold px-3 py-1 rounded-full"
          >Concluído</span
        >
        <span class="text-gray-400 text-xl">&#9825;</span>
      </div>
      <h2 class="text-xl font-bold text-abyss-dark mb-1">{{ processo.nomeAcao }}</h2>
      <p class="text-gray-600 mb-2">{{ processo.descricao }}</p>
      <div class="flex items-center gap-2 text-sm text-gray-500 mb-2">
        <span class="inline-flex items-center gap-1">
          <svg
            class="w-4 h-4 text-abyss-primary"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M17.657 16.657L13.414 20.9a2 2 0 01-2.828 0l-4.243-4.243a8 8 0 1111.314 0z"
            />
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
            />
          </svg>
          {{ processo.forcaResponsavel }}
        </span>
      </div>
      <div class="flex items-center gap-2 mb-2">
        <span class="text-green-700 font-bold text-lg">{{ formatarValor(processo.valor) }}</span>
      </div>
      <div class="flex flex-wrap gap-2 mb-2">
        <span class="bg-abyss-primary/10 text-abyss-primary text-xs px-2 py-1 rounded">{{
          processo.tipoNatureza
        }}</span>
        <span class="bg-abyss-primary/10 text-abyss-primary text-xs px-2 py-1 rounded">{{
          processo.areaTematica
        }}</span>
      </div>
      <div class="flex items-center justify-between text-xs text-gray-500 mt-4">
        <span>Criado em {{ formatarData(processo.dataCriacao) }}</span>
        <span>Ano FAF: {{ processo.anoFaf }}</span>
      </div>
    </div>

    <!-- Modal Detalhes -->
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40"
    >
      <div class="bg-white rounded-xl shadow-xl p-8 max-w-lg w-full relative">
        <button
          class="absolute top-2 right-2 text-gray-400 hover:text-abyss-primary text-2xl"
          @click="showModal = false"
        >
          &times;
        </button>
        <h2 class="text-xl font-bold text-abyss-dark mb-2">{{ processo.nomeAcao }}</h2>
        <p class="mb-2 text-gray-600">{{ processo.descricao }}</p>
        <div class="mb-2"><b>Área Temática:</b> {{ processo.areaTematica }}</div>
        <div class="mb-2"><b>Ano do FAF:</b> {{ processo.anoFaf }}</div>
        <div class="mb-2"><b>Tipo de Natureza:</b> {{ processo.tipoNatureza }}</div>
        <div class="mb-2"><b>Força Responsável:</b> {{ processo.forcaResponsavel }}</div>
        <div class="mb-2"><b>Valor:</b> {{ formatarValor(processo.valor) }}</div>
        <div class="mb-2"><b>Data de Criação:</b> {{ formatarData(processo.dataCriacao) }}</div>
        <div class="mb-2"><b>Código Transferegov:</b> {{ processo.codigoTransferegov }}</div>
        <div class="mb-2"><b>Quantidade de Itens:</b> {{ processo.quantidadeItens }}</div>
        <div class="mb-2"><b>Descrição dos Itens:</b> {{ processo.descricaoItens }}</div>
        <div class="mb-2"><b>Destinação dos Itens:</b> {{ processo.destinacaoItens }}</div>
        <div class="mb-2">
          <b>Valor de Rendimentos:</b> {{ formatarValor(processo.valorRendimentos) }}
        </div>
        <div class="mb-2">
          <b>Valor de Economicidade:</b> {{ formatarValor(processo.valorEconomicidade) }}
        </div>
        <div class="mb-2">
          <b>Valor Total Destinado à Ação:</b> {{ formatarValor(processo.valorTotal) }}
        </div>
        <div class="mb-2"><b>Descrição Geral:</b> {{ processo.descricaoGeral }}</div>
        <div class="flex justify-end mt-4">
          <button
            class="px-4 py-2 bg-abyss-primary text-abyss-black rounded font-bold shadow hover:bg-abyss-secondary transition"
            @click="showModal = false"
          >
            Fechar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
