import { ArrowRight, Gauge, List, CircleDollarSign } from 'lucide-react'
import { useMemo, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { Page, PageHeader } from '@/components/AppShell'
import { repairIcon } from '@/components/icons'
import { Appear, Card, StatTile } from '@/components/ui'
import { repairCategoryInfo, repairTotal } from '@/models/types'
import { dateDayMonth, km, rub } from '@/services/formatters'
import { useCar, useRepairs } from '@/viewmodels/useData'
import { timeline } from '@/viewmodels/viewModels'

/** Общая временная шкала эксплуатации автомобиля */
export const TimelinePage = () => {
  const repairs = useRepairs()
  const car = useCar()
  const years = useMemo(() => timeline(repairs), [repairs])
  const total = years.reduce((s, y) => s + y.total, 0)

  return (
    <>
      <PageHeader title="История автомобиля" back="/garage/repairs" />
      <Page className="max-w-3xl">
        <div className="grid grid-cols-2 gap-2.5">
          <StatTile title="Записей" value={String(repairs.length)} icon={List} />
          <StatTile title="Сумма" value={rub(total)} icon={CircleDollarSign} />
        </div>

        {/* Краткая лента по годам: 2024 → …, 2025 → … */}
        <div className="no-scrollbar -mx-4 flex items-center gap-2 overflow-x-auto px-4">
          {[...years].reverse().map((y, i, all) => {
            const main = [...y.repairs].sort((a, b) => repairTotal(b) - repairTotal(a))[0]
            return (
              <div key={y.year} className="flex shrink-0 items-center gap-2">
                <div className="rounded-small bg-card px-3.5 py-2.5">
                  <div className="font-semibold text-accent">{y.year}</div>
                  <div className="max-w-44 truncate text-xs text-text-2">{main?.title}</div>
                </div>
                {i < all.length - 1 && <ArrowRight size={14} className="text-text-3" />}
              </div>
            )
          })}
        </div>

        <div>
          {car && (
            <Node color="var(--color-accent)" first>
              <div className="flex items-center gap-2 pb-5 text-sm font-semibold text-accent">
                <Gauge size={16} /> Сегодня · {km(car.mileage)}
              </div>
            </Node>
          )}
          {years.map(y => (
            <div key={y.year}>
              <Node color="#fff" big>
                <div className="flex items-baseline justify-between pb-3">
                  <span className="font-rounded text-3xl font-bold">{y.year}</span>
                  <span className="text-sm font-semibold text-text-2">{rub(y.total)}</span>
                </div>
              </Node>
              {y.repairs.map((r, i) => {
                const Icon = repairIcon[r.category]
                const { color, title } = repairCategoryInfo[r.category]
                return (
                  <Node key={r.id} color={color}>
                    <Appear delay={i * 0.04} className="pb-3.5">
                      <Link to={`/garage/repairs/${r.id}`} className="block transition active:scale-[0.99]">
                        <Card padding="p-3.5" className="space-y-2 hover:bg-elevated">
                          <div className="flex justify-between text-xs">
                            <span className="font-semibold" style={{ color }}>{dateDayMonth(r.date)}</span>
                            <span className="text-text-3">{km(r.mileage)}</span>
                          </div>
                          <div className="font-semibold">{r.title}</div>
                          <div className="flex items-center justify-between text-xs text-text-2">
                            <span className="flex items-center gap-1.5"><Icon size={13} /> {title}</span>
                            <span className="font-rounded text-sm font-bold text-text">{rub(repairTotal(r))}</span>
                          </div>
                        </Card>
                      </Link>
                    </Appear>
                  </Node>
                )
              })}
            </div>
          ))}
          {car && (
            <Node color="var(--color-text-3)" last>
              <div className="font-rounded text-lg font-bold text-text-2">{car.year}</div>
              <div className="text-sm text-text-3">Выпуск автомобиля · {car.make} {car.model} {car.bodyCode}</div>
            </Node>
          )}
        </div>
      </Page>
    </>
  )
}

const Node = ({ color, children, first, last, big }: {
  color: string; children: ReactNode; first?: boolean; last?: boolean; big?: boolean
}) => (
  <div className="flex gap-3.5">
    <div className="relative flex w-5 shrink-0 justify-center">
      <div
        className="absolute w-0.5 bg-linear-to-b from-accent/50 to-stroke"
        style={{ top: first ? 10 : 0, bottom: last ? 'auto' : 0, height: last ? 10 : undefined }}
      />
      <div
        className="relative mt-1.5 rounded-full border-[3px] border-bg"
        style={{ width: big ? 16 : 14, height: big ? 16 : 14, background: color, boxShadow: `0 0 8px ${color}` }}
      />
    </div>
    <div className="min-w-0 flex-1">{children}</div>
  </div>
)
