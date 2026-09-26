// Общая логика ресурса: интервал по пробегу и/или по времени от точки отсчёта.
// Используется и для напоминаний (регламент, документы), и для установленных деталей.

import { addMonths, capitalizedFirst, dateShort, days, daysBetween, km, resource } from '@/services/formatters'
import type { Part, Reminder } from './types'

export type ServiceStatus = 'ok' | 'warning' | 'critical' | 'overdue'

const statusRank: Record<ServiceStatus, number> = { ok: 0, warning: 1, critical: 2, overdue: 3 }
export const compareStatus = (a: ServiceStatus, b: ServiceStatus) => statusRank[a] - statusRank[b]

export const statusInfo: Record<ServiceStatus, { title: string; color: string }> = {
  ok: { title: 'В норме', color: 'var(--color-accent)' },
  warning: { title: 'Скоро', color: 'var(--color-warning)' },
  critical: { title: 'Срочно', color: 'var(--color-critical)' },
  overdue: { title: 'Просрочено', color: 'var(--color-danger)' },
}

export const WARNING_DAYS = 30
export const CRITICAL_DAYS = 7

export type TrackedSource = { type: 'reminder'; reminder: Reminder } | { type: 'part'; part: Part }

/** Единое представление напоминания или детали для расчёта ресурса */
export interface Tracked {
  source: TrackedSource
  /** Стабильный ключ — для уведомлений и списков */
  key: string
  title: string
  baseMileage: number
  baseDate: number
  lifeKm: number
  lifeMonths: number
  notifyDaysBefore: number
  notificationsActive: boolean
  overdueTitle: string
}

export const trackReminder = (reminder: Reminder): Tracked => ({
  source: { type: 'reminder', reminder },
  key: `reminder-${reminder.id}`,
  title: reminder.title,
  baseMileage: reminder.lastMileage,
  baseDate: reminder.lastDate,
  lifeKm: reminder.intervalKm,
  lifeMonths: reminder.intervalMonths,
  notifyDaysBefore: reminder.notifyDaysBefore,
  notificationsActive: reminder.notificationsEnabled,
  overdueTitle: 'Просрочено',
})

export const trackPart = (part: Part): Tracked => ({
  source: { type: 'part', part },
  key: `part-${part.id}`,
  title: part.name,
  baseMileage: part.installMileage,
  baseDate: part.installDate,
  lifeKm: part.serviceLifeKm,
  lifeMonths: part.serviceLifeMonths,
  // Для деталей предупреждаем за месяц до окончания срока службы
  notifyDaysBefore: 30,
  notificationsActive: part.isActive === 1,
  overdueTitle: 'Требуется замена',
})

export const nextMileage = (t: Tracked) => (t.lifeKm > 0 ? t.baseMileage + t.lifeKm : undefined)
export const nextDate = (t: Tracked) => (t.lifeMonths > 0 ? addMonths(t.baseDate, t.lifeMonths) : undefined)

/** Порог «Скоро»: 5 000 км, но не больше четверти ресурса */
export const warningKm = (t: Tracked) => Math.min(5_000, Math.max(Math.floor(t.lifeKm / 4), 1))
/** Порог «Срочно»: 1 000 км, но не больше десятой части ресурса */
export const criticalKm = (t: Tracked) => Math.min(1_000, Math.max(Math.floor(t.lifeKm / 10), 1))

export const traveledKm = (t: Tracked, mileage: number) => Math.max(0, mileage - t.baseMileage)

export const remainingKm = (t: Tracked, mileage: number) => {
  const next = nextMileage(t)
  return next === undefined ? undefined : next - mileage
}

export const remainingDays = (t: Tracked, now = Date.now()) => {
  const next = nextDate(t)
  return next === undefined ? undefined : daysBetween(now, next)
}

/** Износ 0…1+ — худший из двух критериев */
export const progress = (t: Tracked, mileage: number, now = Date.now()) => {
  const values: number[] = []
  if (t.lifeKm > 0) values.push((mileage - t.baseMileage) / t.lifeKm)
  const next = nextDate(t)
  if (next !== undefined && next > t.baseDate) values.push((now - t.baseDate) / (next - t.baseDate))
  return Math.max(0, ...values)
}

export const status = (t: Tracked, mileage: number, now = Date.now()): ServiceStatus => {
  const k = remainingKm(t, mileage)
  const d = remainingDays(t, now)
  if ((k ?? 1) <= 0 || (d ?? 1) <= 0) return 'overdue'
  if ((k ?? Infinity) < criticalKm(t) || (d ?? Infinity) < CRITICAL_DAYS) return 'critical'
  if ((k ?? Infinity) < warningKm(t) || (d ?? Infinity) < WARNING_DAYS) return 'warning'
  return 'ok'
}

export const statusTitle = (t: Tracked, mileage: number, now = Date.now()) => {
  const s = status(t, mileage, now)
  return s === 'overdue' ? t.overdueTitle : statusInfo[s].title
}

// MARK: - Подписи

/** «Осталось 5 000 км · 120 дней», «Перепробег 1 200 км» */
export const remainingDescription = (t: Tracked, mileage: number, now = Date.now()) => {
  const left: string[] = []
  const overdue: string[] = []
  const k = remainingKm(t, mileage)
  const d = remainingDays(t, now)
  if (k !== undefined) (k >= 0 ? left : overdue).push(k >= 0 ? km(k) : `перепробег ${km(-k)}`)
  if (d !== undefined) (d >= 0 ? left : overdue).push(d >= 0 ? days(d) : `просрочено на ${days(-d)}`)
  const parts = [...overdue]
  if (left.length) parts.push(`осталось ${left.join(' · ')}`)
  return capitalizedFirst(parts.join(' · '))
}

/** «460 000 км или 12 окт. 2027» */
export const nextServiceDescription = (t: Tracked) => {
  const m = nextMileage(t), d = nextDate(t)
  return [m !== undefined ? km(m) : null, d !== undefined ? dateShort(d) : null].filter(Boolean).join(' или ')
}

export const resourceDescription = (t: Tracked) => resource(t.lifeKm, t.lifeMonths)
