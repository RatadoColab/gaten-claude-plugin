// Referência: domains/ui-components/SKILL.md — Seções Composables e Componentes Compostos
// Quando usar: hooks reutilizáveis e comunicação pai/filho sem prop drilling

// --- useDisclosure hook ---
// composables/useDisclosure.ts
// Manages open/close state for modals, dropdowns, accordions
export function useDisclosure(initial = false) {
  const isOpen = ref(initial)
  const open   = () => { isOpen.value = true }
  const close  = () => { isOpen.value = false }
  const toggle = () => { isOpen.value = !isOpen.value }
  return { isOpen, open, close, toggle }
}

// --- provide/inject com InjectionKey tipado ---

// tabs.types.ts — typed injection key
import type { InjectionKey, Ref } from 'vue'

export interface TabsContext {
  activeTab: Ref<number>
  setActiveTab: (index: number) => void
}

export const TABS_KEY = Symbol('tabs') as InjectionKey<TabsContext>

// --- Tabs.vue ---
import { ref, provide } from 'vue'
// import { TABS_KEY } from './tabs.types'

const activeTab = ref(0)
provide(TABS_KEY, {
  activeTab,
  setActiveTab: (i: number) => { activeTab.value = i },
})

// --- TabPanel.vue ---
import { inject } from 'vue'
// import { TABS_KEY } from './tabs.types'

const tabs = inject(TABS_KEY)
if (!tabs) throw new Error('TabPanel must be used inside <Tabs>')
