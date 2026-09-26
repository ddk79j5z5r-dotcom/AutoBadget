import { CarFront, ChartColumn, House, List, Plus, type LucideIcon } from 'lucide-react'
import { Suspense, useState, type ReactNode } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { AddExpenseSheet } from '@/sheets/AddExpenseSheet'
import { useCar } from '@/viewmodels/useData'
import { cx } from './ui'

const TABS: { to: string; title: string; icon: LucideIcon; end?: boolean }[] = [
  { to: '/', title: 'Главная', icon: House, end: true },
  { to: '/expenses', title: 'Расходы', icon: List },
  { to: '/stats', title: 'Статистика', icon: ChartColumn },
  { to: '/garage', title: 'Гараж', icon: CarFront },
]

/**
 * Каркас приложения: на телефоне — нижняя панель с «+» по центру (как в iOS),
 * на широком экране — боковое меню.
 */
export const AppShell = () => {
  const [adding, setAdding] = useState(false)
  const car = useCar()

  return (
    <div className="screen-glow min-h-dvh lg:flex">
      {/* Боковое меню — десктоп */}
      <aside className="sticky top-0 hidden h-dvh w-64 shrink-0 flex-col gap-1 border-r border-stroke px-4 py-6 lg:flex">
        <div className="mb-6 flex items-center gap-3 px-2">
          <img src={`${import.meta.env.BASE_URL}icon.png`} alt="" className="size-10 rounded-[10px]" />
          <div>
            <div className="font-bold">AutoBudget</div>
            <div className="text-xs text-text-3">{car ? `${car.make} ${car.model}` : ' '}</div>
          </div>
        </div>
        {TABS.map(tab => (
          <NavLink key={tab.to} to={tab.to} end={tab.end}>
            {({ isActive }) => (
              <SideItem icon={tab.icon} active={isActive}>{tab.title}</SideItem>
            )}
          </NavLink>
        ))}
        <button
          type="button"
          onClick={() => setAdding(true)}
          className="mt-6 flex h-12 items-center justify-center gap-2 rounded-card bg-linear-to-br from-accent to-accent-deep font-semibold text-black shadow-[0_6px_16px_rgb(0_212_170/0.3)] transition active:scale-[0.98]"
        >
          <Plus size={20} strokeWidth={2.5} /> Добавить расход
        </button>
      </aside>

      <main className="min-w-0 flex-1 pb-28 lg:pb-10">
        <Suspense fallback={null}>
          <Outlet />
        </Suspense>
      </main>

      {/* Нижняя панель — телефон и планшет */}
      <nav className="pb-safe fixed inset-x-0 bottom-0 z-40 border-t border-stroke bg-black/85 backdrop-blur-xl lg:hidden">
        <div className="mx-auto flex max-w-xl items-center px-2 pt-2">
          {TABS.slice(0, 2).map(tab => <TabItem key={tab.to} {...tab} />)}
          <div className="flex flex-1 justify-center">
            <button
              type="button"
              onClick={() => setAdding(true)}
              aria-label="Добавить расход"
              className="flex size-12 items-center justify-center rounded-full border border-white/15 bg-elevated shadow-[0_3px_8px_rgb(0_0_0/0.5)] transition active:scale-95"
            >
              <Plus size={22} />
            </button>
          </div>
          {TABS.slice(2).map(tab => <TabItem key={tab.to} {...tab} />)}
        </div>
      </nav>

      {adding && <AddExpenseSheet currentMileage={car?.mileage ?? 0} onClose={() => setAdding(false)} />}
    </div>
  )
}

const TabItem = ({ to, title, icon: Icon, end }: { to: string; title: string; icon: LucideIcon; end?: boolean }) => (
  <NavLink to={to} end={end} className="flex-1">
    {({ isActive }) => (
      <span className={cx('flex h-12 flex-col items-center justify-center gap-1 transition', isActive ? 'text-accent' : 'text-text-3')}>
        <Icon size={20} strokeWidth={isActive ? 2.4 : 2} />
        <span className="text-[10px] font-medium">{title}</span>
      </span>
    )}
  </NavLink>
)

const SideItem = ({ icon: Icon, active, children }: { icon: LucideIcon; active: boolean; children: ReactNode }) => (
  <span
    className={cx(
      'flex h-11 items-center gap-3 rounded-small px-3 font-medium transition',
      active ? 'bg-accent/12 text-accent' : 'text-text-2 hover:bg-card hover:text-text',
    )}
  >
    <Icon size={19} strokeWidth={active ? 2.4 : 2} />
    {children}
  </span>
)

/**
 * Заголовок экрана: крупный на главных вкладках, компактный с кнопкой «назад» на вложенных.
 * back — куда вернуться, если экран открыт по прямой ссылке и истории нет.
 */
export const PageHeader = ({ title, back, actions }: { title: string; back?: string; actions?: ReactNode }) => (
  <header className={cx('pt-safe flex items-center gap-3 px-4 lg:px-8', back ? 'pb-2 pt-4' : 'pb-4 pt-8')}>
    {back && <BackButton fallback={back} />}
    <h1 className={cx('min-w-0 flex-1 truncate font-bold', back ? 'text-xl' : 'text-[34px] leading-tight')}>{title}</h1>
    {actions}
  </header>
)

const BackButton = ({ fallback }: { fallback: string }) => {
  const navigate = useNavigate()
  // react-router хранит номер записи в истории: 0 — экран открыт первым
  const canGoBack = ((window.history.state as { idx?: number } | null)?.idx ?? 0) > 0
  return (
  <button
    type="button"
    onClick={() => (canGoBack ? navigate(-1) : navigate(fallback))}
    aria-label="Назад"
    className="flex size-10 shrink-0 items-center justify-center rounded-full border border-stroke bg-card text-text transition hover:bg-elevated"
  >
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="m15 18-6-6 6-6" />
    </svg>
  </button>
  )
}

/** Контейнер содержимого экрана */
export const Page = ({ children, className }: { children: ReactNode; className?: string }) => (
  <div className={cx('mx-auto w-full max-w-5xl space-y-5 px-4 lg:px-8', className)}>{children}</div>
)

export const IconButton = ({ icon: Icon, label, onClick }: { icon: LucideIcon; label: string; onClick: () => void }) => (
  <button
    type="button"
    onClick={onClick}
    aria-label={label}
    title={label}
    className="flex size-10 shrink-0 items-center justify-center rounded-full border border-stroke bg-card text-accent transition hover:bg-elevated"
  >
    <Icon size={19} strokeWidth={2.3} />
  </button>
)
