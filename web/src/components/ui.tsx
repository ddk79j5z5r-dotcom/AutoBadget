// Общие компоненты интерфейса — порт Theme/Components.swift

import { ChevronRight, Search, X, type LucideIcon } from 'lucide-react'
import type { ComponentProps, CSSProperties, ReactNode } from 'react'
import { expenseCategoryInfo, type ExpenseCategory } from '@/models/types'
import { expenseIcon } from './icons'

export const cx = (...classes: (string | false | null | undefined)[]) => classes.filter(Boolean).join(' ')

// MARK: - Card

export const Card = ({ children, className, padding = 'p-4', style }: {
  children: ReactNode; className?: string; padding?: string; style?: CSSProperties
}) => (
  <div className={cx('rounded-card border border-stroke bg-card', padding, className)} style={style}>
    {children}
  </div>
)

/** Плавное появление при загрузке экрана */
export const Appear = ({ children, delay = 0, className }: { children: ReactNode; delay?: number; className?: string }) => (
  <div className={cx('animate-appear', className)} style={{ animationDelay: `${delay}s` }}>
    {children}
  </div>
)

// MARK: - Иконки

export const CategoryIcon = ({ category, size = 40 }: { category: ExpenseCategory; size?: number }) => {
  const Icon = expenseIcon[category]
  const color = expenseCategoryInfo[category].color
  return (
    <span
      className="inline-flex shrink-0 items-center justify-center text-white"
      style={{
        width: size, height: size, borderRadius: size * 0.3,
        background: `linear-gradient(180deg, ${color}, ${color}b3)`,
        boxShadow: `0 2px 8px ${color}59`,
      }}
    >
      <Icon size={size * 0.46} strokeWidth={2.2} />
    </span>
  )
}

export const SymbolBadge = ({ icon: Icon, color, size = 40 }: { icon: LucideIcon; color: string; size?: number }) => (
  <span
    className="relative inline-flex shrink-0 items-center justify-center overflow-hidden"
    style={{ width: size, height: size, borderRadius: size * 0.32, color }}
  >
    <span className="absolute inset-0" style={{ background: color, opacity: 0.16 }} />
    <Icon size={size * 0.46} strokeWidth={2.2} className="relative" />
  </span>
)

export const StatusPill = ({ text, color }: { text: string; color: string }) => (
  <span className="relative inline-flex shrink-0 items-center overflow-hidden rounded-full px-2.5 py-1 text-xs font-semibold" style={{ color }}>
    <span className="absolute inset-0" style={{ background: color, opacity: 0.15 }} />
    <span className="relative">{text}</span>
  </span>
)

// MARK: - Заголовки и плитки

export const SectionHeader = ({ title, action }: { title: string; action?: ReactNode }) => (
  <div className="flex items-center justify-between gap-3">
    <h2 className="text-lg font-bold">{title}</h2>
    {action}
  </div>
)

/** «Все ›» в заголовках карточек */
export const AllLink = ({ label = 'Все' }: { label?: string }) => (
  <span className="inline-flex items-center gap-0.5 text-sm font-semibold text-accent">
    {label}
    <ChevronRight size={16} strokeWidth={2.6} />
  </span>
)

export const StatTile = ({ title, value, icon: Icon, tint = 'var(--color-accent)', footnote }: {
  title: string; value: string; icon?: LucideIcon; tint?: string; footnote?: string
}) => (
  <Card padding="p-3.5" className="flex h-full flex-col gap-2">
    <div className="flex items-center gap-1.5 text-xs text-text-2">
      {Icon && <Icon size={14} style={{ color: tint }} strokeWidth={2.4} />}
      <span className="truncate">{title}</span>
    </div>
    <div className="font-rounded truncate text-xl font-bold">{value}</div>
    <div className="truncate text-[11px] text-text-3">{footnote ?? ' '}</div>
  </Card>
)

export const InfoRow = ({ title, value, valueClass }: { title: string; value: ReactNode; valueClass?: string }) => (
  <div className="flex items-baseline justify-between gap-4 text-sm">
    <span className="text-text-2">{title}</span>
    <span className={cx('text-right', valueClass)}>{value}</span>
  </div>
)

export const Divider = ({ inset = 0 }: { inset?: number }) => (
  <div className="h-px bg-stroke" style={{ marginLeft: inset }} />
)

// MARK: - Фильтры и поиск

export const FilterChip = ({ title, selected, onClick }: { title: string; selected: boolean; onClick: () => void }) => (
  <button
    type="button"
    onClick={onClick}
    className={cx(
      'h-9 shrink-0 rounded-full px-3.5 text-sm font-semibold transition active:scale-95',
      selected ? 'bg-accent text-black' : 'border border-stroke bg-card text-text hover:bg-elevated',
    )}
  >
    {title}
  </button>
)

export const ChipBar = ({ children }: { children: ReactNode }) => (
  <div className="no-scrollbar -mx-4 flex gap-2 overflow-x-auto px-4 py-0.5">{children}</div>
)

export const SearchField = ({ value, onChange, placeholder = 'Поиск' }: {
  value: string; onChange: (v: string) => void; placeholder?: string
}) => (
  <label className="flex h-11 items-center gap-2.5 rounded-small border border-stroke bg-card px-3.5">
    <Search size={18} className="shrink-0 text-text-3" />
    <input className="min-w-0 flex-1" value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} />
    {value && (
      <button type="button" onClick={() => onChange('')} className="text-text-3" aria-label="Очистить">
        <X size={16} />
      </button>
    )}
  </label>
)

// MARK: - Прогресс

export const ProgressBar = ({ value, color = 'var(--color-accent)', height = 6 }: {
  value: number; color?: string; height?: number
}) => (
  <div className="w-full overflow-hidden rounded-full bg-white/8" style={{ height }}>
    <div
      className="h-full rounded-full transition-[width] duration-500 ease-out"
      style={{ width: `${Math.max(Math.min(value, 1), 0.02) * 100}%`, background: color }}
    />
  </div>
)

// MARK: - Пустое состояние

export const EmptyState = ({ icon: Icon, title, message }: { icon: LucideIcon; title: string; message: string }) => (
  <div className="flex flex-col items-center gap-2 px-6 py-10 text-center">
    <Icon size={40} strokeWidth={1.4} className="text-accent" />
    <div className="font-semibold">{title}</div>
    <div className="text-sm text-text-2">{message}</div>
  </div>
)

// MARK: - Кнопки

export const PrimaryButton = ({ children, disabled, onClick, type = 'button' }: {
  children: ReactNode; disabled?: boolean; onClick?: () => void; type?: 'button' | 'submit'
}) => (
  <button
    type={type}
    disabled={disabled}
    onClick={onClick}
    className={cx(
      'h-14 w-full rounded-card font-semibold transition active:scale-[0.98]',
      disabled
        ? 'bg-elevated text-text-3'
        : 'bg-linear-to-br from-accent to-accent-deep text-black shadow-[0_6px_16px_rgb(0_212_170/0.35)]',
    )}
  >
    {children}
  </button>
)

export const DangerButton = ({ children, onClick }: { children: ReactNode; onClick: () => void }) => (
  <button
    type="button"
    onClick={onClick}
    className="flex h-12 w-full items-center justify-center gap-2 rounded-card bg-danger/12 font-semibold text-danger transition active:scale-[0.98]"
  >
    {children}
  </button>
)

// MARK: - Форма

/** Строка формы: подпись слева, значение справа, отдельная скруглённая плашка */
export const FieldRow = ({ label, children }: { label: string; children: ReactNode }) => (
  <label className="flex min-h-13 items-center gap-3 rounded-small border border-stroke bg-card px-4">
    <span className="shrink-0 text-sm text-text-2">{label}</span>
    <span className="flex min-w-0 flex-1 items-center justify-end gap-2">{children}</span>
  </label>
)

export const FieldInput = (props: ComponentProps<'input'>) => (
  <input {...props} className={cx('min-w-0 flex-1 text-right', props.className)} />
)

export const FieldLabel = ({ children }: { children: ReactNode }) => (
  <div className="px-1 pt-1.5 text-xs text-text-3">{children}</div>
)

export const TextArea = (props: ComponentProps<'textarea'>) => (
  <textarea
    rows={3}
    {...props}
    className="w-full resize-none rounded-small border border-stroke bg-card p-3.5"
  />
)
