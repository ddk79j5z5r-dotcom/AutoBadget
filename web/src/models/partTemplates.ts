import type { RepairCategory } from './types'

/** Типовые детали с рекомендуемым ресурсом — быстрый выбор в форме детали */
export interface PartTemplate {
  name: string
  category: RepairCategory
  lifeKm: number
  lifeMonths: number
}

export const PART_TEMPLATES: PartTemplate[] = [
  { name: 'Моторное масло', category: 'service', lifeKm: 7_500, lifeMonths: 12 },
  { name: 'Масляный фильтр', category: 'service', lifeKm: 7_500, lifeMonths: 12 },
  { name: 'Воздушный фильтр', category: 'service', lifeKm: 15_000, lifeMonths: 12 },
  { name: 'Салонный фильтр', category: 'service', lifeKm: 15_000, lifeMonths: 12 },
  { name: 'Свечи зажигания', category: 'engine', lifeKm: 30_000, lifeMonths: 0 },
  { name: 'Ремень ГРМ', category: 'engine', lifeKm: 100_000, lifeMonths: 60 },
  { name: 'Помпа', category: 'engine', lifeKm: 100_000, lifeMonths: 0 },
  { name: 'Антифриз', category: 'engine', lifeKm: 60_000, lifeMonths: 36 },
  { name: 'Масло АКПП (ATF)', category: 'gearbox', lifeKm: 40_000, lifeMonths: 0 },
  { name: 'Передние колодки', category: 'brakes', lifeKm: 30_000, lifeMonths: 0 },
  { name: 'Задние колодки', category: 'brakes', lifeKm: 50_000, lifeMonths: 0 },
  { name: 'Тормозные диски', category: 'brakes', lifeKm: 60_000, lifeMonths: 0 },
  { name: 'Тормозная жидкость', category: 'brakes', lifeKm: 0, lifeMonths: 24 },
  { name: 'Амортизаторы', category: 'suspension', lifeKm: 80_000, lifeMonths: 0 },
  { name: 'Сайлентблоки', category: 'suspension', lifeKm: 80_000, lifeMonths: 0 },
  { name: 'Аккумулятор', category: 'electrics', lifeKm: 0, lifeMonths: 48 },
  { name: 'Щётки стеклоочистителя', category: 'body', lifeKm: 0, lifeMonths: 12 },
]
