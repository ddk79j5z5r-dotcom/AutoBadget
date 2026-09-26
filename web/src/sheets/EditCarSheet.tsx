import { useState, type ChangeEvent } from 'react'
import { Sheet } from '@/components/Sheet'
import { FieldInput, FieldLabel, FieldRow, PrimaryButton } from '@/components/ui'
import type { Car } from '@/models/types'
import { db } from '@/services/db'
import { updateMileage } from '@/services/dataService'
import { parseNumber } from '@/services/formatters'

export const EditCarSheet = ({ car, onClose }: { car: Car; onClose: () => void }) => {
  const [f, setF] = useState({
    make: car.make, model: car.model, bodyCode: car.bodyCode, year: String(car.year),
    engine: car.engine, vin: car.vin, plate: car.plate, mileage: String(car.mileage),
  })
  const set = (key: keyof typeof f) => (e: ChangeEvent<HTMLInputElement>) => setF(prev => ({ ...prev, [key]: e.target.value }))
  const valid = f.make.trim() !== '' && f.model.trim() !== '' && Number.isInteger(Number(f.year))

  const save = async () => {
    if (!valid) return
    await db.cars.update(car.id, {
      make: f.make.trim(), model: f.model.trim(), bodyCode: f.bodyCode.trim(), year: Number(f.year),
      engine: f.engine.trim(), vin: f.vin.trim().toUpperCase(), plate: f.plate.trim().toUpperCase(),
    })
    // Ручная корректировка может и уменьшить пробег
    const km = parseNumber(f.mileage)
    if (km) await updateMileage(Math.round(km), false)
    onClose()
  }

  return (
    <Sheet title="Автомобиль" onClose={onClose} footer={<PrimaryButton disabled={!valid} onClick={save}>Сохранить</PrimaryButton>}>
      <div className="space-y-2.5">
        <FieldLabel>ОСНОВНОЕ</FieldLabel>
        <FieldRow label="Марка"><FieldInput value={f.make} onChange={set('make')} /></FieldRow>
        <FieldRow label="Модель"><FieldInput value={f.model} onChange={set('model')} /></FieldRow>
        <FieldRow label="Год"><FieldInput inputMode="numeric" value={f.year} onChange={set('year')} /></FieldRow>
        <FieldRow label="Кузов"><FieldInput placeholder="JZS160" value={f.bodyCode} onChange={set('bodyCode')} /></FieldRow>
        <FieldRow label="Двигатель"><FieldInput value={f.engine} onChange={set('engine')} /></FieldRow>
        <FieldLabel>ДОКУМЕНТЫ</FieldLabel>
        <FieldRow label="VIN / номер кузова"><FieldInput value={f.vin} onChange={set('vin')} /></FieldRow>
        <FieldRow label="Госномер"><FieldInput placeholder="А160РС 178" value={f.plate} onChange={set('plate')} /></FieldRow>
        <FieldLabel>ПРОБЕГ</FieldLabel>
        <FieldRow label="Текущий пробег">
          <FieldInput inputMode="numeric" value={f.mileage} onChange={set('mileage')} />
          <span className="text-text-2">км</span>
        </FieldRow>
      </div>
    </Sheet>
  )
}
