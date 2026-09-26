// Операции, затрагивающие несколько таблиц сразу — порт DataService.swift

import { trackPart, trackReminder, type Tracked } from '@/models/serviceTracking'
import { newId, repairExpenseCategory, repairTotal, type Part, type RepairRecord } from '@/models/types'
import { db } from './db'
import { notifyMileageThresholds } from './notifications'

export const getCar = async () => (await db.cars.orderBy('createdAt').first()) ?? undefined

export const activeParts = () => db.parts.where('isActive').equals(1).toArray()

/** Всё, что отслеживается по ресурсу: регламентные работы и установленные детали */
export const trackedItems = async (): Promise<Tracked[]> => {
  const [reminders, parts] = await Promise.all([db.reminders.toArray(), activeParts()])
  return [...reminders.map(trackReminder), ...parts.map(trackPart)]
}

/**
 * Единая точка изменения пробега: обновляет автомобиль и уведомляет о пересечённых порогах.
 * onlyIncrease — для записей расходов и ремонтов (старая запись не должна «откатить» пробег).
 */
export const updateMileage = async (mileage: number, onlyIncrease = true) => {
  const car = await getCar()
  if (!car || mileage <= 0 || mileage === car.mileage) return
  if (onlyIncrease && mileage < car.mileage) return
  await db.cars.update(car.id, { mileage })
  notifyMileageThresholds(await trackedItems(), car.mileage, mileage)
}

// MARK: - Детали

const samePosition = (a: Part, b: Part) =>
  a.category === b.category && a.name.trim().toLowerCase() === b.name.trim().toLowerCase()

/**
 * Ставит новую деталь на учёт: ранее установленная деталь на той же позиции
 * снимается с учёта и связывается с новой в историю замен.
 */
export const registerInstallation = async (part: Part) => {
  const previous = (await activeParts())
    .filter(p => p.id !== part.id && samePosition(p, part) && p.installDate <= part.installDate)
    .sort((a, b) => b.installDate - a.installDate)[0]
  if (previous) {
    await db.parts.update(previous.id, { isActive: 0, removedDate: part.installDate, removedMileage: part.installMileage })
    part.replacesId = previous.id
  }
  await db.parts.put(part)
}

/** Удаляет деталь; если она заменила другую — предыдущая снова становится активной */
export const deletePart = async (part: Part) => {
  if (part.isActive === 1 && part.replacesId) {
    await db.parts.update(part.replacesId, { isActive: 1, removedDate: undefined, removedMileage: undefined })
  }
  // Деталь, которую заменила удаляемая, «наследует» ссылку на предыдущую — цепочка истории не рвётся
  const successor = await db.parts.where('replacesId').equals(part.id).first()
  if (successor) await db.parts.update(successor.id, { replacesId: part.replacesId })
  await db.parts.delete(part.id)
}

/** История замен: от текущей детали к самой старой */
export const replacementHistory = async (part: Part) => {
  const chain: Part[] = [part]
  let cursor = part.replacesId
  while (cursor && !chain.some(p => p.id === cursor)) {
    const prev = await db.parts.get(cursor)
    if (!prev) break
    chain.push(prev)
    cursor = prev.replacesId
  }
  return chain
}

// MARK: - Ремонт ⇄ бюджет

/** Каждый ремонт автоматически попадает в бюджет как расход и обновляется вместе с ним */
export const syncExpense = async (repair: RepairRecord) => {
  const existing = await db.expenses.where('repairId').equals(repair.id).first()
  const fields = {
    title: repair.title,
    category: repairExpenseCategory(repair.category),
    date: repair.date,
    amount: repairTotal(repair),
    mileage: repair.mileage,
    place: repair.shop,
    comment: [repair.worksDone, repair.comment].filter(Boolean).join('\n'),
  }
  if (existing) {
    await db.expenses.update(existing.id, fields)
  } else if (fields.amount > 0) {
    await db.expenses.add({ id: newId(), repairId: repair.id, ...fields })
  }
}

export const deleteRepair = async (repair: RepairRecord) =>
  db.transaction('rw', db.repairs, db.parts, db.expenses, async () => {
    const parts = await db.parts.where('repairId').equals(repair.id).toArray()
    for (const part of parts) await deletePart(part)
    await db.expenses.where('repairId').equals(repair.id).delete()
    await db.repairs.delete(repair.id)
  })

export const deleteAll = () =>
  db.transaction('rw', [db.cars, db.expenses, db.repairs, db.parts, db.reminders], async () => {
    await Promise.all([db.cars.clear(), db.expenses.clear(), db.repairs.clear(), db.parts.clear(), db.reminders.clear()])
  })
