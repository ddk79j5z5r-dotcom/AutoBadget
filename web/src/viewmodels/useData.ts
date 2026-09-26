// Живые запросы к IndexedDB: компоненты перерисовываются при любом изменении данных

import { useLiveQuery } from 'dexie-react-hooks'
import type { Car, Expense, Part, Reminder, RepairRecord } from '@/models/types'
import { db } from '@/services/db'

const EMPTY: never[] = []

export const useCar = (): Car | undefined => useLiveQuery(() => db.cars.orderBy('createdAt').first(), [])

/** Расходы, новые сверху */
export const useExpenses = (): Expense[] =>
  useLiveQuery(() => db.expenses.orderBy('date').reverse().toArray(), []) ?? EMPTY

/** Ремонты, новые сверху */
export const useRepairs = (): RepairRecord[] =>
  useLiveQuery(() => db.repairs.orderBy('date').reverse().toArray(), []) ?? EMPTY

export const useActiveParts = (): Part[] =>
  useLiveQuery(() => db.parts.where('isActive').equals(1).toArray(), []) ?? EMPTY

export const useReminders = (): Reminder[] => useLiveQuery(() => db.reminders.toArray(), []) ?? EMPTY

export const useRepair = (id: string | undefined) =>
  useLiveQuery(() => (id ? db.repairs.get(id) : undefined), [id])

export const usePart = (id: string | undefined) => useLiveQuery(() => (id ? db.parts.get(id) : undefined), [id])

export const usePartsOfRepair = (repairId: string | undefined): Part[] =>
  useLiveQuery(() => (repairId ? db.parts.where('repairId').equals(repairId).sortBy('name') : []), [repairId]) ?? EMPTY

/** Первый вызов вернёт undefined — пока база не ответила, экраны показывают пустое состояние без мигания */
export const useIsLoaded = () => useLiveQuery(() => db.cars.count(), []) !== undefined
