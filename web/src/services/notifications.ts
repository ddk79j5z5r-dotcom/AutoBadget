// Уведомления в вебе — через Notification API браузера.
// Ограничение платформы: без сервера и push-подписки уведомление может прийти
// только пока сайт открыт (или при следующем открытии). Поэтому:
// - по пробегу — сразу при пересечении порога «Скоро»/«Срочно»/0;
// - по времени и по ресурсу деталей — проверка сроков при открытии приложения, каждое событие один раз.

import { criticalKm, nextDate, remainingKm, warningKm, type Tracked } from '@/models/serviceTracking'
import { dateShort, days, daysBetween, km } from './formatters'

export type Permission = NotificationPermission | 'unsupported'

const supported = () => typeof window !== 'undefined' && 'Notification' in window

export const permission = (): Permission => (supported() ? Notification.permission : 'unsupported')

export const requestPermission = async (): Promise<Permission> =>
  supported() ? Notification.requestPermission() : 'unsupported'

const show = (title: string, body: string, tag: string) => {
  if (permission() !== 'granted') return
  new Notification(`AutoBudget · ${title}`, { body, tag, icon: '/icon.png' })
}

/** Уведомляет, если после изменения пробега остаток пересёк порог (один раз — в момент пересечения) */
export const notifyMileageThresholds = (items: Tracked[], oldMileage: number, newMileage: number) => {
  if (newMileage <= oldMileage) return
  for (const item of items) {
    if (!item.notificationsActive) continue
    const before = remainingKm(item, oldMileage)
    const after = remainingKm(item, newMileage)
    if (before === undefined || after === undefined) continue
    const crossed = [0, criticalKm(item), warningKm(item)].find(t => before > t && after <= t)
    if (crossed === undefined) continue
    show(
      item.title,
      crossed === 0
        ? `${item.overdueTitle}: ${item.title.toLowerCase()}. Ресурс исчерпан.`
        : `Через ${km(after)} потребуется: ${item.title.toLowerCase()}.`,
      `mileage-${item.key}`,
    )
  }
}

const NOTIFIED_KEY = 'autobudget.notified'

const notifiedSet = (): Set<string> => {
  try {
    return new Set(JSON.parse(localStorage.getItem(NOTIFIED_KEY) ?? '[]') as string[])
  } catch {
    return new Set()
  }
}

/** Проверка сроков по времени: за `notifyDaysBefore` дней до даты — одно уведомление на каждый срок */
export const notifyDueDates = (items: Tracked[], now = Date.now()) => {
  if (permission() !== 'granted') return
  const sent = notifiedSet()
  for (const item of items) {
    const due = nextDate(item)
    if (!item.notificationsActive || due === undefined) continue
    const left = daysBetween(now, due)
    const id = `${item.key}@${due}`
    if (left > item.notifyDaysBefore || sent.has(id)) continue
    show(
      item.title,
      left > 0
        ? `Через ${days(left)} истекает срок: ${item.title.toLowerCase()}. Срок — ${dateShort(due)}.`
        : `Срок истёк ${dateShort(due)}: ${item.title.toLowerCase()}.`,
      id,
    )
    sent.add(id)
  }
  try {
    localStorage.setItem(NOTIFIED_KEY, JSON.stringify([...sent]))
  } catch {
    // Хранилище недоступно (приватный режим) — уведомление повторится при следующем открытии
  }
}
