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
    // Индексы — только поля, по которым идут выборки. Новые версии схемы добавлять через this.version(2)…
    this.version(1).stores({
      cars: 'id, createdAt',
      expenses: 'id, date, category, repairId',
      repairs: 'id, date',
      parts: 'id, repairId, replacesId, isActive, installDate',
      reminders: 'id',
    })
  }
}

export const db = new AutoBudgetDB()
