import type { Expense } from '@/models/types'
import { addMonths, startOfMonth } from '@/services/formatters'

export type StatsPeriod = 'threeMonths' | 'sixMonths' | 'twelveMonths' | 'allTime'

export const periodInfo: Record<StatsPeriod, { title: string; short: string; months?: number }> = {
  threeMonths: { title: '3 месяца', short: '3 мес.', months: 3 },
  sixMonths: { title: '6 месяцев', short: '6 мес.', months: 6 },
  twelveMonths: { title: '12 месяцев', short: '12 мес.', months: 12 },
  allTime: { title: 'Всё время', short: 'Всё' },
}

/** Начало периода — первое число месяца; undefined — вся история */
export const periodStart = (p: StatsPeriod, now = Date.now()) => {
  const m = periodInfo[p].months
  return m ? addMonths(startOfMonth(now), -(m - 1)) : undefined
}

export const filterByPeriod = (expenses: Expense[], p: StatsPeriod, now = Date.now()) => {
  const start = periodStart(p, now)
  return start === undefined ? expenses : expenses.filter(e => e.date >= start)
}

/** Такой же по длине предыдущий период — для сравнения «↑/↓ %» */
export const previousPeriod = (expenses: Expense[], p: StatsPeriod, now = Date.now()) => {
  const m = periodInfo[p].months
  const start = periodStart(p, now)
  if (!m || start === undefined) return undefined
  const prevStart = addMonths(start, -m)
  return expenses.filter(e => e.date >= prevStart && e.date < start)
}
