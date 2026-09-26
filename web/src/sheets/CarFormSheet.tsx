import { Camera, X } from 'lucide-react'
import { useState, type ChangeEvent } from 'react'
import { CarImage } from '@/components/rows'
import { Sheet } from '@/components/Sheet'
import { FieldInput, FieldLabel, FieldRow, PrimaryButton } from '@/components/ui'
import type { Car } from '@/models/types'
import { db } from '@/services/db'
import { addCar, updateMileage } from '@/services/dataService'
import { parseNumber } from '@/services/formatters'
import { downscaleImage } from '@/services/images'

// MARK: - Состояние формы

export const useCarDraft = (car?: Car) => {
  const [f, setF] = useState({
    make: car?.make ?? '', model: car?.model ?? '', bodyCode: car?.bodyCode ?? '',
    year: car ? String(car.year) : '', engine: car?.engine ?? '', vin: car?.vin ?? '',
    plate: car?.plate ?? '', mileage: car ? String(car.mileage) : '',
  })
  const [photo, setPhoto] = useState<Blob | undefined>(car?.photo)
  const year = Number(f.year)
  const valid = f.make.trim() !== '' && f.model.trim() !== ''
    && Number.isInteger(year) && year >= 1900 && year <= new Date().getFullYear() + 1

  const set = (key: keyof typeof f) => (e: ChangeEvent<HTMLInputElement>) => setF(prev => ({ ...prev, [key]: e.target.value }))

  /** Создаёт новый автомобиль или сохраняет изменения; возвращает id */
  const save = async (): Promise<string> => {
    const fields = {
      make: f.make.trim(), model: f.model.trim(), bodyCode: f.bodyCode.trim(), year,
      engine: f.engine.trim(), vin: f.vin.trim().toUpperCase(), plate: f.plate.trim().toUpperCase(), photo,
    }
    const mileage = Math.round(parseNumber(f.mileage) ?? 0)
    if (!car) return (await addCar({ ...fields, mileage })).id
    await db.cars.update(car.id, fields)
    // Ручная корректировка может и уменьшить пробег
    if (mileage) await updateMileage(car.id, mileage, false)
    return car.id
  }

  return { f, set, photo, setPhoto, valid, save }
}

export type CarDraft = ReturnType<typeof useCarDraft>

// MARK: - Поля

export const CarFields = ({ draft }: { draft: CarDraft }) => {
  const { f, set, photo, setPhoto } = draft
  return (
    <div className="space-y-2.5">
      <div className="relative h-40 overflow-hidden rounded-card border border-stroke bg-linear-to-b from-elevated to-card">
        <CarImage photo={photo} className={photo ? 'size-full' : 'size-full px-10 pt-2'} />
        <label className="absolute bottom-2.5 right-2.5 flex cursor-pointer items-center gap-1.5 rounded-full bg-black/60 px-3 py-2 text-xs font-semibold backdrop-blur">
          <Camera size={14} /> {photo ? 'Сменить фото' : 'Добавить фото'}
          <input type="file" accept="image/*" hidden onChange={async e => {
            const file = e.target.files?.[0]
            if (file) setPhoto(await downscaleImage(file))
          }} />
        </label>
        {photo && (
          <button type="button" onClick={() => setPhoto(undefined)} aria-label="Убрать фото"
            className="absolute right-2.5 top-2.5 flex size-7 items-center justify-center rounded-full bg-black/60">
            <X size={14} />
          </button>
        )}
      </div>

      <FieldLabel>ОСНОВНОЕ</FieldLabel>
      <FieldRow label="Марка"><FieldInput placeholder="Toyota" value={f.make} onChange={set('make')} /></FieldRow>
      <FieldRow label="Модель"><FieldInput placeholder="Aristo" value={f.model} onChange={set('model')} /></FieldRow>
      <FieldRow label="Год"><FieldInput inputMode="numeric" placeholder="1998" value={f.year} onChange={set('year')} /></FieldRow>
      <FieldRow label="Кузов"><FieldInput placeholder="JZS160" value={f.bodyCode} onChange={set('bodyCode')} /></FieldRow>
      <FieldRow label="Двигатель"><FieldInput placeholder="2JZ-GE" value={f.engine} onChange={set('engine')} /></FieldRow>
      <FieldRow label="Пробег">
        <FieldInput inputMode="numeric" placeholder="0" value={f.mileage} onChange={set('mileage')} />
        <span className="text-text-2">км</span>
      </FieldRow>
      <FieldLabel>ДОКУМЕНТЫ (НЕОБЯЗАТЕЛЬНО)</FieldLabel>
      <FieldRow label="VIN / номер кузова"><FieldInput value={f.vin} onChange={set('vin')} /></FieldRow>
      <FieldRow label="Госномер"><FieldInput placeholder="А123БВ 77" value={f.plate} onChange={set('plate')} /></FieldRow>
    </div>
  )
}

// MARK: - Шторка

/** Новый автомобиль или редактирование существующего */
export const CarFormSheet = ({ car, onSaved, onClose }: {
  car?: Car
  onSaved?: (id: string) => void
  onClose: () => void
}) => {
  const draft = useCarDraft(car)
  const submit = async () => {
    if (!draft.valid) return
    const id = await draft.save()
    onSaved?.(id)
    onClose()
  }
  return (
    <Sheet
      title={car ? 'Автомобиль' : 'Новый автомобиль'}
      onClose={onClose}
      footer={<PrimaryButton disabled={!draft.valid} onClick={submit}>{car ? 'Сохранить' : 'Добавить автомобиль'}</PrimaryButton>}
    >
      <CarFields draft={draft} />
    </Sheet>
  )
}
