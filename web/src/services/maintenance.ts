// Сводит напоминания и детали в единый список ближайшего обслуживания

import {
  progress, remainingDays, remainingKm, status, trackPart, trackReminder,
  type ServiceStatus, type Tracked,
} from '@/models/serviceTracking'
import type { Part, Reminder } from '@/models/types'
import { days, km } from './formatters'

/** Если истории пробега недостаточно — ~40 км в день (≈ 14 600 км в год) */
export const FALLBACK_DAILY_KM = 40

export interface UpcomingService {
  tracked: Tracked
  status: ServiceStatus
  progress: number
  remainingKm?: number
  remainingDays?: number
  /** Оценка, через сколько дней наступит событие — общая шкала для км и дат */
  estimatedDays: number
  /** «Через 2 000 км», «Через 20 дней» или «Требуется замена» */
  headline: string
}

export const upcoming = (
  reminders: Reminder[],
  parts: Part[],
  mileage: number,
  dailyKm: number | undefined,
  limit = 5,
  now = Date.now(),
): UpcomingService[] => {
  const pace = Math.max(dailyKm ?? FALLBACK_DAILY_KM, 1)
  const items = [...reminders.map(trackReminder), ...parts.filter(p => p.isActive === 1).map(trackPart)]

  return items
    .map(tracked => {
      const k = remainingKm(tracked, mileage)
      const d = remainingDays(tracked, now)
      const byKm = k !== undefined ? k / pace : Infinity
      const byDays = d ?? Infinity
      const s = status(tracked, mileage, now)
      let headline: string
      if (s === 'overdue') headline = tracked.overdueTitle
      else if (k !== undefined && (d === undefined || byKm <= byDays)) headline = `Через ${km(k)}`
      else if (d !== undefined) headline = `Через ${days(d)}`
      else headline = 'В норме'
      return {
        tracked,
        status: s,
        progress: progress(tracked, mileage, now),
        remainingKm: k,
        remainingDays: d,
        estimatedDays: Math.min(byKm, byDays),
        headline,
      }
    })
    .sort((a, b) => a.estimatedDays - b.estimatedDays)
    .slice(0, limit)
}
