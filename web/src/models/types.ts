// Модели данных — повторяют SwiftData-модели iOS-версии.
// Даты хранятся как timestamp (мс), связи — через id (в IndexedDB нет relationships).

export type ID = string

// MARK: - Категории расходов

export type ExpenseCategory = 'fuel' | 'maintenance' | 'tires' | 'tuning' | 'insurance' | 'taxes' | 'repair' | 'parts'

export const EXPENSE_CATEGORIES: ExpenseCategory[] = [
  'fuel', 'maintenance', 'tires', 'tuning', 'insurance', 'taxes', 'repair', 'parts',
]

/** Порядок фильтров экрана «Расходы» */
export const EXPENSE_FILTER_ORDER: ExpenseCategory[] = [
  'fuel', 'repair', 'parts', 'tires', 'tuning', 'insurance', 'maintenance', 'taxes',
]

export const expenseCategoryInfo: Record<ExpenseCategory, { title: string; defaultTitle: string; color: string }> = {
  fuel: { title: 'Топливо', defaultTitle: 'Заправка', color: '#2FC86B' },
  maintenance: { title: 'Обслуживание', defaultTitle: 'Обслуживание', color: '#3D7BFF' },
  tires: { title: 'Шины', defaultTitle: 'Шиномонтаж', color: '#8E5CFF' },
  tuning: { title: 'Тюнинг', defaultTitle: 'Тюнинг', color: '#FF4FA3' },
  insurance: { title: 'Страховка', defaultTitle: 'ОСАГО', color: '#19B5E8' },
  taxes: { title: 'Налоги', defaultTitle: 'Транспортный налог', color: '#FFB020' },
  repair: { title: 'Ремонт', defaultTitle: 'Ремонт', color: '#FF4D4F' },
  parts: { title: 'Запчасти', defaultTitle: 'Запчасти', color: '#FF7A1A' },
}

// MARK: - Категории ремонтов и деталей

export type RepairCategory = 'engine' | 'gearbox' | 'suspension' | 'brakes' | 'electrics' | 'body' | 'interior' | 'service'

export const REPAIR_CATEGORIES: RepairCategory[] = [
  'engine', 'gearbox', 'suspension', 'brakes', 'electrics', 'body', 'interior', 'service',
]

export const repairCategoryInfo: Record<RepairCategory, { title: string; color: string }> = {
  engine: { title: 'Двигатель', color: '#FF7A45' },
  gearbox: { title: 'Трансмиссия', color: '#A66CFF' },
  suspension: { title: 'Подвеска', color: '#4D8DFF' },
  brakes: { title: 'Тормоза', color: '#FF5A5F' },
  electrics: { title: 'Электрика', color: '#FFD166' },
  body: { title: 'Кузов', color: '#8E9AAF' },
  interior: { title: 'Салон', color: '#E58FD8' },
  service: { title: 'Плановое ТО', color: '#00D4AA' },
}

/** В какую категорию бюджета попадает стоимость ремонта */
export const repairExpenseCategory = (c: RepairCategory): ExpenseCategory => (c === 'service' ? 'maintenance' : 'repair')

// MARK: - Топливо

export type FuelType = 'ai92' | 'ai95' | 'ai98' | 'ai100' | 'diesel' | 'lpg' | 'other'

export const FUEL_TYPES: FuelType[] = ['ai92', 'ai95', 'ai98', 'ai100', 'diesel', 'lpg', 'other']

export const fuelTypeInfo: Record<FuelType, { title: string; short: string; color: string }> = {
  ai92: { title: 'АИ-92', short: '92', color: '#4D8DFF' },
  ai95: { title: 'АИ-95', short: '95', color: '#2FC86B' },
  ai98: { title: 'АИ-98', short: '98', color: '#A66CFF' },
  ai100: { title: 'АИ-100', short: '100', color: '#FF4FA3' },
  diesel: { title: 'Дизель', short: 'ДТ', color: '#FFB020' },
  lpg: { title: 'Газ (LPG)', short: 'Газ', color: '#19B5E8' },
  other: { title: 'Другое', short: 'Другое', color: '#8E9AAF' },
}

// MARK: - Напоминания

export type ReminderKind = 'oil' | 'filters' | 'brakePads' | 'timingBelt' | 'osago' | 'inspection' | 'custom'

export const REMINDER_KINDS: ReminderKind[] = ['oil', 'filters', 'brakePads', 'timingBelt', 'osago', 'inspection', 'custom']

export const reminderKindInfo: Record<ReminderKind, { title: string; intervalKm: number; intervalMonths: number }> = {
  oil: { title: 'Замена масла', intervalKm: 7_500, intervalMonths: 6 },
  filters: { title: 'Замена фильтров', intervalKm: 15_000, intervalMonths: 12 },
  brakePads: { title: 'Замена колодок', intervalKm: 30_000, intervalMonths: 0 },
  timingBelt: { title: 'Замена ремня ГРМ', intervalKm: 100_000, intervalMonths: 60 },
  osago: { title: 'ОСАГО', intervalKm: 0, intervalMonths: 12 },
  inspection: { title: 'Техосмотр', intervalKm: 0, intervalMonths: 24 },
  custom: { title: 'Своё напоминание', intervalKm: 0, intervalMonths: 12 },
}

// MARK: - Сущности

export interface Car {
  id: ID
  make: string
  model: string
  bodyCode: string
  year: number
  engine: string
  vin: string
  plate: string
  mileage: number
  photo?: Blob
  createdAt: number
}

export interface Expense {
  id: ID
  category: ExpenseCategory
  title: string
  date: number
  amount: number
  mileage: number
  comment: string
  /** Место покупки; для заправки — АЗС */
  place: string
  /** Объём заправки, л — только для топлива */
  liters?: number
  fuelType?: FuelType
  /** Расход создан из ремонта */
  repairId?: ID
}

export interface RepairRecord {
  id: ID
  title: string
  category: RepairCategory
  date: number
  mileage: number
  worksDone: string
  partsUsed: string
  laborCost: number
  partsCost: number
  shop: string
  comment: string
  photoBefore?: Blob
  photoAfter?: Blob
}

/**
 * Установленная деталь. Следующая замена и текущий пробег не хранятся,
 * а вычисляются (serviceTracking.ts) — пробег принадлежит автомобилю.
 */
export interface Part {
  id: ID
  name: string
  category: RepairCategory
  manufacturer: string
  articleNumber: string
  installDate: number
  installMileage: number
  serviceLifeKm: number
  serviceLifeMonths: number
  purchasePrice: number
  notes: string
  /** 1 — на учёте, 0 — снята (IndexedDB не индексирует boolean) */
  isActive: 0 | 1
  removedDate?: number
  removedMileage?: number
  repairId: ID
  /** Предыдущая деталь на этой позиции — из цепочки строится история замен */
  replacesId?: ID
}

export interface Reminder {
  id: ID
  kind: ReminderKind
  title: string
  intervalKm: number
  intervalMonths: number
  lastDate: number
  lastMileage: number
  notificationsEnabled: boolean
  notifyDaysBefore: number
}

export const repairTotal = (r: RepairRecord) => r.laborCost + r.partsCost

export const pricePerLiter = (e: Expense): number | undefined =>
  e.liters && e.liters > 0 ? e.amount / e.liters : undefined

export const newId = (): ID => crypto.randomUUID()
