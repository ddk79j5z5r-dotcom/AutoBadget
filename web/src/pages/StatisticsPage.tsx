import { ArrowDown, ArrowUp, CalendarDays, CircleDollarSign, Clock, Fuel, Gauge, PieChart as PieIcon, Route } from 'lucide-react'
import { Link } from 'react-router-dom'
import { Page, PageHeader } from '@/components/AppShell'
import {
  CategoryBarChart, CategoryDonut, ConsumptionSparkline, FuelPriceChart, MonthlyBarChart, YearBarChart,
} from '@/components/charts'
import { Segmented } from '@/components/controls'
import { AllLink, Appear, Card, CategoryIcon, EmptyState, ProgressBar, SectionHeader, StatTile } from '@/components/ui'
import { expenseCategoryInfo, fuelTypeInfo } from '@/models/types'
import { dateCompact, km, oneDecimal, plural, rub } from '@/services/formatters'
import { periodInfo, type StatsPeriod } from '@/viewmodels/period'
import { useStatisticsViewModel, type StatsChart } from '@/viewmodels/viewModels'

export const StatisticsPage = () => {
  const vm = useStatisticsViewModel()
  const selected = vm.categories.find(c => c.category === vm.selectedCategory)

  return (
    <>
      <PageHeader title="Статистика" />
      <Page>
        <Segmented
          value={vm.period}
          onChange={vm.setPeriod}
          options={(Object.keys(periodInfo) as StatsPeriod[]).map(p => ({ value: p, title: periodInfo[p].title, short: periodInfo[p].short }))}
        />

        <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
          <div className="space-y-5">
            {/* Кольцевая диаграмма с легендой */}
            <Appear>
              <Card padding="p-5" className="flex items-center gap-5">
                <CategoryDonut
                  data={vm.categories}
                  selected={vm.selectedCategory}
                  onSelect={vm.setSelectedCategory}
                  centerValue={rub(selected?.total ?? vm.total)}
                  centerTitle={selected ? expenseCategoryInfo[selected.category].title : 'Всего'}
                />
                <div className="min-w-0 flex-1 space-y-2">
                  {vm.categories.length === 0 && <div className="text-xs text-text-2">Нет расходов за период</div>}
                  {vm.categories.slice(0, 6).map(c => (
                    <button
                      key={c.category}
                      type="button"
                      onClick={() => vm.setSelectedCategory(vm.selectedCategory === c.category ? undefined : c.category)}
                      className="flex w-full items-center gap-2 text-xs font-medium"
                    >
                      <span className="size-2 shrink-0 rounded-full" style={{ background: expenseCategoryInfo[c.category].color }} />
                      <span className={`truncate ${vm.selectedCategory === c.category ? 'text-text' : 'text-text-2'}`}>
                        {expenseCategoryInfo[c.category].title}
                      </span>
                      <span className="ml-auto text-text-3">{Math.round(c.share * 100)}%</span>
                    </button>
                  ))}
                </div>
              </Card>
            </Appear>

            <Appear delay={0.05}>
              <Card className="space-y-3.5">
                <SectionHeader title="Расходы по категориям" />
                {vm.categories.length === 0 && (
                  <EmptyState icon={PieIcon} title="Нет данных" message="За выбранный период расходов нет" />
                )}
                {vm.categories.map(c => (
                  <div key={c.category} className="flex items-center gap-3">
                    <CategoryIcon category={c.category} size={32} />
                    <div className="min-w-0 flex-1 space-y-1.5">
                      <div className="flex items-baseline gap-2 text-sm">
                        <span className="truncate font-medium">{expenseCategoryInfo[c.category].title}</span>
                        <span className="font-rounded ml-auto font-semibold">{rub(c.total)}</span>
                        <span className="w-9 text-right text-xs font-semibold text-text-3">{Math.round(c.share * 100)}%</span>
                      </div>
                      <ProgressBar value={c.share} color={expenseCategoryInfo[c.category].color} height={4} />
                    </div>
                  </div>
                ))}
              </Card>
            </Appear>

            <Appear delay={0.1}>
              <div className="grid grid-cols-2 gap-2.5">
                <StatTile title="Общие расходы" value={rub(vm.total)} icon={CircleDollarSign}
                  footnote={`${vm.count} ${plural(vm.count, 'операция', 'операции', 'операций')}`} />
                <StatTile title="В среднем в месяц" value={rub(vm.averagePerMonth)} icon={CalendarDays}
                  tint={expenseCategoryInfo.maintenance.color} />
                <StatTile title="Стоимость 1 км" value={vm.costPerKm !== undefined ? `${oneDecimal(vm.costPerKm)} ₽` : '—'}
                  icon={Route} tint={expenseCategoryInfo.tires.color} footnote="Все расходы / пробег" />
                <StatTile title="Пробег за период" value={vm.distance !== undefined ? km(vm.distance) : '—'}
                  icon={Gauge} tint={expenseCategoryInfo.insurance.color} footnote="По записям с пробегом" />
              </div>
            </Appear>
          </div>

          <div className="space-y-5">
            <FuelSection vm={vm} />
            <Appear delay={0.2}>
              <Card className="space-y-4">
                <SectionHeader title="Графики" />
                <Segmented<StatsChart>
                  value={vm.chart}
                  onChange={vm.setChart}
                  options={[
                    { value: 'months', title: 'По месяцам' },
                    { value: 'categories', title: 'По категориям' },
                    { value: 'years', title: 'По годам' },
                  ]}
                />
                {vm.chart === 'months' && <MonthlyBarChart data={vm.monthly} height={230} />}
                {vm.chart === 'categories' && <CategoryBarChart data={vm.categories} />}
                {vm.chart === 'years' && <YearBarChart data={vm.yearly} />}
              </Card>
            </Appear>
          </div>
        </div>
      </Page>
    </>
  )
}

/** Аналитика топлива: расход, цена литра, стоимость 100 км, типы топлива, график цены */
const FuelSection = ({ vm }: { vm: ReturnType<typeof useStatisticsViewModel> }) => {
  const f = vm.fuel
  return (
    <Appear delay={0.15} className="space-y-3">
      <SectionHeader title="Топливо" action={<Link to="/fuel"><AllLink /></Link>} />
      <Card padding="p-5" className="flex items-end gap-3">
        <div className="min-w-0 flex-1 space-y-1">
          <div className="text-xs text-text-2">Средний расход топлива</div>
          <div className="flex items-baseline gap-1">
            <span className="font-rounded text-[28px] font-bold leading-none">{f.consumption !== undefined ? oneDecimal(f.consumption) : '—'}</span>
            <span className="text-xs font-semibold text-text-2">л/100 км</span>
          </div>
          {vm.fuelTrend !== undefined && (
            <div className={`flex items-center gap-0.5 text-[11px] font-bold ${vm.fuelTrend > 0 ? 'text-warning' : 'text-accent'}`}>
              {vm.fuelTrend > 0 ? <ArrowUp size={11} strokeWidth={3} /> : <ArrowDown size={11} strokeWidth={3} />}
              {oneDecimal(Math.abs(vm.fuelTrend))}% к прошлому периоду
            </div>
          )}
        </div>
        {vm.fuelSeries.length > 1 && <ConsumptionSparkline data={vm.fuelSeries} />}
      </Card>

      <div className="grid grid-cols-2 gap-2.5">
        <StatTile title="Средняя цена литра" value={f.averagePricePerLiter !== undefined ? `${oneDecimal(f.averagePricePerLiter)} ₽` : '—'}
          icon={CircleDollarSign} tint={expenseCategoryInfo.fuel.color} />
        <StatTile title="Стоимость 100 км" value={f.costPer100Km !== undefined ? rub(f.costPer100Km) : '—'}
          icon={Route} tint={expenseCategoryInfo.tires.color} />
        <StatTile title="Заправок" value={String(f.fillsCount)} icon={Fuel} tint={expenseCategoryInfo.maintenance.color} />
        <StatTile
          title="Последняя заправка"
          value={f.lastFill ? rub(f.lastFill.amount) : '—'}
          icon={Clock}
          tint={expenseCategoryInfo.taxes.color}
          footnote={f.lastFill ? [dateCompact(f.lastFill.date), f.lastFill.liters ? `${Math.round(f.lastFill.liters)} л` : null,
            f.lastFill.fuelType ? fuelTypeInfo[f.lastFill.fuelType].title : null].filter(Boolean).join(' · ') : undefined}
        />
      </div>

      {f.byType.length > 0 && (
        <Card className="space-y-3">
          <div className="text-sm font-semibold text-text-2">Расход по типу топлива</div>
          {f.byType.map(t => (
            <div key={t.type} className="flex items-center gap-3">
              <span className="size-2.5 rounded-full" style={{ background: fuelTypeInfo[t.type].color }} />
              <div className="min-w-0 flex-1">
                <div className="text-sm font-semibold">{fuelTypeInfo[t.type].title}</div>
                <div className="text-xs text-text-3">
                  {t.fillsCount} {plural(t.fillsCount, 'заправка', 'заправки', 'заправок')} · {Math.round(t.liters)} л
                </div>
              </div>
              <div className="text-right">
                <div className="font-rounded text-sm font-semibold">{t.consumption !== undefined ? `${oneDecimal(t.consumption)} л/100` : '—'}</div>
                <div className="text-xs text-text-3">{t.averagePricePerLiter !== undefined ? `${oneDecimal(t.averagePricePerLiter)} ₽/л` : ''}</div>
              </div>
            </div>
          ))}
        </Card>
      )}

      {f.pricePoints.length >= 2 && (
        <Card className="space-y-3">
          <div className="text-sm font-semibold text-text-2">Изменение цены топлива</div>
          <FuelPriceChart points={f.pricePoints} types={f.byType.map(t => t.type)} />
        </Card>
      )}
    </Appear>
  )
}
