import { X } from 'lucide-react'
import { useEffect, useRef, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'

/**
 * Bottom Sheet на телефоне и диалог по центру на широком экране.
 * Закрывается крестиком, Escape или тапом по фону; закрытие анимировано.
 */
export const Sheet = ({ title, onClose, children, footer }: {
  title: string
  onClose: () => void
  children: ReactNode
  footer?: ReactNode
}) => {
  const [closing, setClosing] = useState(false)
  const panelRef = useRef<HTMLDivElement>(null)

  const close = () => {
    setClosing(true)
    window.setTimeout(onClose, 200)
  }

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && close()
    document.addEventListener('keydown', onKey)
    const overflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    panelRef.current?.focus()
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = overflow
    }
    // Подписка один раз на время жизни шторки
  }, [])

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-end justify-center lg:items-center" role="dialog" aria-modal="true" aria-label={title}>
      <div
        className={`absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity duration-200 ${closing ? 'opacity-0' : 'animate-fade-in'}`}
        onClick={close}
      />
      <div
        ref={panelRef}
        tabIndex={-1}
        className={`relative flex max-h-[94dvh] w-full flex-col rounded-t-[32px] border border-stroke bg-bg outline-none transition duration-200
          lg:max-h-[88vh] lg:max-w-lg lg:rounded-[28px]
          ${closing ? 'translate-y-full opacity-0 lg:translate-y-4' : 'animate-sheet-in lg:animate-appear'}`}
      >
        <div className="mx-auto mt-2 h-1.5 w-10 shrink-0 rounded-full bg-white/20 lg:hidden" />
        <div className="flex shrink-0 items-center justify-between px-5 pb-2 pt-4">
          <h2 className="text-2xl font-bold">{title}</h2>
          <button
            type="button"
            onClick={close}
            aria-label="Закрыть"
            className="flex size-8 items-center justify-center rounded-full bg-elevated text-text-2 transition hover:text-text"
          >
            <X size={16} strokeWidth={2.8} />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto overscroll-contain px-5 pb-6">{children}</div>
        {footer && <div className="pb-safe shrink-0 px-5 pb-3 pt-2.5">{footer}</div>}
      </div>
    </div>,
    document.body,
  )
}

/** Подтверждение опасного действия */
export const ConfirmDialog = ({ title, message, confirmTitle = 'Удалить', onConfirm, onCancel }: {
  title: string; message?: string; confirmTitle?: string; onConfirm: () => void; onCancel: () => void
}) =>
  createPortal(
    <div className="fixed inset-0 z-[60] flex items-center justify-center p-6" role="alertdialog" aria-modal="true">
      <div className="animate-fade-in absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onCancel} />
      <div className="animate-appear relative w-full max-w-sm rounded-[24px] border border-stroke bg-elevated p-5 text-center">
        <div className="text-lg font-bold">{title}</div>
        {message && <div className="mt-1.5 text-sm text-text-2">{message}</div>}
        <div className="mt-5 flex gap-2.5">
          <button type="button" onClick={onCancel} className="h-11 flex-1 rounded-small bg-field font-semibold">Отмена</button>
          <button type="button" onClick={onConfirm} className="h-11 flex-1 rounded-small bg-danger font-semibold text-white">
            {confirmTitle}
          </button>
        </div>
      </div>
    </div>,
    document.body,
  )
