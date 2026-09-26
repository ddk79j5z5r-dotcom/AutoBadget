import { Building2, ChevronRight, ClockArrowUp, Image, Plus, Waypoints, Wrench } from 'lucide-react'
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { IconButton, Page, PageHeader } from '@/components/AppShell'
import { RepairBadge } from '@/components/rows'
import { Appear, Card, ChipBar, Divider, EmptyState, FilterChip, SearchField, StatusPill, SymbolBadge } from '@/components/ui'
import { REPAIR_CATEGORIES, repairCategoryInfo, repairTotal, type RepairCategory, type RepairRecord } from '@/models/types'
import { dateShort, km, plural, rub } from '@/services/formatters'
import { AddRepairSheet } from '@/sheets/AddRepairSheet'
import { useCar, useRepairs } from '@/viewmodels/useData'
import { filterRepairs, repairStats } from '@/viewmodels/viewModels'

export const RepairsPage = () => {
  const repairs = useRepairs()
  const car = useCar()
  const [category, setCategory] = useState<RepairCategory>()
  const [search, setSearch] = useState('')
  const [adding, setAdding] = useState(false)
  const stats = useMemo(() => repairStats(repairs), [repairs])
  const items = useMemo(() => filterRepairs(repairs, category, search), [repairs, category, search])

  return (
    <>
      <PageHeader title="Ремонт и ТО" back="/garage" actions={<IconButton icon={Plus} label="Добавить ремонт" onClick={() => setAdding(true)} />} />
      <Page>
        <Appear>
          <Card padding="p-5" className="space-y-4">
            <div className="flex items-start">
              <div className="min-w-0 flex-1">
                <div className="text-sm text-text-2">Все ремонты</div>
                <div className="font-rounded truncate text-[32px] font-bold leading-tight">{rub(stats.total)}</div>
              </div>
              <div className="text-right">
                <div className="font-rounded text-3xl font-bold text-accent">{stats.count}</div>
                <div className="text-xs text-text-2">{plural(stats.count, 'ремонт', 'ремонта', 'ремонтов')}</div>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-2.5">
              <Mini title="Средняя стоимость" value={rub(stats.average)} />
              <Mini title="Самая дорогая" value={stats.mostExpensive ? rub(repairTotal(stats.mostExpensive)) : '—'} detail={stats.mostExpensive?.title} />
            </div>
            {stats.last && (
              <div className="flex items-center gap-2.5 rounded-small bg-elevated p-3">
                <ClockArrowUp size={18} className="shrink-0 text-accent" />
                <div className="min-w-0 flex-1">
                  <div className="text-xs text-text-2">Последний ремонт</div>
                  <div className="truncate text-sm font-semibold">{stats.last.title} · {dateShort(stats.last.date)}</div>
                </div>
                <span className="text-sm font-semibold">{rub(repairTotal(stats.last))}</span>
              </div>
            )}
          </Card>
        </Appear>

        <Link to="/garage/timeline" className="block">
          <Card className="flex items-center gap-3.5 transition hover:bg-elevated">
            <SymbolBadge icon={Waypoints} color="var(--color-accent)" />
            <div className="min-w-0 flex-1">
              <div className="font-semibold">История автомобиля</div>
              <div className="text-xs text-text-2">Все ремонты на временной шкале</div>
            </div>
            <ChevronRight size={18} className="text-text-3" />
          </Card>
        </Link>

        <SearchField value={search} onChange={setSearch} placeholder="Поиск по работам и запчастям" />
        <ChipBar>
          <FilterChip title="Все" selected={!category} onClick={() => setCategory(undefined)} />
          {REPAIR_CATEGORIES.map(c => (
            <FilterChip key={c} title={repairCategoryInfo[c].title} selected={category === c}
              onClick={() => setCategory(category === c ? undefined : c)} />
          ))}
        </ChipBar>

        {items.length === 0 && <EmptyState icon={Wrench} title="Нет записей" message="Добавьте ремонт кнопкой «+»" />}
        <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
          {items.map(r => <RepairCard key={r.id} repair={r} />)}
        </div>
      </Page>
      {adding && <AddRepairSheet currentMileage={car?.mileage} onClose={() => setAdding(false)} />}
    </>
  )
}

const Mini = ({ title, value, detail }: { title: string; value: string; detail?: string }) => (
  <div className="rounded-small bg-elevated p-3">
    <div className="text-xs text-text-2">{title}</div>
    <div className="font-rounded truncate font-semibold">{value}</div>
    <div className="truncate text-[11px] text-text-3">{detail ?? ' '}</div>
  </div>
)

export const RepairCard = ({ repair }: { repair: RepairRecord }) => (
  <Link to={`/garage/repairs/${repair.id}`} className="block transition active:scale-[0.99]">
    <Card className="h-full space-y-3.5 hover:bg-elevated">
      <div className="flex items-start gap-3">
        <RepairBadge category={repair.category} />
        <div className="min-w-0 flex-1">
          <div className="font-semibold">{repair.title}</div>
          <div className="text-xs text-text-2">{dateShort(repair.date)} · Пробег: {km(repair.mileage)}</div>
        </div>
        <StatusPill text={repairCategoryInfo[repair.category].title} color={repairCategoryInfo[repair.category].color} />
      </div>
      <div className="space-y-1.5 text-sm text-text-2">
        <div className="flex justify-between"><span>Работы</span><span>{rub(repair.laborCost)}</span></div>
        <div className="flex justify-between"><span>Запчасти</span><span>{rub(repair.partsCost)}</span></div>
        <Divider />
        <div className="flex justify-between text-text">
          <span className="font-semibold">Итого</span>
          <span className="font-rounded font-bold text-accent">{rub(repairTotal(repair))}</span>
        </div>
      </div>
      {(repair.shop || repair.photoBefore || repair.photoAfter) && (
        <div className="flex items-center gap-1.5 text-xs text-text-3">
          {repair.shop && <><Building2 size={13} /><span className="truncate">{repair.shop}</span></>}
          {(repair.photoBefore || repair.photoAfter) && <Image size={14} className="ml-auto" />}
        </div>
      )}
    </Card>
  </Link>
)
