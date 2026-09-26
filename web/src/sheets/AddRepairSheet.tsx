import { Camera, CircleMinus, CirclePlus, X } from 'lucide-react'
import { useState } from 'react'
import { repairIcon } from '@/components/icons'
import { useObjectURL } from '@/components/rows'
import { Sheet } from '@/components/Sheet'
import { FieldInput, FieldLabel, FieldRow, PrimaryButton, TextArea, cx } from '@/components/ui'
import { REPAIR_CATEGORIES, newId, repairCategoryInfo, type Part, type RepairCategory, type RepairRecord } from '@/models/types'
import { db } from '@/services/db'
import { deletePart, registerInstallation, syncExpense, updateMileage } from '@/services/dataService'
import { fromDateInput, grouped, parseNumber, rub, toDateInput } from '@/services/formatters'
import { downscaleImage } from '@/services/images'
import { useCar, usePartsOfRepair } from '@/viewmodels/useData'
import {
  PartFormSheet, draftFromPart, draftResource, draftValues, newPartDraft, type PartDraft,
} from './PartFormSheet'

const money = (n?: number) => (n ? grouped(n) : '')

/** Новый ремонт / редактирование — порт AddRepairView + AddRepairViewModel */
export const AddRepairSheet = ({ repair, onClose }: {
  repair?: RepairRecord
  onClose: () => void
}) => {
  const car = useCar()
  const carId = repair?.carId ?? car?.id
  const savedParts = usePartsOfRepair(repair?.id)
  const [title, setTitle] = useState(repair?.title ?? '')
  const [category, setCategory] = useState<RepairCategory>(repair?.category ?? 'engine')
  const [date, setDate] = useState(toDateInput(repair?.date ?? Date.now()))
  const [mileage, setMileage] = useState(String(repair?.mileage || car?.mileage || ''))
  const [worksDone, setWorksDone] = useState(repair?.worksDone ?? '')
  const [partsUsed, setPartsUsed] = useState(repair?.partsUsed ?? '')
  const [labor, setLabor] = useState(money(repair?.laborCost))
  const [partsCost, setPartsCost] = useState(money(repair?.partsCost))
  const [shop, setShop] = useState(repair?.shop ?? '')
  const [comment, setComment] = useState(repair?.comment ?? '')
  const [photoBefore, setPhotoBefore] = useState(repair?.photoBefore)
  const [photoAfter, setPhotoAfter] = useState(repair?.photoAfter)

  // Черновики деталей: сохранённые подтягиваются из базы один раз, дальше правятся локально
  const [drafts, setDrafts] = useState<PartDraft[] | undefined>(repair ? undefined : [])
  const [removed, setRemoved] = useState<Part[]>([])
  const [editing, setEditing] = useState<PartDraft>()
  const partDrafts = drafts ?? savedParts.map(draftFromPart)

  const laborValue = parseNumber(labor) ?? 0
  const partsValue = parseNumber(partsCost) ?? 0
  const draftsTotal = partDrafts.reduce((s, d) => s + draftValues(d).purchasePrice, 0)
  const valid = title.trim() !== '' && !!carId

  const upsertDraft = (d: PartDraft) =>
    setDrafts(prev => {
      const list = prev ?? partDrafts
      return list.some(x => x.key === d.key) ? list.map(x => (x.key === d.key ? d : x)) : [...list, d]
    })

  const removeDraft = (d: PartDraft) => {
    setDrafts((drafts ?? partDrafts).filter(x => x.key !== d.key))
    if (d.part) setRemoved(r => [...r, d.part!])
  }

  const save = async () => {
    if (!valid || !carId) return
    const record: RepairRecord = {
      id: repair?.id ?? newId(),
      carId,
      title: title.trim(),
      category,
      date: fromDateInput(date),
      mileage: Math.round(parseNumber(mileage) ?? 0),
      worksDone, partsUsed,
      laborCost: laborValue,
      partsCost: partsValue,
      shop: shop.trim(), comment,
      photoBefore, photoAfter,
    }
    await db.transaction('rw', db.repairs, db.parts, db.expenses, async () => {
      await db.repairs.put(record)
      for (const part of removed) await deletePart(part)
      // Детали наследуют дату и пробег ремонта; новые ставятся на учёт и заменяют предыдущие на той же позиции
      for (const d of partDrafts) {
        const values = { ...draftValues(d), installDate: record.date, installMileage: record.mileage }
        if (d.part) {
          await db.parts.update(d.part.id, values)
        } else {
          await registerInstallation({ id: newId(), ...values, isActive: 1, repairId: record.id, carId })
        }
      }
      await syncExpense(record)
    })
    await updateMileage(carId, record.mileage)
    onClose()
  }

  return (
    <Sheet
      title={repair ? 'Редактирование' : 'Новый ремонт'}
      onClose={onClose}
      footer={<PrimaryButton disabled={!valid} onClick={save}>Сохранить</PrimaryButton>}
    >
      <div className="space-y-2.5">
        <FieldRow label="Что сделано">
          <FieldInput autoFocus={!repair} placeholder="Замена топливного насоса" value={title} onChange={e => setTitle(e.target.value)} />
        </FieldRow>

        <FieldLabel>КАТЕГОРИЯ</FieldLabel>
        <div className="grid grid-cols-4 gap-2">
          {REPAIR_CATEGORIES.map(c => {
            const Icon = repairIcon[c]
            const { color, title: t } = repairCategoryInfo[c]
            const selected = c === category
            return (
              <button
                key={c}
                type="button"
                onClick={() => setCategory(c)}
                className={cx('flex h-[68px] flex-col items-center justify-center gap-1.5 rounded-2xl border transition active:scale-95',
                  selected ? '' : 'border-stroke bg-card')}
                style={selected ? { borderColor: color, background: `${color}33` } : undefined}
              >
                <Icon size={20} style={{ color }} strokeWidth={2.3} />
                <span className={cx('w-full truncate px-1 text-[11px] font-medium', selected ? 'text-text' : 'text-text-2')}>{t}</span>
              </button>
            )
          })}
        </div>

        <FieldLabel>КОГДА</FieldLabel>
        <FieldRow label="Дата ремонта">
          <input type="date" value={date} onChange={e => setDate(e.target.value)} className="text-right" />
        </FieldRow>
        <FieldRow label="Пробег">
          <FieldInput inputMode="numeric" placeholder="0" value={mileage} onChange={e => setMileage(e.target.value)} />
          <span className="text-text-2">км</span>
        </FieldRow>

        <FieldLabel>РАБОТЫ И ЗАПЧАСТИ</FieldLabel>
        <TextArea placeholder="Выполненные работы" value={worksDone} onChange={e => setWorksDone(e.target.value)} />
        <TextArea rows={2} placeholder="Использованные запчасти и материалы" value={partsUsed} onChange={e => setPartsUsed(e.target.value)} />

        <FieldLabel>ЗАМЕНЁННЫЕ ДЕТАЛИ</FieldLabel>
        <div className="overflow-hidden rounded-card border border-stroke bg-card">
          {partDrafts.map(d => {
            const Icon = repairIcon[d.category]
            const v = draftValues(d)
            return (
              <div key={d.key} className="flex min-h-[58px] items-center gap-3 border-b border-stroke px-4">
                <button type="button" onClick={() => setEditing(d)} className="flex min-w-0 flex-1 items-center gap-3 py-2 text-left">
                  <Icon size={18} style={{ color: repairCategoryInfo[d.category].color }} className="shrink-0" />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate">{v.name}</span>
                    <span className="block truncate text-xs text-text-3">
                      {[v.manufacturer, `ресурс ${draftResource(d)}`].filter(Boolean).join(' · ')}
                    </span>
                  </span>
                  {v.purchasePrice > 0 && <span className="text-sm text-text-2">{rub(v.purchasePrice)}</span>}
                </button>
                <button type="button" onClick={() => removeDraft(d)} aria-label="Убрать деталь" className="text-danger">
                  <CircleMinus size={20} />
                </button>
              </div>
            )
          })}
          <button
            type="button"
            onClick={() => setEditing(newPartDraft(category))}
            className="flex h-13 w-full items-center gap-2.5 px-4 font-semibold text-accent"
          >
            <CirclePlus size={20} /> Добавить деталь
          </button>
        </div>
        <p className="px-1 text-[11px] text-text-3">
          Для каждой детали отслеживается ресурс. Ранее установленная деталь с тем же названием снимается с учёта и попадает в историю замен.
        </p>

        <FieldLabel>СТОИМОСТЬ</FieldLabel>
        <FieldRow label="Работы">
          <FieldInput inputMode="decimal" placeholder="0" value={labor} onChange={e => setLabor(e.target.value)} />
          <span className="text-text-2">₽</span>
        </FieldRow>
        <FieldRow label="Запчасти">
          {draftsTotal > 0 && partsValue === 0 && (
            <button type="button" onClick={() => setPartsCost(grouped(draftsTotal))} className="text-xs font-semibold text-accent">
              = {rub(draftsTotal)}
            </button>
          )}
          <FieldInput inputMode="decimal" placeholder="0" value={partsCost} onChange={e => setPartsCost(e.target.value)} />
          <span className="text-text-2">₽</span>
        </FieldRow>
        <div className="flex items-center justify-between px-1 pt-1">
          <span>Общая стоимость</span>
          <span className="font-rounded text-lg font-bold text-accent">{rub(laborValue + partsValue)}</span>
        </div>

        <FieldLabel>ИСПОЛНИТЕЛЬ</FieldLabel>
        <FieldRow label="СТО">
          <FieldInput placeholder="СТО или мастер" value={shop} onChange={e => setShop(e.target.value)} />
        </FieldRow>
        <TextArea rows={2} placeholder="Комментарий" value={comment} onChange={e => setComment(e.target.value)} />

        <FieldLabel>ФОТО</FieldLabel>
        <div className="grid grid-cols-2 gap-3">
          <PhotoPicker title="До ремонта" photo={photoBefore} onChange={setPhotoBefore} />
          <PhotoPicker title="После ремонта" photo={photoAfter} onChange={setPhotoAfter} />
        </div>
      </div>

      {editing && (
        <PartFormSheet draft={editing} onSave={upsertDraft} onClose={() => setEditing(undefined)} />
      )}
    </Sheet>
  )
}

const PhotoPicker = ({ title, photo, onChange }: { title: string; photo?: Blob; onChange: (b?: Blob) => void }) => {
  const url = useObjectURL(photo)
  return (
    <div className="relative">
      <label
        className={cx('flex h-[120px] cursor-pointer flex-col items-center justify-center gap-2 overflow-hidden rounded-card bg-card',
          url ? 'border border-stroke' : 'border border-dashed border-accent/40')}
      >
        {url ? <img src={url} alt={title} className="size-full object-cover" /> : (
          <>
            <Camera size={24} className="text-accent" />
            <span className="text-xs font-medium text-text-2">{title}</span>
          </>
        )}
        <input
          type="file" accept="image/*" hidden
          onChange={async e => {
            const file = e.target.files?.[0]
            if (file) onChange(await downscaleImage(file))
          }}
        />
      </label>
      {url && (
        <button type="button" onClick={() => onChange(undefined)} aria-label="Убрать фото"
          className="absolute right-1.5 top-1.5 flex size-7 items-center justify-center rounded-full bg-black/60 text-white">
          <X size={14} />
        </button>
      )}
    </div>
  )
}
