import { Trash } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { ConfirmDialog, Sheet } from '@/components/Sheet'
import { CategoryIcon, ChipBar, DangerButton, FieldInput, FieldLabel, FieldRow, FilterChip, PrimaryButton, TextArea, cx } from '@/components/ui'
import {
  EXPENSE_CATEGORIES, FUEL_TYPES, expenseCategoryInfo, fuelTypeInfo, newId, pricePerLiter,
  type Expense, type ExpenseCategory, type FuelType,
} from '@/models/types'
import { db } from '@/services/db'
import { updateMileage } from '@/services/dataService'
import { fromDateInput, grouped, parseNumber, toDateInput } from '@/services/formatters'
import { useCar } from '@/viewmodels/useData'

const formatNumber = (n?: number) => (n ? grouped(n) : '')

/**
 * Подписи полей «место» и «комментарий» под категорию: у заправки это АЗС, у страховки — компания,
 * у запчастей комментарий становится списком купленного. Налогам поле места не нужно.
 */
const categoryFields: Record<ExpenseCategory, {
  place?: { label: string; placeholder: string }
  comment: { label: string; placeholder: string }
}> = {
  fuel: {
    place: { label: 'АЗС', placeholder: 'Лукойл, Shell…' },
    comment: { label: 'Комментарий (необязательно)', placeholder: 'Например: полный бак' },
  },
  maintenance: {
    place: { label: 'Где делали', placeholder: 'СТО, мойка, детейлинг' },
    comment: { label: 'Что сделано (необязательно)', placeholder: 'Например: замена антифриза, 6 л' },
  },
  tires: {
    place: { label: 'Где', placeholder: 'Шиномонтаж, магазин' },
    comment: { label: 'Комментарий (необязательно)', placeholder: 'Например: зимняя резина 225/55 R16' },
  },
  tuning: {
    place: { label: 'Исполнитель / магазин', placeholder: 'Мастерская, магазин' },
    comment: { label: 'Что сделано (необязательно)', placeholder: 'Например: линзы Bi-LED в фары' },
  },
  insurance: {
    place: { label: 'Страховая компания', placeholder: 'Ингосстрах, Росгосстрах…' },
    comment: { label: 'Комментарий (необязательно)', placeholder: 'Например: полис до 10.03.2027' },
  },
  taxes: {
    comment: { label: 'Комментарий (необязательно)', placeholder: 'Например: оплачено через Госуслуги' },
  },
  repair: {
    place: { label: 'СТО / мастер', placeholder: 'Название сервиса' },
    comment: { label: 'Что сделано (необязательно)', placeholder: 'Например: замена сайлентблоков' },
  },
  parts: {
    place: { label: 'Магазин', placeholder: 'Exist.ru, Emex…' },
    comment: { label: 'Что куплено', placeholder: 'Например: колодки Akebono, диски Brembo' },
  },
}

/** Добавление / редактирование расхода — порт AddExpenseView + AddExpenseViewModel */
export const AddExpenseSheet = ({ expense, preset, onClose }: {
  expense?: Expense
  preset?: ExpenseCategory
  onClose: () => void
}) => {
  const [category, setCategory] = useState<ExpenseCategory>(expense?.category ?? preset ?? 'fuel')
  const [title, setTitle] = useState(expense?.title ?? expenseCategoryInfo[category].defaultTitle)
  const [date, setDate] = useState(toDateInput(expense?.date ?? Date.now()))
  const [amount, setAmount] = useState(formatNumber(expense?.amount))
  const [fuelType, setFuelType] = useState<FuelType>(expense?.fuelType ?? 'ai95')
  const [liters, setLiters] = useState(expense?.liters ? String(expense.liters).replace('.', ',') : '')
  const [price, setPrice] = useState(expense && pricePerLiter(expense) ? pricePerLiter(expense)!.toFixed(2).replace('.', ',') : '')
  const [place, setPlace] = useState(expense?.place ?? '')
  const [comment, setComment] = useState(expense?.comment ?? '')
  const [confirmDelete, setConfirmDelete] = useState(false)
  const firstField = useRef<HTMLInputElement>(null)
  const car = useCar()
  const carId = expense?.carId ?? car?.id
  const [mileage, setMileage] = useState(String(expense?.mileage || car?.mileage || ''))

  const isFuel = category === 'fuel'
  const fields = categoryFields[category]
  const isLinkedToRepair = !!expense?.repairId
  const amountValue = parseNumber(amount) ?? 0
  const valid = amountValue > 0 && title.trim() !== '' && !!carId

  useEffect(() => {
    if (!expense) window.setTimeout(() => firstField.current?.focus(), 350)
  }, [expense])

  const changeCategory = (c: ExpenseCategory) => {
    // Подставляем название по умолчанию, если пользователь его не менял
    if (!title || title === expenseCategoryInfo[category].defaultTitle) setTitle(expenseCategoryInfo[c].defaultTitle)
    setCategory(c)
  }

  /** Литры × цена за литр → сумма (её можно поправить вручную) */
  const recalc = (l: string, p: string) => {
    const lv = parseNumber(l), pv = parseNumber(p)
    if (lv && pv) setAmount(grouped(Math.round(lv * pv)))
  }

  const save = async () => {
    if (!valid || !carId) return
    const km = Math.round(parseNumber(mileage) ?? 0)
    const record: Expense = {
      id: expense?.id ?? newId(),
      carId,
      category,
      title: title.trim(),
      date: fromDateInput(date),
      amount: amountValue,
      mileage: km,
      place: place.trim(),
      comment: comment.trim(),
      liters: isFuel ? parseNumber(liters) : undefined,
      fuelType: isFuel ? fuelType : undefined,
      repairId: expense?.repairId,
    }
    await db.expenses.put(record)
    await updateMileage(carId, km)
    onClose()
  }

  const remove = async () => {
    if (expense) await db.expenses.delete(expense.id)
    onClose()
  }

  return (
    <Sheet
      title={expense ? 'Изменить расход' : 'Добавить расход'}
      onClose={onClose}
      footer={<PrimaryButton disabled={!valid} onClick={save}>Сохранить</PrimaryButton>}
    >
      <form className="space-y-2.5" onSubmit={e => { e.preventDefault(); save() }}>
        <div className="grid grid-cols-4 gap-2 pb-2">
          {EXPENSE_CATEGORIES.map(c => {
            const selected = c === category
            const color = expenseCategoryInfo[c].color
            return (
              <button
                key={c}
                type="button"
                disabled={isLinkedToRepair}
                onClick={() => changeCategory(c)}
                className={cx(
                  'flex h-[78px] flex-col items-center justify-center gap-2 rounded-2xl border transition active:scale-95 disabled:opacity-50',
                  selected ? '' : 'border-stroke bg-card',
                )}
                style={selected ? { borderColor: color, background: `${color}29` } : undefined}
              >
                <CategoryIcon category={c} size={32} />
                <span className={cx('w-full truncate px-1 text-[11px] font-medium', selected ? 'text-text' : 'text-text-2')}>
                  {expenseCategoryInfo[c].title}
                </span>
              </button>
            )
          })}
        </div>

        <FieldRow label="Дата">
          <input type="date" value={date} onChange={e => setDate(e.target.value)} className="text-right" required />
        </FieldRow>

        {isFuel && (
          <>
            <ChipBar>
              {FUEL_TYPES.map(t => (
                <FilterChip key={t} title={fuelTypeInfo[t].title} selected={t === fuelType} onClick={() => setFuelType(t)} />
              ))}
            </ChipBar>
            <FieldRow label="Объём">
              <FieldInput ref={firstField} inputMode="decimal" placeholder="0" value={liters}
                onChange={e => { setLiters(e.target.value); recalc(e.target.value, price) }} />
              <span className="text-text-2">л</span>
            </FieldRow>
            <FieldRow label="Цена за литр">
              <FieldInput inputMode="decimal" placeholder="0" value={price}
                onChange={e => { setPrice(e.target.value); recalc(liters, e.target.value) }} />
              <span className="text-text-2">₽/л</span>
            </FieldRow>
          </>
        )}

        <FieldRow label="Сумма">
          <FieldInput ref={isFuel ? undefined : firstField} inputMode="decimal" placeholder="0" value={amount}
            onChange={e => setAmount(e.target.value)} className="font-rounded font-semibold" />
          <span className="text-text-2">₽</span>
        </FieldRow>
        <FieldRow label="Пробег (км)">
          <FieldInput inputMode="numeric" placeholder="0" value={mileage} onChange={e => setMileage(e.target.value)} />
        </FieldRow>
        <FieldRow label="Название">
          <FieldInput placeholder="Название" value={title} onChange={e => setTitle(e.target.value)} />
        </FieldRow>
        {fields.place && (
          <FieldRow label={fields.place.label}>
            <FieldInput placeholder={fields.place.placeholder} value={place} onChange={e => setPlace(e.target.value)} />
          </FieldRow>
        )}

        <FieldLabel>{fields.comment.label}</FieldLabel>
        <TextArea placeholder={fields.comment.placeholder} value={comment} onChange={e => setComment(e.target.value)} />

        {expense && (
          <div className="pt-3">
            <DangerButton onClick={() => setConfirmDelete(true)}><Trash size={17} /> Удалить расход</DangerButton>
          </div>
        )}
        <button type="submit" hidden />
      </form>

      {confirmDelete && (
        <ConfirmDialog title="Удалить расход?" onConfirm={remove} onCancel={() => setConfirmDelete(false)} />
      )}
    </Sheet>
  )
}
