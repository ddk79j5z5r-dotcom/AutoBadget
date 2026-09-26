// Графики на Recharts — стиль повторяет Swift Charts из iOS-версии

import {
  Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from 'recharts'
import { expenseCategoryInfo, fuelTypeInfo, type ExpenseCategory, type FuelType } from '@/models/types'
import type { CategoryTotal, FuelFill, MonthTotal, YearTotal } from '@/services/analytics'
import { dateShort, monthAbbr, monthLetter, monthName, oneDecimal, rub, rubShort, sameMonth } from '@/services/formatters'

const AXIS = { fill: 'var(--color-text-3)', fontSize: 11 }
const GRID = 'rgb(255 255 255 / 0.07)'

const TooltipBox = ({ title, value }: { title: string; value: string }) => (
  <div className="rounded-[10px] bg-elevated px-2.5 py-1.5 text-center shadow-lg">
    <div className="text-[11px] text-text-2">{title}</div>
    <div className="text-xs font-bold">{value}</div>
  </div>
)

/** Расходы по месяцам; текущий месяц подсвечен */
export const MonthlyBarChart = ({ data, height = 190 }: { data: MonthTotal[]; height?: number }) => (
  <ResponsiveContainer width="100%" height={height}>
    <BarChart data={data} margin={{ top: 8, right: 0, left: -8, bottom: 0 }}>
      <defs>
        <linearGradient id="bar-current" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#00D4AA" />
          <stop offset="1" stopColor="#00A887" stopOpacity={0.6} />
        </linearGradient>
        <linearGradient id="bar-regular" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#00D4AA" stopOpacity={0.55} />
          <stop offset="1" stopColor="#00D4AA" stopOpacity={0.15} />
        </linearGradient>
      </defs>
      <CartesianGrid vertical={false} stroke={GRID} strokeDasharray="3 3" />
      <XAxis
        dataKey="month"
        tickFormatter={(m: number) => (data.length > 12 ? monthAbbr(m) : monthLetter(m))}
        tick={AXIS} axisLine={false} tickLine={false}
        interval={data.length > 12 ? Math.ceil(data.length / 8) : 0}
      />
      <YAxis tickFormatter={rubShort} tick={AXIS} axisLine={false} tickLine={false} width={52} />
      <Tooltip
        cursor={{ fill: 'rgb(255 255 255 / 0.04)' }}
        content={({ active, payload }) =>
          active && payload?.[0] ? (
            <TooltipBox title={monthName(payload[0].payload.month)} value={rub(payload[0].payload.total)} />
          ) : null
        }
      />
      <Bar dataKey="total" radius={[6, 6, 0, 0]} animationDuration={600}>
        {data.map(d => (
          <Cell key={d.month} fill={sameMonth(d.month, Date.now()) ? 'url(#bar-current)' : 'url(#bar-regular)'} />
        ))}
      </Bar>
    </BarChart>
  </ResponsiveContainer>
)

/** Мини-столбики в карточке «Всего потрачено» */
export const SparkBars = ({ data }: { data: MonthTotal[] }) => {
  const max = Math.max(...data.map(d => d.total), 1)
  return (
    <div className="flex h-14 w-24 items-end gap-1.5" aria-hidden>
      {data.map((d, i) => (
        <div
          key={d.month}
          className="flex-1 rounded-[2px] transition-[height] duration-500"
          style={{
            height: `${Math.max(4, (56 * d.total) / max)}px`,
            background: `linear-gradient(180deg, rgb(0 212 170 / ${i === data.length - 1 ? 1 : 0.55}), rgb(0 212 170 / 0.15))`,
          }}
        />
      ))}
    </div>
  )
}

/** Кольцевая диаграмма расходов по категориям */
export const CategoryDonut = ({ data, selected, onSelect, centerTitle, centerValue }: {
  data: CategoryTotal[]
  selected?: ExpenseCategory
  onSelect: (c?: ExpenseCategory) => void
  centerTitle: string
  centerValue: string
}) => (
  <div className="relative size-[150px] shrink-0">
    <ResponsiveContainer width="100%" height="100%">
      <PieChart>
        <Pie
          data={data}
          dataKey="total"
          nameKey="category"
          innerRadius="72%"
          outerRadius="100%"
          paddingAngle={2}
          cornerRadius={4}
          stroke="none"
          animationDuration={700}
          onClick={(_, i) => onSelect(data[i].category === selected ? undefined : data[i].category)}
        >
          {data.map(d => (
            <Cell
              key={d.category}
              fill={expenseCategoryInfo[d.category].color}
              opacity={!selected || selected === d.category ? 1 : 0.3}
              className="cursor-pointer outline-none"
            />
          ))}
        </Pie>
      </PieChart>
    </ResponsiveContainer>
    <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center px-5 text-center">
      <div className="font-rounded w-full truncate text-sm font-bold">{centerValue}</div>
      <div className="w-full truncate text-[11px] text-text-2">{centerTitle}</div>
    </div>
  </div>
)

/** Горизонтальные столбики по категориям */
export const CategoryBarChart = ({ data }: { data: CategoryTotal[] }) => (
  <ResponsiveContainer width="100%" height={Math.max(160, data.length * 34)}>
    <BarChart data={data} layout="vertical" margin={{ top: 0, right: 56, left: 0, bottom: 0 }}>
      <XAxis type="number" hide />
      <YAxis
        type="category" dataKey="category" width={104} axisLine={false} tickLine={false}
        tick={{ fill: 'var(--color-text-2)', fontSize: 12 }}
        tickFormatter={(c: ExpenseCategory) => expenseCategoryInfo[c].title}
      />
      <Bar
        dataKey="total" radius={6} barSize={18} animationDuration={600}
        label={{ position: 'right', fill: 'var(--color-text-2)', fontSize: 11, formatter: (v: unknown) => rubShort(Number(v)) }}
      >
        {data.map(d => <Cell key={d.category} fill={expenseCategoryInfo[d.category].color} />)}
      </Bar>
    </BarChart>
  </ResponsiveContainer>
)

export const YearBarChart = ({ data }: { data: YearTotal[] }) => (
  <ResponsiveContainer width="100%" height={230}>
    <BarChart data={data} margin={{ top: 20, right: 0, left: -8, bottom: 0 }}>
      <CartesianGrid vertical={false} stroke={GRID} strokeDasharray="3 3" />
      <XAxis dataKey="year" tick={{ fill: 'var(--color-text-2)', fontSize: 12 }} axisLine={false} tickLine={false} />
      <YAxis tickFormatter={rubShort} tick={AXIS} axisLine={false} tickLine={false} width={52} />
      <Bar
        dataKey="total" radius={[8, 8, 0, 0]} maxBarSize={56} fill="url(#bar-year)" animationDuration={600}
        label={{ position: 'top', fill: 'var(--color-text-2)', fontSize: 11, formatter: (v: unknown) => rubShort(Number(v)) }}
      />
      <defs>
        <linearGradient id="bar-year" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#00D4AA" />
          <stop offset="1" stopColor="#00D4AA" stopOpacity={0.25} />
        </linearGradient>
      </defs>
    </BarChart>
  </ResponsiveContainer>
)

/** Мини-график расхода по заправкам */
export const ConsumptionSparkline = ({ data }: { data: FuelFill[] }) => (
  <div className="h-16 w-36 shrink-0">
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={data.map(f => ({ date: f.expense.date, value: f.consumption }))}>
        <YAxis hide domain={['dataMin', 'dataMax']} />
        <Line type="monotone" dataKey="value" stroke="#00D4AA" strokeWidth={2.5} dot={false} animationDuration={700} />
      </LineChart>
    </ResponsiveContainer>
  </div>
)

/** Изменение цены топлива — отдельная линия для каждого типа */
export const FuelPriceChart = ({ points, types }: {
  points: { date: number; price: number; type: FuelType }[]
  types: FuelType[]
}) => {
  const rows = points.map(p => ({ date: p.date, [p.type]: p.price }))
  return (
    <ResponsiveContainer width="100%" height={200}>
      <LineChart data={rows} margin={{ top: 8, right: 8, left: -8, bottom: 0 }}>
        <CartesianGrid vertical={false} stroke={GRID} strokeDasharray="3 3" />
        <XAxis
          dataKey="date" type="number" scale="time" domain={['dataMin', 'dataMax']}
          tickFormatter={(d: number) => monthAbbr(d)} tick={AXIS} axisLine={false} tickLine={false} tickCount={5}
        />
        <YAxis domain={['dataMin - 2', 'dataMax + 2']} tickFormatter={(v: number) => `${Math.round(v)} ₽`}
          tick={AXIS} axisLine={false} tickLine={false} width={52} />
        <Tooltip
          content={({ active, payload }) => {
            const p = payload?.[0]
            if (!active || !p) return null
            const type = p.dataKey as FuelType
            return <TooltipBox title={`${fuelTypeInfo[type].title} · ${dateShort(p.payload.date)}`} value={`${oneDecimal(Number(p.value))} ₽/л`} />
          }}
        />
        <Legend
          iconType="circle" iconSize={8} align="left"
          formatter={(t: string) => <span className="text-xs text-text-2">{fuelTypeInfo[t as FuelType].title}</span>}
        />
        {types.map(type => (
          <Line
            key={type} dataKey={type} type="monotone" connectNulls stroke={fuelTypeInfo[type].color}
            strokeWidth={2} dot={{ r: 2.5, fill: fuelTypeInfo[type].color, strokeWidth: 0 }} animationDuration={700}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  )
}

/** Литры по месяцам — экран «Заправки» */
export const LitersChart = ({ data }: { data: { month: number; liters: number }[] }) => (
  <ResponsiveContainer width="100%" height={150}>
    <BarChart data={data} margin={{ top: 4, right: 0, left: 0, bottom: 0 }}>
      <defs>
        <linearGradient id="bar-fuel" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#2FC86B" />
          <stop offset="1" stopColor="#2FC86B" stopOpacity={0.25} />
        </linearGradient>
      </defs>
      <XAxis dataKey="month" tickFormatter={(m: number) => monthAbbr(m)} tick={AXIS} axisLine={false} tickLine={false} />
      <Tooltip
        cursor={{ fill: 'rgb(255 255 255 / 0.04)' }}
        content={({ active, payload }) =>
          active && payload?.[0] ? <TooltipBox title={monthName(payload[0].payload.month)} value={`${Math.round(payload[0].payload.liters)} л`} /> : null
        }
      />
      <Bar dataKey="liters" radius={[5, 5, 0, 0]} fill="url(#bar-fuel)" maxBarSize={64} animationDuration={600} />
    </BarChart>
  </ResponsiveContainer>
)
