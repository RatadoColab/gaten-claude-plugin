// Referência: domains/ui-components/SKILL.md — Seção Performance
// Quando usar: otimizações de reatividade Vue 3 (markRaw, computed, async components)

// --- markRaw com Chart.js ---
import { ref, markRaw } from 'vue'
import Chart from 'chart.js/auto'

// Without markRaw, Vue would try to make the Chart instance reactive — causing errors
const chartInstance = ref(markRaw(new Chart(canvas, config)))

// --- computed list em vez de v-if + v-for ---
// Good: computed list instead of v-if + v-for on the same element
const activeItems = computed(() =>
  items.value.filter(item => item.active)
)
