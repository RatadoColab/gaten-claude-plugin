// Referência: domains/forms/SKILL.md — Seção React Hook Form + Zod
// Quando usar: formulário React completo com validação tipada e erros de servidor

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email('Informe um e-mail válido'),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: 'As senhas não coincidem',
  path: ['confirmPassword'],
});

type FormData = z.infer<typeof schema>;

function RegistrationForm() {
  const { register, handleSubmit, setError, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    mode: 'onBlur',       // validate on blur
    reValidateMode: 'onChange', // re-validate immediately on fix
  });

  const onSubmit = async (data: FormData) => {
    try {
      await submitToServer(data);
    } catch (err) {
      // Map server validation errors back to form fields
      if (err.errors) {
        Object.entries(err.errors).forEach(([field, message]) => {
          setError(field as keyof FormData, { type: 'server', message: message as string });
        });
      }
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <div>
        <label htmlFor="email">E-mail *</label>
        <input
          id="email"
          type="email"
          {...register('email')}
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? 'email-error' : undefined}
        />
        {errors.email && (
          <span id="email-error" role="alert">{errors.email.message}</span>
        )}
      </div>
      <div>
        <label htmlFor="password">Senha *</label>
        <input
          id="password"
          type="password"
          {...register('password')}
          aria-invalid={!!errors.password}
          aria-describedby={errors.password ? 'password-error' : undefined}
        />
        {errors.password && (
          <span id="password-error" role="alert">{errors.password.message}</span>
        )}
      </div>
      <div>
        <label htmlFor="confirmPassword">Confirmar Senha *</label>
        <input
          id="confirmPassword"
          type="password"
          {...register('confirmPassword')}
          aria-invalid={!!errors.confirmPassword}
          aria-describedby={errors.confirmPassword ? 'confirm-error' : undefined}
        />
        {errors.confirmPassword && (
          <span id="confirm-error" role="alert">{errors.confirmPassword.message}</span>
        )}
      </div>
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Enviando...' : 'Cadastrar'}
      </button>
    </form>
  );
}
