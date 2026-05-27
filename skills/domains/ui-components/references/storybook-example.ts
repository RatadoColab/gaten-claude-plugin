// Referência: domains/ui-components/SKILL.md — Seção Documentação com Storybook
// Quando usar: template de Story para componentes Vue 3 com Storybook

// BaseButton.stories.ts
import type { Meta, StoryObj } from '@storybook/vue3'
import BaseButton from './BaseButton.vue'

const meta: Meta<typeof BaseButton> = {
  title: 'Atoms/BaseButton',
  component: BaseButton,
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'danger'] },
    size:    { control: 'select', options: ['sm', 'md', 'lg'] },
    disabled: { control: 'boolean' },
  },
}
export default meta

type Story = StoryObj<typeof BaseButton>

export const Primary:  Story = { args: { variant: 'primary',  label: 'Salvar' } }
export const Danger:   Story = { args: { variant: 'danger',   label: 'Excluir' } }
export const Disabled: Story = { args: { disabled: true,      label: 'Indisponível' } }
