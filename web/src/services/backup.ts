// Резервная копия: экспорт/импорт всех данных в JSON.
// Нужна, потому что данные живут в браузере — так их можно перенести или сохранить.

import type { Car, Expense, Part, Reminder, RepairRecord } from '@/models/types'
import { db } from './db'

const FORMAT = 'autobudget-backup'
const VERSION = 1

const blobToDataURL = (blob: Blob) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(reader.error)
    reader.readAsDataURL(blob)
  })

const dataURLToBlob = async (url: string) => (await fetch(url)).blob()

type Serialized<T> = Omit<T, 'photo' | 'photoBefore' | 'photoAfter'> & { photo?: string; photoBefore?: string; photoAfter?: string }

const encodePhotos = async <T extends object>(item: T) => {
  const out: Record<string, unknown> = { ...(item as Record<string, unknown>) }
  for (const key of ['photo', 'photoBefore', 'photoAfter']) {
    const value = out[key]
    if (value instanceof Blob) out[key] = await blobToDataURL(value)
  }
  return out
}

const decodePhotos = async <T>(item: Record<string, unknown>) => {
  const out: Record<string, unknown> = { ...item }
  for (const key of ['photo', 'photoBefore', 'photoAfter']) {
    const value = out[key]
    if (typeof value === 'string' && value.startsWith('data:')) out[key] = await dataURLToBlob(value)
  }
  return out as T
}

export const exportBackup = async () => {
  const [cars, expenses, repairs, parts, reminders] = await Promise.all([
    db.cars.toArray(), db.expenses.toArray(), db.repairs.toArray(), db.parts.toArray(), db.reminders.toArray(),
  ])
  const payload = {
    format: FORMAT,
    version: VERSION,
    exportedAt: new Date().toISOString(),
    cars: await Promise.all(cars.map(encodePhotos)),
    expenses,
    repairs: await Promise.all(repairs.map(encodePhotos)),
    parts,
    reminders,
  }
  const blob = new Blob([JSON.stringify(payload)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `autobudget-${new Date().toISOString().slice(0, 10)}.json`
  a.click()
  URL.revokeObjectURL(url)
}

/** Полностью заменяет текущие данные содержимым файла */
export const importBackup = async (file: File) => {
  const data = JSON.parse(await file.text()) as {
    format?: string
    cars: Serialized<Car>[]; expenses: Expense[]; repairs: Serialized<RepairRecord>[]; parts: Part[]; reminders: Reminder[]
  }
  if (data.format !== FORMAT) throw new Error('Это не резервная копия AutoBudget')
  const cars = await Promise.all(data.cars.map(c => decodePhotos<Car>(c)))
  const repairs = await Promise.all(data.repairs.map(r => decodePhotos<RepairRecord>(r)))
  await db.transaction('rw', [db.cars, db.expenses, db.repairs, db.parts, db.reminders], async () => {
    await Promise.all([db.cars.clear(), db.expenses.clear(), db.repairs.clear(), db.parts.clear(), db.reminders.clear()])
    await db.cars.bulkAdd(cars)
    await db.expenses.bulkAdd(data.expenses)
    await db.repairs.bulkAdd(repairs)
    await db.parts.bulkAdd(data.parts)
    await db.reminders.bulkAdd(data.reminders)
  })
}
