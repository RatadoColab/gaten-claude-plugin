// Referência: domains/ui-components/SKILL.md — Seção Testes de Componente
// Quando usar: estrutura de teste para componentes Vue 3 com Testing Library

// BaseButton.test.ts
import { render, screen, fireEvent } from '@testing-library/vue'
import { describe, it, expect, vi } from 'vitest'
import BaseButton from './BaseButton.vue'

describe('BaseButton', () => {
  it('renders label text', () => {
    render(BaseButton, { props: { label: 'Salvar' } })
    expect(screen.getByRole('button', { name: 'Salvar' })).toBeInTheDocument()
  })

  it('is disabled when prop is set', () => {
    render(BaseButton, { props: { label: 'Salvar', disabled: true } })
    expect(screen.getByRole('button')).toBeDisabled()
  })

  it('emits click event when clicked', async () => {
    const onClick = vi.fn()
    render(BaseButton, { props: { label: 'Salvar' }, attrs: { onClick } })
    await fireEvent.click(screen.getByRole('button'))
    expect(onClick).toHaveBeenCalledOnce()
  })

  it('does not emit click when disabled', async () => {
    const onClick = vi.fn()
    render(BaseButton, { props: { label: 'Salvar', disabled: true }, attrs: { onClick } })
    await fireEvent.click(screen.getByRole('button'))
    expect(onClick).not.toHaveBeenCalled()
  })
})
