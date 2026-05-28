// Referência: domains/forms/SKILL.md — Seção Formulários Multi-step
// Quando usar: gerenciamento de estado entre etapas com persistência localStorage

// Example with Zustand for persistence
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface FormStore {
  step: number;
  data: Partial<FormData>;
  setStep: (step: number) => void;
  updateData: (partial: Partial<FormData>) => void;
  reset: () => void;
}

const useFormStore = create<FormStore>()(
  persist(
    (set) => ({
      step: 1,
      data: {},
      setStep: (step) => set({ step }),
      updateData: (partial) => set((state) => ({ data: { ...state.data, ...partial } })),
      reset: () => set({ step: 1, data: {} }),
    }),
    { name: 'form-wizard-storage' }
  )
);
