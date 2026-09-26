import { Package } from 'lucide-react'
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Page, PageHeader } from '@/components/AppShell'
import { NotificationBanner } from '@/components/controls'
import { repairIcon } from '@/components/icons'
import { PartRow } from '@/components/rows'
import { Card, Divider, EmptyState, SearchField } from '@/components/ui'
import { statusInfo } from '@/models/serviceTracking'
import { repairCategoryInfo } from '@/models/types'
import { useActiveParts, useCar } from '@/viewmodels/useData'
import { groupParts, partsSummary } from '@/viewmodels/viewModels'

/** Все установленные детали по категориям с остатком ресурса */
export const PartsPage = () => {
  const parts = useActiveParts()
  const mileage = useCar()?.mileage ?? 0
  const [search, setSearch] = useState('')
  const groups = useMemo(() => groupParts(parts, mileage, search), [parts, mileage, search])
  const summary = useMemo(() => partsSummary(parts, mileage), [parts, mileage])

  return (
    <>
      <PageHeader title="Детали и ресурс" back="/garage" />
      <Page>
        <NotificationBanner message="Предупредим, когда ресурс деталей подойдёт к концу." />
        <div className="grid grid-cols-3 gap-2.5">
          <Tile value={summary.replaceNow} title="Замена" color={statusInfo.overdue.color} />
          <Tile value={summary.attention} title="Скоро" color={statusInfo.warning.color} />
          <Tile value={summary.total} title="На учёте" color="var(--color-accent)" />
        </div>
        <SearchField value={search} onChange={setSearch} placeholder="Название, производитель, артикул" />

        {groups.length === 0 && (
          <EmptyState
            icon={Package}
            title={search ? 'Ничего не найдено' : 'Нет деталей'}
            message="Детали добавляются в записи ремонта: «Гараж» → «Ремонт и обслуживание» → «Заменённые детали»."
          />
        )}

        <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
          {groups.map(g => {
            const Icon = repairIcon[g.category]
            return (
              <section key={g.category} className="space-y-2.5">
                <h2 className="flex items-center gap-2 text-lg font-bold">
                  <Icon size={20} /> {repairCategoryInfo[g.category].title}
                </h2>
                <Card padding="px-4 py-1">
                  {g.parts.map((p, i) => (
                    <div key={p.id}>
                      <Link to={`/garage/parts/${p.id}`} className="block transition hover:opacity-85">
                        <PartRow part={p} mileage={mileage} />
                      </Link>
                      {i < g.parts.length - 1 && <Divider />}
                    </div>
                  ))}
                </Card>
              </section>
            )
          })}
        </div>
      </Page>
    </>
  )
}

const Tile = ({ value, title, color }: { value: number; title: string; color: string }) => (
  <Card padding="p-3" className="text-center">
    <div className="font-rounded text-2xl font-bold" style={{ color }}>{value}</div>
    <div className="text-xs text-text-2">{title}</div>
  </Card>
)
