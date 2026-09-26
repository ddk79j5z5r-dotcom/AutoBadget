import { Fuel } from 'lucide-react'
import { useMemo, useState } from 'react'
import { Page, PageHeader } from '@/components/AppShell'
import { LitersChart } from '@/components/charts'
import { Segmented } from '@/components/controls'
import { Card, CategoryIcon, Divider, EmptyState, SectionHeader } from '@/components/ui'
import { fuelTypeInfo, type Expense } from '@/models/types'
import { fuelFills, fuelSpentPerLiter, averageFuelConsumption, type FuelFill } from '@/services/analytics'
import { addMonths, dateShort, grouped, km, oneDecimal, rub, sameMonth, startOfMonth } from '@/services/formatters'
import { AddExpenseSheet } from '@/sheets/AddExpenseSheet'
import { filterByPeriod, periodInfo, type StatsPeriod } from '@/viewmodels/period'
import { useExpenses } from '@/viewmodels/useData'

/** Экран «Заправки»: литры, средний расход, график и история заправок */
export const FuelPage = () => {
  const expenses = useExpenses()
  const [period, setPeriod] = useState<StatsPeriod>('threeMonths')
  const [editing, setEditing] = useState<Expense>()

  const data = useMemo(() => {
    const items = filterByPeriod(expenses, period)
    const fills = fuelFills(items)
    const months = periodInfo[period].months ?? 12
    const now = Date.now()
    return {
      liters: fills.reduce((s, f) => s + f.liters, 0),
      consumption: averageFuelConsumption(items),
      price: fuelSpentPerLiter(items),
      chart: Array.from({ length: months }, (_, i) => {
        const month = addMonths(startOfMonth(now), -(months - 1 - i))
        return { month, liters: fills.filter(f => sameMonth(f.expense.date, month)).reduce((s, f) => s + f.liters, 0) }
      }),
      history: fuelFills(expenses).reverse().slice(0, 30),
    }
  }, [expenses, period])

  return (
    <>
      <PageHeader title="Заправки" back="/" />
      <Page>
        <Segmented
          value={period}
          onChange={setPeriod}
          options={(['threeMonths', 'sixMonths', 'twelveMonths'] as StatsPeriod[]).map(p => ({ value: p, title: periodInfo[p].title, short: periodInfo[p].short }))}
        />
        <Card padding="p-5" className="space-y-4">
          <div className="flex">
            <Summary title="Общий расход топлива" value={grouped(data.liters)} unit="л" footnote={`за ${periodInfo[period].title.toLowerCase()}`} />
            <div className="mx-4 w-px bg-stroke" />
            <Summary
              title="Средний расход"
              value={data.consumption !== undefined ? oneDecimal(data.consumption) : '—'}
              unit="л/100 км"
              footnote={data.price !== undefined ? `${oneDecimal(data.price)} ₽ за литр` : ' '}
            />
          </div>
          <LitersChart data={data.chart} />
        </Card>

        <Card className="space-y-1">
          <SectionHeader title="Последние заправки" />
          {data.history.length === 0 && (
            <EmptyState icon={Fuel} title="Нет заправок" message="Добавьте расход «Топливо» с объёмом в литрах" />
          )}
          {data.history.map((f, i) => (
            <div key={f.expense.id}>
              <button type="button" className="w-full text-left" onClick={() => setEditing(f.expense)}>
                <FuelRow fill={f} />
              </button>
              {i < data.history.length - 1 && <Divider inset={52} />}
            </div>
          ))}
        </Card>
      </Page>
      {editing && <AddExpenseSheet expense={editing} onClose={() => setEditing(undefined)} />}
    </>
  )
}

const Summary = ({ title, value, unit, footnote }: { title: string; value: string; unit: string; footnote: string }) => (
  <div className="min-w-0 flex-1 space-y-1">
    <div className="truncate text-xs text-text-2">{title}</div>
    <div className="flex items-baseline gap-1">
      <span className="font-rounded text-[28px] font-bold leading-none">{value}</span>
      <span className="text-xs font-semibold text-text-2">{unit}</span>
    </div>
    <div className="text-[11px] text-text-3">{footnote}</div>
  </div>
)

/** «45 л · 95 · 62,4 ₽/л · Лукойл» */
const FuelRow = ({ fill }: { fill: FuelFill }) => {
  const details = [`${Math.round(fill.liters)} л`]
  if (fill.expense.fuelType) details.push(fuelTypeInfo[fill.expense.fuelType].short)
  details.push(`${oneDecimal(fill.pricePerLiter)} ₽/л`)
  if (fill.expense.place) details.push(fill.expense.place)
  return (
    <div className="flex items-center gap-3 py-1.5">
      <CategoryIcon category="fuel" />
      <div className="min-w-0 flex-1">
        <div className="text-sm font-semibold">{dateShort(fill.expense.date)} · {rub(fill.expense.amount)}</div>
        <div className="truncate text-xs text-text-3">{details.join(' · ')}</div>
      </div>
      <div className="shrink-0 text-right">
        <div className="font-rounded text-sm font-semibold">{fill.distance ? km(fill.distance) : '—'}</div>
        {fill.consumption !== undefined && <div className="text-[11px] text-text-3">{oneDecimal(fill.consumption)} л/100</div>}
      </div>
    </div>
  )
}
