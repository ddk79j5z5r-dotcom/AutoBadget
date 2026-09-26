// Демо-данные: Toyota Aristo JZS160, 1998, 2JZ-GE, 430 000 км — те же, что в iOS-версии

import {
  newId, type Expense, type ExpenseCategory, type FuelType, type Part, type RepairCategory, type RepairRecord, type Reminder,
} from '@/models/types'
import { db } from './db'
import { addCar, registerInstallation, syncExpense } from './dataService'

const date = (y: number, m: number, d: number) => new Date(y, m - 1, d, 12).getTime()

/** Детерминированный генератор, чтобы демо-данные были одинаковыми при каждой загрузке */
const seeded = (seed: number) => {
  let s = seed >>> 0
  return () => {
    s = (s + 0x6d2b79f5) >>> 0
    let t = s
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

type RepairSeed = Omit<RepairRecord, 'id' | 'carId' | 'partsUsed' | 'comment'> & { partsUsed?: string; comment?: string }
type PartSeed = Pick<Part, 'name' | 'category' | 'manufacturer' | 'articleNumber' | 'purchasePrice'> &
  Partial<Pick<Part, 'serviceLifeKm' | 'serviceLifeMonths' | 'notes'>>

const repair = (r: RepairSeed): RepairSeed => r
const part = (p: PartSeed): PartSeed => p

// Хронологический порядок важен: новая деталь снимает с учёта ранее установленную на той же позиции
const REPAIRS: [RepairSeed, PartSeed[]][] = [
  [repair({ title: 'Замена ремня ГРМ и помпы', category: 'engine', date: date(2021, 11, 10), mileage: 342_000,
    worksDone: 'Замена ремня ГРМ, натяжного и обводного роликов, помпы', partsUsed: 'Ролики ГРМ, антифриз',
    laborCost: 6_000, partsCost: 14_500, shop: 'Garage 2JZ' }),
  [part({ name: 'Ремень ГРМ', category: 'engine', manufacturer: 'Gates', articleNumber: 'T254', serviceLifeKm: 100_000, serviceLifeMonths: 60, purchasePrice: 4_200 }),
   part({ name: 'Помпа', category: 'engine', manufacturer: 'Aisin', articleNumber: 'WPT-060', serviceLifeKm: 100_000, purchasePrice: 5_800 })]],
  [repair({ title: 'Ремонт коробки передач', category: 'gearbox', date: date(2024, 6, 14), mileage: 398_700,
    worksDone: 'Снятие/установка АКПП, дефектовка, замена фрикционов и сальников, промывка гидроблока',
    partsUsed: 'Ремкомплект АКПП, пакет фрикционов, фильтр АКПП', laborCost: 38_000, partsCost: 42_500,
    shop: 'АКПП-Сервис на Обводном', comment: 'Пинки при переключении 2→3. После ремонта — гарантия 12 мес.' }),
  [part({ name: 'Масло АКПП (ATF)', category: 'gearbox', manufacturer: 'Toyota', articleNumber: '08886-01705', serviceLifeKm: 40_000, purchasePrice: 9_600, notes: 'ATF Type T-IV, 12 л' })]],
  [repair({ title: 'Замена колодок и дисков', category: 'brakes', date: date(2024, 10, 28), mileage: 402_000,
    worksDone: 'Замена передних тормозных дисков и колодок, замена тормозной жидкости',
    laborCost: 3_000, partsCost: 9_800, shop: 'Тормоза+' }),
  [part({ name: 'Передние колодки', category: 'brakes', manufacturer: 'Akebono', articleNumber: 'AN-690WK', serviceLifeKm: 30_000, purchasePrice: 3_900 }),
   part({ name: 'Тормозные диски', category: 'brakes', manufacturer: 'Brembo', articleNumber: '09.A717.10', serviceLifeKm: 60_000, purchasePrice: 5_100 }),
   part({ name: 'Тормозная жидкость', category: 'brakes', manufacturer: 'Toyota', articleNumber: 'DOT4', serviceLifeMonths: 24, purchasePrice: 800 })]],
  [repair({ title: 'Плановое ТО', category: 'service', date: date(2025, 1, 20), mileage: 407_900,
    worksDone: 'Замена моторного масла, масляного и воздушного фильтров', laborCost: 1_800, partsCost: 6_200, shop: 'Garage 2JZ' }),
  [part({ name: 'Моторное масло', category: 'service', manufacturer: 'Mobil 1', articleNumber: '5W-30, 5 л', serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 4_300 }),
   part({ name: 'Масляный фильтр', category: 'service', manufacturer: 'Toyota', articleNumber: '90915-YZZD2', serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 700 }),
   part({ name: 'Воздушный фильтр', category: 'service', manufacturer: 'Mann', articleNumber: 'C 26 003', serviceLifeKm: 15_000, serviceLifeMonths: 12, purchasePrice: 1_200 })]],
  [repair({ title: 'Замена топливного насоса', category: 'engine', date: date(2025, 4, 22), mileage: 412_300,
    worksDone: 'Замена топливного насоса в баке, проверка давления топлива', partsUsed: 'Сетка насоса',
    laborCost: 5_000, partsCost: 8_500, shop: 'Garage 2JZ', comment: 'Машина глохла на горячую, падало давление топлива.' }),
  [part({ name: 'Топливный насос', category: 'engine', manufacturer: 'Denso', articleNumber: '195130-7010', serviceLifeKm: 150_000, purchasePrice: 8_100 })]],
  [repair({ title: 'Плановое ТО', category: 'service', date: date(2025, 8, 2), mileage: 415_100,
    worksDone: 'Замена масла, масляного фильтра, свечей зажигания', laborCost: 2_500, partsCost: 9_800, shop: 'Garage 2JZ' }),
  [part({ name: 'Моторное масло', category: 'service', manufacturer: 'Mobil 1', articleNumber: '5W-30, 5 л', serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 4_400 }),
   part({ name: 'Масляный фильтр', category: 'service', manufacturer: 'Toyota', articleNumber: '90915-YZZD2', serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 700 }),
   part({ name: 'Свечи зажигания', category: 'engine', manufacturer: 'Denso', articleNumber: 'IK20 ×6', serviceLifeKm: 30_000, purchasePrice: 4_700 })]],
  [repair({ title: 'Замена генератора', category: 'electrics', date: date(2026, 1, 18), mileage: 421_900,
    worksDone: 'Диагностика зарядки, замена генератора', laborCost: 2_500, partsCost: 14_000, shop: 'Автоэлектрик Сергей' }),
  [part({ name: 'Генератор', category: 'electrics', manufacturer: 'Denso (восст.)', articleNumber: '27060-46090', serviceLifeKm: 150_000, purchasePrice: 14_000 })]],
  [repair({ title: 'Обслуживание подвески', category: 'suspension', date: date(2026, 4, 12), mileage: 424_600,
    worksDone: 'Замена сайлентблоков передних рычагов, стоек стабилизатора, развал-схождение',
    laborCost: 9_500, partsCost: 16_800, shop: 'Подвеска-Про', comment: 'Стук спереди на неровностях — устранён.' }),
  [part({ name: 'Сайлентблоки передних рычагов', category: 'suspension', manufacturer: 'Toyota', articleNumber: '48655-30150', serviceLifeKm: 80_000, purchasePrice: 11_200 }),
   part({ name: 'Стойки стабилизатора', category: 'suspension', manufacturer: '555', articleNumber: 'SL-3710', serviceLifeKm: 60_000, purchasePrice: 5_600 })]],
  [repair({ title: 'Плановое ТО', category: 'service', date: date(2026, 7, 20), mileage: 428_100,
    worksDone: 'Замена моторного масла, масляного, воздушного и салонного фильтров', laborCost: 2_000, partsCost: 7_400, shop: 'Garage 2JZ' }),
  [part({ name: 'Моторное масло', category: 'service', manufacturer: 'Mobil 1', articleNumber: '5W-30, 5 л', serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 4_600 }),
   part({ name: 'Масляный фильтр', category: 'service', manufacturer: 'Toyota', articleNumber: '90915-YZZD2', serviceLifeKm: 7_500, serviceLifeMonths: 12, purchasePrice: 750 }),
   part({ name: 'Воздушный фильтр', category: 'service', manufacturer: 'Mann', articleNumber: 'C 26 003', serviceLifeKm: 15_000, serviceLifeMonths: 12, purchasePrice: 1_250 }),
   part({ name: 'Салонный фильтр', category: 'service', manufacturer: 'Denso', articleNumber: 'DCC-1009', serviceLifeKm: 15_000, serviceLifeMonths: 12, purchasePrice: 800 })]],
  [repair({ title: 'Полировка фар и перекрас бампера', category: 'body', date: date(2026, 9, 2), mileage: 429_700,
    worksDone: 'Восстановительная полировка фар, локальный окрас переднего бампера', partsUsed: 'Краска, лак',
    laborCost: 9_000, partsCost: 2_500, shop: 'Кузовной цех «Гранд»' }), []],
]

const seedRepairs = async (carId: string) => {
  for (const [seed, parts] of REPAIRS) {
    const record: RepairRecord = { id: newId(), carId, partsUsed: '', comment: '', ...seed }
    await db.repairs.add(record)
    for (const p of parts) {
      await registerInstallation({
        id: newId(), serviceLifeKm: 0, serviceLifeMonths: 0, notes: '', ...p,
        category: p.category as RepairCategory,
        installDate: record.date, installMileage: record.mileage, isActive: 1, repairId: record.id, carId,
      })
    }
    await syncExpense(record)
  }
}

const seedExpenses = async (carId: string) => {
  const rand = seeded(160)
  const between = (a: number, b: number) => a + (b - a) * rand()
  const now = Date.now()
  const start = now - 364 * 86_400_000
  const startKm = 417_200, endKm = 430_000
  const stations = ['Лукойл', 'Газпромнефть', 'Роснефть', 'Shell', 'Татнефть']
  const expenses: Expense[] = []

  // Заправки каждые 10–16 дней; литры считаются от пройденного расстояния (~13 л/100 км)
  let day = 0
  let previousKm = startKm
  while (day <= 360) {
    const km = startKm + ((endKm - startKm) * day) / 364
    const liters = day === 0 ? 55 : Math.round((km - previousKm) * between(0.124, 0.14))
    // Каждая пятая заправка — АИ-98
    const fuelType: FuelType = rand() < 0.2 ? 'ai98' : 'ai95'
    const price = (fuelType === 'ai98' ? 67.4 : 58.9) + (day / 360) * 5 + between(-0.6, 0.6)
    expenses.push({
      id: newId(), carId, category: 'fuel', title: 'Заправка', date: start + day * 86_400_000,
      amount: Math.round(liters * price), mileage: Math.round(km), comment: '',
      place: stations[Math.floor(rand() * stations.length)], liters, fuelType,
    })
    previousKm = km
    day += 10 + Math.floor(rand() * 7)
  }

  const kmAt = (t: number) => Math.round(startKm + (endKm - startKm) * Math.min(Math.max((t - start) / (now - start), 0), 1))
  const ago = (d: number) => now - d * 86_400_000
  const misc: [ExpenseCategory, string, number, number, string, string][] = [
    ['tires', 'Зимняя резина Nokian Hakkapeliitta 225/55 R16', ago(340), 38_400, 'Колёса Даром', 'Комплект 4 шт.'],
    ['tires', 'Сезонный шиномонтаж', ago(338), 2_400, 'Шиномонтаж 24', ''],
    ['tires', 'Сезонный шиномонтаж', ago(160), 2_400, 'Шиномонтаж 24', 'Переобувка на лето'],
    ['taxes', 'Транспортный налог', ago(300), 16_500, 'Госуслуги', '220 л.с. × 75 ₽'],
    ['insurance', 'ОСАГО', date(2026, 3, 10), 14_800, 'Ингосстрах', 'Без ограничений по водителям'],
    ['insurance', 'КАСКО (частичное)', date(2026, 3, 12), 21_000, 'Ингосстрах', 'Угон + тотал'],
    ['parts', 'Щётки стеклоочистителя', ago(330), 1_850, 'Exist.ru', 'Bosch Aerotwin'],
    ['parts', 'Аккумулятор 75Ah', ago(250), 9_500, 'Автозапчасти 78', 'Varta Blue Dynamic'],
    ['parts', 'Лампы ближнего света D2S', ago(95), 4_300, 'Exist.ru', ''],
    ['tuning', 'Линзы Bi-LED', ago(120), 12_000, 'LightLab', 'Установка в фары'],
    ['tuning', 'Шумоизоляция дверей', ago(60), 18_000, 'Тишина-Авто', '4 двери, вибродемпфер + сплен'],
    ['maintenance', 'Мойка и химчистка салона', ago(200), 6_500, 'Detailing Club', ''],
    ['maintenance', 'Замена антифриза', ago(45), 3_900, 'Garage 2JZ', 'Toyota SLLC 6 л'],
    ['maintenance', 'Мойка кузова', ago(12), 900, 'Мойка «Капля»', ''],
  ]
  for (const [category, title, d, amount, place, comment] of misc) {
    expenses.push({ id: newId(), carId, category, title, date: d, amount, mileage: kmAt(d), comment, place })
  }
  await db.expenses.bulkAdd(expenses)
}

/**
 * Напоминания — для процедур и документов. Масло, фильтры, колодки и ремень ГРМ
 * отслеживаются как детали, чтобы одно и то же событие не появлялось дважды.
 */
const seedReminders = async (carId: string) => {
  const reminders: Reminder[] = [
    { id: newId(), carId, kind: 'osago', title: 'ОСАГО', intervalKm: 0, intervalMonths: 12, lastDate: date(2026, 3, 10),
      lastMileage: 423_500, notificationsEnabled: true, notifyDaysBefore: 14 },
    { id: newId(), carId, kind: 'inspection', title: 'Техосмотр', intervalKm: 0, intervalMonths: 24, lastDate: date(2024, 10, 15),
      lastMileage: 401_000, notificationsEnabled: true, notifyDaysBefore: 14 },
  ]
  await db.reminders.bulkAdd(reminders)
}

/** Добавляет демонстрационный автомобиль со всей историей; возвращает его id */
export const addDemoCar = () =>
  db.transaction('rw', [db.cars, db.expenses, db.repairs, db.parts, db.reminders], async () => {
    const car = await addCar({
      make: 'Toyota', model: 'Aristo', bodyCode: 'JZS160', year: 1998, engine: '2JZ-GE',
      vin: 'JZS160-0071345', plate: 'А160РС 178', mileage: 430_000,
    })
    await seedRepairs(car.id)
    await seedExpenses(car.id)
    await seedReminders(car.id)
    return car.id
  })
