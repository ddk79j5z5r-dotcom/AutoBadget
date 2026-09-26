import { BellRing } from 'lucide-react'
import { useEffect, useState } from 'react'
import { permission, requestPermission, type Permission } from '@/services/notifications'
import { Card, SymbolBadge, cx } from './ui'

/** Сегментный переключатель в стиле референса: активный сегмент — «пилюля» */
export const Segmented = <T extends string>({ value, options, onChange }: {
  value: T
  /** short — подпись для узких экранов */
  options: { value: T; title: string; short?: string }[]
  onChange: (v: T) => void
}) => (
  <div className="flex gap-1 rounded-full border border-stroke bg-card p-1" role="tablist">
    {options.map(o => (
      <button
        key={o.value}
        type="button"
        role="tab"
        aria-selected={o.value === value}
        onClick={() => onChange(o.value)}
        className={cx(
          'h-8 flex-1 truncate rounded-full px-2 text-[13px] font-semibold transition',
          o.value === value ? 'border border-white/10 bg-elevated text-text' : 'text-text-2 hover:text-text',
        )}
      >
        {o.short ? (
          <>
            <span className="sm:hidden">{o.short}</span>
            <span className="hidden sm:inline">{o.title}</span>
          </>
        ) : o.title}
      </button>
    ))}
  </div>
)

/** Просьба включить уведомления — на экранах «Напоминания» и «Детали» */
export const NotificationBanner = ({ message }: { message: string }) => {
  const [state, setState] = useState<Permission>(permission())

  useEffect(() => {
    const refresh = () => setState(permission())
    document.addEventListener('visibilitychange', refresh)
    return () => document.removeEventListener('visibilitychange', refresh)
  }, [])

  if (state === 'granted' || state === 'unsupported') return null
  const denied = state === 'denied'
  return (
    <Card className="flex items-center gap-3.5">
      <SymbolBadge icon={BellRing} color="var(--color-warning)" />
      <div className="min-w-0 flex-1">
        <div className="font-semibold">Включите уведомления</div>
        <div className="text-xs text-text-2">
          {denied ? 'Уведомления запрещены. Разрешите их в настройках сайта в браузере.' : message}
        </div>
      </div>
      {!denied && (
        <button
          type="button"
          onClick={async () => setState(await requestPermission())}
          className="shrink-0 rounded-full bg-accent px-3.5 py-2 text-sm font-bold text-black"
        >
          Включить
        </button>
      )}
    </Card>
  )
}
