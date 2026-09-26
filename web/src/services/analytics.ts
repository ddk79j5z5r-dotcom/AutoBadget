// Чистые функции расчёта статистики — порт AnalyticsService.swift

import { EXPENSE_CATEGORIES, pricePerLiter, type Expense, type ExpenseCategory, type FuelType } from '@/models/types'
import { addMonths, sameMonth, startOfMonth, yearOf } from './formatters'

export interface MonthTotal { month: number; total: number }
export interface CategoryTotal { category: ExpenseCategory; total: number; share: number }
export interface YearTotal { year: number; total: number }

export interface FuelFill {
  expense: Expense
  liters: number
  /** Пробег с предыдущей заправки, км */
  distance?: number
  /** Расход на этом отрезке, л/100 км */
  consumption?: number
  pricePerLiter: number
}

export interface FuelTypeStats {
  type: FuelType
  fillsCount: number
  liters: number
  averagePricePerLiter?: number
  consumption?: number
}

export interface FuelStats {
  consumption?: number
  averagePricePerLiter?: number
  costPer100Km?: number
  fillsCount: number
  lastFill?: Expense
  byType: FuelTypeStats[]
  pricePoints: { date: number; price: number; type: FuelType }[]
}

const sum = <T>(items: T[], f: (x: T) => number) => items.reduce((acc, x) => acc + f(x), 0)

export const total = (expenses: Expense[]) => sum(expenses, e => e.amount)

export const totalInMonth = (expenses: Expense[], date: number) =>
  total(expenses.filter(e => sameMonth(e.date, date)))

/** Средние траты в месяц с момента первой записи */
export const averagePerMonth = (expenses: Expense[], now = Date.now()) => {
  if (!expenses.length) return 0
  const first = Math.min(...expenses.map(e => e.date))
  const a = new Date(startOfMonth(first)), b = new Date(startOfMonth(now))
  const months = (b.getFullYear() - a.getFullYear()) * 12 + (b.getMonth() - a.getMonth()) + 1
  return total(expenses) / Math.max(months, 1)
}

/** Суммы за последние `count` месяцев, пустые месяцы = 0 */
export const monthly = (expenses: Expense[], count: number, now = Date.now()): MonthTotal[] => {
  const current = startOfMonth(now)
  const buckets = new Map<number, number>()
  for (const e of expenses) {
    const m = startOfMonth(e.date)
    buckets.set(m, (buckets.get(m) ?? 0) + e.amount)
  }
  return Array.from({ length: count }, (_, i) => {
    const month = addMonths(current, -(count - 1 - i))
    return { month, total: buckets.get(month) ?? 0 }
  })
}

export const byCategory = (expenses: Expense[], includeEmpty = false): CategoryTotal[] => {
  const all = total(expenses)
  return EXPENSE_CATEGORIES
    .map(category => {
      const t = total(expenses.filter(e => e.category === category))
      return { category, total: t, share: all > 0 ? t / all : 0 }
    })
    .filter(c => includeEmpty || c.total > 0)
    .sort((a, b) => b.total - a.total)
}

export const byYear = (expenses: Expense[]): YearTotal[] => {
  const buckets = new Map<number, number>()
  for (const e of expenses) buckets.set(yearOf(e.date), (buckets.get(yearOf(e.date)) ?? 0) + e.amount)
  return [...buckets].map(([year, t]) => ({ year, total: t })).sort((a, b) => a.year - b.year)
}

/** Средний расход, л/100 км — метод «полного бака»: литры первой заправки не учитываются */
export const averageFuelConsumption = (expenses: Expense[]) => {
  const fills = expenses
    .filter(e => e.category === 'fuel' && (e.liters ?? 0) > 0 && e.mileage > 0)
    .sort((a, b) => a.mileage - b.mileage)
  if (fills.length < 2) return undefined
  const distance = fills[fills.length - 1].mileage - fills[0].mileage
  if (distance <= 0) return undefined
  return (sum(fills.slice(1), e => e.liters ?? 0) / distance) * 100
}

/** Заправки с расходом на каждом отрезке (по возрастанию пробега) */
export const fuelFills = (expenses: Expense[]): FuelFill[] => {
  const fills = expenses
    .filter(e => e.category === 'fuel' && (e.liters ?? 0) > 0)
    .sort((a, b) => a.mileage - b.mileage || a.date - b.date)
  let previousKm: number | undefined
  return fills.map(e => {
    const liters = e.liters ?? 0
    const distance = previousKm !== undefined && e.mileage > previousKm ? e.mileage - previousKm : undefined
    if (e.mileage > 0) previousKm = e.mileage
    return {
      expense: e,
      liters,
      distance,
      consumption: distance ? (liters / distance) * 100 : undefined,
      pricePerLiter: pricePerLiter(e) ?? 0,
    }
  })
}

export const fuelSpentPerLiter = (expenses: Expense[]) => {
  const fills = expenses.filter(e => e.category === 'fuel' && (e.liters ?? 0) > 0)
  const liters = sum(fills, e => e.liters ?? 0)
  return liters > 0 ? total(fills) / liters : undefined
}

/** Сводная статистика по заправкам */
export const fuelStats = (expenses: Expense[]): FuelStats => {
  const fills = fuelFills(expenses)
  if (!fills.length) return { fillsCount: 0, byType: [], pricePoints: [] }
  const segments = fills.filter(f => f.distance !== undefined)
  const segmentKm = sum(segments, f => f.distance ?? 0)
  const segmentCost = sum(segments, f => f.expense.amount)

  const groups = new Map<FuelType, FuelFill[]>()
  for (const f of fills) {
    const type = f.expense.fuelType ?? 'other'
    groups.set(type, [...(groups.get(type) ?? []), f])
  }
  const byType: FuelTypeStats[] = [...groups].map(([type, items]) => {
    const liters = sum(items, f => f.liters)
    const cost = sum(items, f => f.expense.amount)
    const typeSegments = items.filter(f => f.distance !== undefined)
    const typeKm = sum(typeSegments, f => f.distance ?? 0)
    return {
      type,
      fillsCount: items.length,
      liters,
      averagePricePerLiter: liters > 0 ? cost / liters : undefined,
      consumption: typeKm > 0 ? (sum(typeSegments, f => f.liters) / typeKm) * 100 : undefined,
    }
  }).sort((a, b) => b.fillsCount - a.fillsCount)

  const byDate = [...fills].sort((a, b) => a.expense.date - b.expense.date)
  return {
    consumption: averageFuelConsumption(expenses),
    averagePricePerLiter: fuelSpentPerLiter(expenses),
    costPer100Km: segmentKm > 0 ? (segmentCost / segmentKm) * 100 : undefined,
    fillsCount: fills.length,
    lastFill: byDate[byDate.length - 1]?.expense,
    byType,
    pricePoints: byDate.map(f => ({ date: f.expense.date, price: f.pricePerLiter, type: f.expense.fuelType ?? 'other' })),
  }
}

/** Пробег за период по записям с указанным пробегом */
export const distance = (expenses: Expense[]) => {
  const m = expenses.map(e => e.mileage).filter(v => v > 0)
  if (!m.length) return undefined
  const d = Math.max(...m) - Math.min(...m)
  return d > 0 ? d : undefined
}

export const costPerKm = (expenses: Expense[]) => {
  const d = distance(expenses)
  return d ? total(expenses) / d : undefined
}

/** Средний пробег в день за последний год — для прогноза обслуживания */
export const averageDailyKm = (expenses: Expense[], now = Date.now()) => {
  const yearAgo = addMonths(now, -12)
  const points = expenses.filter(e => e.mileage > 0 && e.date >= yearAgo).sort((a, b) => a.date - b.date)
  if (points.length < 2) return undefined
  const first = points[0], last = points[points.length - 1]
  const spanDays = (last.date - first.date) / 86_400_000
  const kmDelta = last.mileage - first.mileage
  return spanDays >= 30 && kmDelta > 0 ? kmDelta / spanDays : undefined
}
