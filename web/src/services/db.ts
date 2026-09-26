import Dexie, { type EntityTable } from 'dexie'
import type { Car, Expense, Part, Reminder, RepairRecord } from '@/models/types'

/** Локальная база в IndexedDB браузера */
export class AutoBudgetDB extends Dexie {
  cars!: EntityTable<Car, 'id'>
  expenses!: EntityTable<Expense, 'id'>
  repairs!: EntityTable<RepairRecord, 'id'>
  parts!: EntityTable<Part, 'id'>
  reminders!: EntityTable<Reminder, 'id'>

  constructor() {
    super('autobudget')
    // Индексы — только поля, по которым идут выборки
    this.version(1).stores({
      cars: 'id, createdAt',
      expenses: 'id, date, category, repairId',
      repairs: 'id, date',
      parts: 'id, repairId, replacesId, isActive, installDate',
      reminders: 'id',
    })
    // v2: несколько автомобилей — все записи привязаны к машине через carId
    this.version(2)
      .stores({
        expenses: 'id, date, category, repairId, carId',
        repairs: 'id, date, carId',
        parts: 'id, repairId, replacesId, isActive, installDate, carId',
        reminders: 'id, carId',
      })
      .upgrade(async tx => {
        // До v2 автомобиль был один — все существующие записи принадлежат ему
        const car = await tx.table<Car>('cars').orderBy('createdAt').first()
        if (!car) return
        for (const table of ['expenses', 'repairs', 'parts', 'reminders']) {
          await tx.table(table).toCollection().modify((r: { carId?: string }) => {
            r.carId ??= car.id
          })
        }
      })
  }
}

export const db = new AutoBudgetDB()
