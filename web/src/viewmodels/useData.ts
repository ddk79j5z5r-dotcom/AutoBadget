// Живые запросы к IndexedDB: компоненты перерисовываются при любом изменении данных.
// Списки — всегда в пределах выбранного автомобиля.

import { useLiveQuery } from 'dexie-react-hooks'
import type { Car, Expense, Part, Reminder, RepairRecord } from '@/models/types'
import { db } from '@/services/db'
import { useCurrentCar } from './currentCar'

const EMPTY: never[] = []

/** Выбранный автомобиль */
export const useCar = (): Car | undefined => useCurrentCar().car

/** Расходы выбранного автомобиля, новые сверху */
export const useExpenses = (): Expense[] => {
  const id = useCar()?.id
  return useLiveQuery(() => (id ? db.expenses.where('carId').equals(id).reverse().sortBy('date') : EMPTY), [id]) ?? EMPTY
}

/** Ремонты выбранного автомобиля, новые сверху */
export const useRepairs = (): RepairRecord[] => {
  const id = useCar()?.id
  return useLiveQuery(() => (id ? db.repairs.where('carId').equals(id).reverse().sortBy('date') : EMPTY), [id]) ?? EMPTY
}

export const useActiveParts = (): Part[] => {
  const id = useCar()?.id
  return useLiveQuery(
    () => (id ? db.parts.where('carId').equals(id).filter(p => p.isActive === 1).toArray() : EMPTY), [id],
  ) ?? EMPTY
}

export const useReminders = (): Reminder[] => {
  const id = useCar()?.id
  return useLiveQuery(() => (id ? db.reminders.where('carId').equals(id).toArray() : EMPTY), [id]) ?? EMPTY
}

export const useRepair = (id: string | undefined) =>
  useLiveQuery(() => (id ? db.repairs.get(id) : undefined), [id])

export const usePart = (id: string | undefined) => useLiveQuery(() => (id ? db.parts.get(id) : undefined), [id])

export const usePartsOfRepair = (repairId: string | undefined): Part[] =>
  useLiveQuery(() => (repairId ? db.parts.where('repairId').equals(repairId).sortBy('name') : []), [repairId]) ?? EMPTY
