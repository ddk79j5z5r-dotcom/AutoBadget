import { ArrowDown, ArrowUp, ChevronDown, Gauge, Inbox } from 'lucide-react'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Page } from '@/components/AppShell'
import { MonthlyBarChart, SparkBars } from '@/components/charts'
import { CarImage, ExpenseRow, UpcomingServiceRow } from '@/components/rows'
import { AllLink, Appear, Card, CategoryIcon, Divider, EmptyState, SectionHeader, cx } from '@/components/ui'
import { expenseCategoryInfo, type Expense } from '@/models/types'
import { km, rub } from '@/services/formatters'
import { AddExpenseSheet } from '@/sheets/AddExpenseSheet'
import { useDashboardViewModel } from '@/viewmodels/viewModels'

export const DashboardPage = () => {
  const vm = useDashboardViewModel()
  const [editing, setEditing] = useState<Expense>()

  return (
    <Page className="pt-safe pt-6 lg:pt-10">
      {vm.car && (
        <Appear>
          <Link to="/garage" className="flex items-center gap-2 transition active:scale-[0.99]">
            <div className="min-w-0 flex-1 space-y-1.5">
              <div className="flex items-center gap-1.5">
                <h1 className="font-rounded truncate text-2xl font-bold lg:text-3xl">{vm.car.make} {vm.car.model}</h1>
                <ChevronDown size={16} strokeWidth={2.8} className="shrink-0 text-text-2" />
              </div>
              <div className="text-sm text-text-2">
                {[vm.car.bodyCode, vm.car.engine, vm.car.year].filter(Boolean).join(' · ')}
              </div>
              <span className="inline-flex items-center gap-1.5 rounded-full bg-accent/12 px-2.5 py-1 text-xs font-semibold text-accent">
                <Gauge size={14} /> {km(vm.car.mileage)}
              </span>
            </div>
            <CarImage photo={vm.car.photo} className="h-20 w-36 rounded-small lg:h-28 lg:w-52" />
          </Link>
        </Appear>
      )}

      <div className="grid grid-cols-1 gap-5 lg:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)]">
        <div className="space-y-5">
          <Appear delay={0.05}>
            <Card padding="p-5" className="space-y-4">
              <div className="flex items-end gap-3">
                <div className="min-w-0 flex-1">
                  <div className="text-sm text-text-2">Всего потрачено</div>
                  <div className="font-rounded truncate text-[32px] font-bold leading-tight">{rub(vm.total)}</div>
                  <div className="text-xs text-text-3">за всё время</div>
                </div>
                <SparkBars data={vm.sparkline} />
              </div>
              <div className="grid grid-cols-2 gap-2.5">
                <Metric title="В этом месяце" value={rub(vm.thisMonth)} delta={vm.deltaVsLastMonth} />
                <Metric title="Ср. / мес за год" value={rub(vm.averagePerMonth)} />
              </div>
            </Card>
          </Appear>

          <Appear delay={0.1}>
            <div className="grid grid-cols-4 gap-2">
              {vm.categories.map(item => (
                <Link
                  key={item.category}
                  to={item.category === 'fuel' ? '/fuel' : `/expenses/${item.category}`}
                  className="flex flex-col items-center gap-1.5 rounded-2xl border border-stroke bg-card px-1 py-3 transition hover:bg-elevated active:scale-95"
                >
                  <CategoryIcon category={item.category} size={34} />
                  <span className="w-full truncate text-center text-[10px] font-medium text-text-2 sm:text-[11px]">
                    {expenseCategoryInfo[item.category].title}
                  </span>
                  <span className="font-rounded w-full truncate text-center text-xs font-bold">{rub(item.total)}</span>
                  <span className="text-[10px] font-semibold text-text-3">{Math.round(item.share * 100)}%</span>
                </Link>
              ))}
            </div>
          </Appear>

          <Appear delay={0.15}>
            <Card className="space-y-1">
              <SectionHeader title="Последние расходы" action={<Link to="/expenses"><AllLink /></Link>} />
              {vm.recent.length === 0 && <EmptyState icon={Inbox} title="Пока пусто" message="Добавьте первый расход кнопкой «+»" />}
              {vm.recent.map((e, i) => (
                <div key={e.id}>
                  <button type="button" className="w-full text-left" onClick={() => setEditing(e)}>
                    <ExpenseRow expense={e} />
                  </button>
                  {i < vm.recent.length - 1 && <Divider inset={52} />}
                </div>
              ))}
            </Card>
          </Appear>
        </div>

        <div className="space-y-5">
          <Appear delay={0.2}>
            <Card className="space-y-3">
              <SectionHeader title="Расходы по месяцам" />
              <MonthlyBarChart data={vm.monthly} />
            </Card>
          </Appear>

          {vm.upcoming.length > 0 && (
            <Appear delay={0.25}>
              <Card className="space-y-4">
                <SectionHeader title="Скоро потребуется обслуживание" action={<Link to="/garage/parts"><AllLink /></Link>} />
                {vm.upcoming.map(item => (
                  <Link
                    key={item.tracked.key}
                    to={item.tracked.source.type === 'part' ? `/garage/parts/${item.tracked.source.part.id}` : '/garage/reminders'}
                    className="block transition active:scale-[0.99]"
                  >
                    <UpcomingServiceRow item={item} />
                  </Link>
                ))}
              </Card>
            </Appear>
          )}
        </div>
      </div>

      {editing && <AddExpenseSheet expense={editing} onClose={() => setEditing(undefined)} />}
    </Page>
  )
}

const Metric = ({ title, value, delta }: { title: string; value: string; delta?: number }) => (
  <div className="rounded-small bg-elevated p-3">
    <div className="truncate text-xs text-text-2">{title}</div>
    <div className="flex items-baseline gap-1.5">
      <span className="font-rounded truncate font-semibold">{value}</span>
      {delta !== undefined && (
        // Для расходов рост — плохо (оранжевый), снижение — хорошо (акцент)
        <span className={cx('inline-flex items-center text-[11px] font-bold', delta > 0 ? 'text-warning' : 'text-accent')}>
          {delta > 0 ? <ArrowUp size={11} strokeWidth={3} /> : <ArrowDown size={11} strokeWidth={3} />}
          {Math.round(Math.abs(delta))}%
        </span>
      )}
    </div>
  </div>
)
