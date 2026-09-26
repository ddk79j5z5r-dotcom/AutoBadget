// ViewModels экранов: производные данные и состояние фильтров. Порт ViewModels iOS-версии.

import { useMemo, useState } from 'react'
import { progress, status, trackPart, type ServiceStatus } from '@/models/serviceTracking'
import {
  EXPENSE_CATEGORIES, REPAIR_CATEGORIES, repairTotal, type Expense, type ExpenseCategory, type Part, type RepairCategory, type RepairRecord,
} from '@/models/types'
import * as A from '@/services/analytics'
import { addMonths, startOfMonth, yearOf } from '@/services/formatters'
import { upcoming } from '@/services/maintenance'
import { filterByPeriod, previousPeriod, type StatsPeriod } from './period'
import { useActiveParts, useCar, useExpenses, useReminders, useRepairs } from './useData'

// MARK: - Главная

export const useDashboardViewModel = () => {
  const car = useCar()
  const expenses = useExpenses()
  const reminders = useReminders()
  const parts = useActiveParts()

  return useMemo(() => {
    const now = Date.now()
    const thisMonth = A.totalInMonth(expenses, now)
    const lastMonth = A.totalInMonth(expenses, addMonths(now, -1))
    return {
      car,
      expenses,
      total: A.total(expenses),
      thisMonth,
      deltaVsLastMonth: lastMonth > 0 ? ((thisMonth - lastMonth) / lastMonth) * 100 : undefined,
      // Среднее за последний год: давние редкие записи не должны «размазывать» показатель
      averagePerMonth: A.averagePerMonth(filterByPeriod(expenses, 'twelveMonths', now), now),
      // Все 8 категорий в фиксированном порядке — для сетки плиток
      categories: [...A.byCategory(expenses, true)].sort(
        (a, b) => EXPENSE_CATEGORIES.indexOf(a.category) - EXPENSE_CATEGORIES.indexOf(b.category),
      ),
      monthly: A.monthly(expenses, 12, now),
      sparkline: A.monthly(expenses, 8, now),
      recent: expenses.slice(0, 5),
      upcoming: car ? upcoming(reminders, parts, car.mileage, A.averageDailyKm(expenses), 5) : [],
    }
  }, [car, expenses, reminders, parts])
}

// MARK: - Расходы

export type ExpenseSort = 'date' | 'amount'

export interface ExpenseMonthGroup { month: number; items: Expense[]; total: number }

export const useExpensesViewModel = (initialCategory?: ExpenseCategory) => {
  const expenses = useExpenses()
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState<ExpenseCategory | undefined>(initialCategory)
  const [sort, setSort] = useState<ExpenseSort>('date')

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return expenses
      .filter(e => !category || e.category === category)
      .filter(e => !q || [e.title, e.place, e.comment].some(s => s.toLowerCase().includes(q)))
      .sort((a, b) => (sort === 'date' ? b.date - a.date : b.amount - a.amount))
  }, [expenses, search, category, sort])

  const groups = useMemo<ExpenseMonthGroup[]>(() => {
    if (sort !== 'date') return []
    const map = new Map<number, Expense[]>()
    for (const e of filtered) map.set(startOfMonth(e.date), [...(map.get(startOfMonth(e.date)) ?? []), e])
    return [...map].map(([month, items]) => ({ month, items, total: A.total(items) }))
  }, [filtered, sort])

  return { search, setSearch, category, setCategory, sort, setSort, filtered, groups, total: A.total(filtered) }
}

// MARK: - Статистика

export type StatsChart = 'months' | 'categories' | 'years'

export const useStatisticsViewModel = () => {
  const expenses = useExpenses()
  const [period, setPeriod] = useState<StatsPeriod>('threeMonths')
  const [chart, setChart] = useState<StatsChart>('months')
  const [selectedCategory, setSelectedCategory] = useState<ExpenseCategory>()

  const data = useMemo(() => {
    const items = filterByPeriod(expenses, period)
    const prev = previousPeriod(expenses, period)
    const current = A.averageFuelConsumption(items)
    const before = prev ? A.averageFuelConsumption(prev) : undefined
    const months = period === 'allTime'
      ? (() => {
          const first = items.length ? Math.min(...items.map(e => e.date)) : Date.now()
          const a = new Date(first), b = new Date()
          return (b.getFullYear() - a.getFullYear()) * 12 + b.getMonth() - a.getMonth() + 1
        })()
      : { threeMonths: 3, sixMonths: 6, twelveMonths: 12 }[period]
    return {
      total: A.total(items),
      count: items.length,
      averagePerMonth: A.averagePerMonth(items),
      costPerKm: A.costPerKm(items),
      distance: A.distance(items),
      categories: A.byCategory(items),
      monthly: A.monthly(items, Math.max(months, 1)),
      // По годам всегда показываем всю историю
      yearly: A.byYear(expenses),
      fuel: A.fuelStats(items),
      fuelSeries: A.fuelFills(items).filter(f => f.consumption !== undefined),
      fuelTrend: current !== undefined && before ? ((current - before) / before) * 100 : undefined,
    }
  }, [expenses, period])

  return { period, setPeriod, chart, setChart, selectedCategory, setSelectedCategory, ...data }
}

// MARK: - Ремонты

export const repairStats = (repairs: RepairRecord[]) => {
  const total = repairs.reduce((s, r) => s + repairTotal(r), 0)
  return {
    total,
    count: repairs.length,
    average: repairs.length ? total / repairs.length : 0,
    mostExpensive: [...repairs].sort((a, b) => repairTotal(b) - repairTotal(a))[0],
    last: [...repairs].sort((a, b) => b.date - a.date)[0],
  }
}

export const filterRepairs = (repairs: RepairRecord[], category: RepairCategory | undefined, search: string) => {
  const q = search.trim().toLowerCase()
  return repairs
    .filter(r => !category || r.category === category)
    .filter(r => !q || [r.title, r.worksDone, r.partsUsed, r.shop].some(s => s.toLowerCase().includes(q)))
}

/** Общая временная шкала: годы по убыванию, внутри — по дате */
export const timeline = (repairs: RepairRecord[]) => {
  const map = new Map<number, RepairRecord[]>()
  for (const r of repairs) map.set(yearOf(r.date), [...(map.get(yearOf(r.date)) ?? []), r])
  return [...map]
    .map(([year, items]) => ({
      year,
      repairs: items.sort((a, b) => b.date - a.date),
      total: items.reduce((s, r) => s + repairTotal(r), 0),
    }))
    .sort((a, b) => b.year - a.year)
}

// MARK: - Детали

export interface PartGroup { category: RepairCategory; parts: Part[] }

export const groupParts = (parts: Part[], mileage: number, search: string): PartGroup[] => {
  const q = search.trim().toLowerCase()
  const active = parts.filter(p => p.isActive === 1 && (!q ||
    [p.name, p.manufacturer, p.articleNumber].some(s => s.toLowerCase().includes(q))))
  return REPAIR_CATEGORIES
    .map(category => ({
      category,
      parts: active
        .filter(p => p.category === category)
        .sort((a, b) => progress(trackPart(b), mileage) - progress(trackPart(a), mileage)),
    }))
    .filter(g => g.parts.length > 0)
}

export const partsSummary = (parts: Part[], mileage: number) => {
  const statuses: ServiceStatus[] = parts.filter(p => p.isActive === 1).map(p => status(trackPart(p), mileage))
  return {
    total: statuses.length,
    replaceNow: statuses.filter(s => s === 'overdue').length,
    attention: statuses.filter(s => s === 'warning' || s === 'critical').length,
  }
}

// MARK: - Гараж

export const useGarageViewModel = () => {
  const car = useCar()
  const repairs = useRepairs()
  const reminders = useReminders()
  const parts = useActiveParts()
  const expenses = useExpenses()

  return useMemo(() => {
    const items = car ? upcoming(reminders, parts, car.mileage, A.averageDailyKm(expenses), Infinity) : []
    return {
      car,
      lastService: repairs.find(r => r.category === 'service'),
      // Ближайшее плановое ТО: деталь категории «Плановое ТО» или напоминание о масле/фильтрах
      nextService: items.find(i =>
        i.tracked.source.type === 'part'
          ? i.tracked.source.part.category === 'service'
          : ['oil', 'filters'].includes(i.tracked.source.reminder.kind)),
      lastRepair: repairs.find(r => r.category !== 'service'),
      nearestWorks: items.slice(0, 3),
      serviceHistory: repairs.filter(r => r.category === 'service'),
    }
  }, [car, repairs, reminders, parts, expenses])
}
