import { useState } from 'react'
import { Sheet } from '@/components/Sheet'
import { ChipBar, FieldInput, FieldLabel, FieldRow, FilterChip, PrimaryButton, TextArea } from '@/components/ui'
import { PART_TEMPLATES } from '@/models/partTemplates'
import { REPAIR_CATEGORIES, repairCategoryInfo, type Part, type RepairCategory } from '@/models/types'
import { grouped, parseNumber, resource } from '@/services/formatters'

/**
 * Состояние формы детали. Живёт до сохранения ремонта: записи Part создаются
 * только в момент сохранения, чтобы отмена формы ничего не оставляла в базе.
 */
export interface PartDraft {
  key: string
  /** Уже сохранённая деталь — при редактировании */
  part?: Part
  name: string
  category: RepairCategory
  manufacturer: string
  articleNumber: string
  lifeKm: string
  lifeMonths: string
  price: string
  notes: string
}

export const newPartDraft = (category: RepairCategory): PartDraft => ({
  key: crypto.randomUUID(), name: '', category, manufacturer: '', articleNumber: '',
  lifeKm: '', lifeMonths: '', price: '', notes: '',
})

export const draftFromPart = (part: Part): PartDraft => ({
  key: part.id,
  part,
  name: part.name,
  category: part.category,
  manufacturer: part.manufacturer,
  articleNumber: part.articleNumber,
  lifeKm: part.serviceLifeKm ? String(part.serviceLifeKm) : '',
  lifeMonths: part.serviceLifeMonths ? String(part.serviceLifeMonths) : '',
  price: part.purchasePrice ? grouped(part.purchasePrice) : '',
  notes: part.notes,
})

export const draftValues = (d: PartDraft) => ({
  name: d.name.trim(),
  category: d.category,
  manufacturer: d.manufacturer.trim(),
  articleNumber: d.articleNumber.trim(),
  serviceLifeKm: Math.round(parseNumber(d.lifeKm) ?? 0),
  serviceLifeMonths: Math.round(parseNumber(d.lifeMonths) ?? 0),
  purchasePrice: parseNumber(d.price) ?? 0,
  notes: d.notes,
})

/** Без ресурса деталь нечего отслеживать */
export const isDraftValid = (d: PartDraft) => {
  const v = draftValues(d)
  return v.name !== '' && (v.serviceLifeKm > 0 || v.serviceLifeMonths > 0)
}

export const draftResource = (d: PartDraft) => {
  const v = draftValues(d)
  return resource(v.serviceLifeKm, v.serviceLifeMonths)
}

/** Шторка детали: новая деталь в ремонте или редактирование существующей */
export const PartFormSheet = ({ draft: initial, onSave, onClose }: {
  draft: PartDraft
  onSave: (d: PartDraft) => void
  onClose: () => void
}) => {
  const [d, setD] = useState(initial)
  const set = <K extends keyof PartDraft>(key: K, value: PartDraft[K]) => setD(prev => ({ ...prev, [key]: value }))
  const valid = isDraftValid(d)

  const save = () => {
    if (!valid) return
    onSave(d)
    onClose()
  }

  return (
    <Sheet
      title={d.part ? 'Деталь' : 'Новая деталь'}
      onClose={onClose}
      footer={<PrimaryButton disabled={!valid} onClick={save}>Сохранить</PrimaryButton>}
    >
      <form className="space-y-2.5" onSubmit={e => { e.preventDefault(); save() }}>
        {!d.part && (
          <>
            <FieldLabel>ТИПОВЫЕ ДЕТАЛИ</FieldLabel>
            <ChipBar>
              {PART_TEMPLATES.map(t => (
                <FilterChip
                  key={t.name}
                  title={t.name}
                  selected={d.name === t.name}
                  onClick={() => setD(prev => ({
                    ...prev, name: t.name, category: t.category,
                    lifeKm: t.lifeKm ? String(t.lifeKm) : '', lifeMonths: t.lifeMonths ? String(t.lifeMonths) : '',
                  }))}
                />
              ))}
            </ChipBar>
            <div className="h-1" />
          </>
        )}
        <FieldRow label="Название">
          <FieldInput placeholder="Передние колодки" value={d.name} onChange={e => set('name', e.target.value)} />
        </FieldRow>
        <FieldRow label="Категория">
          <select
            value={d.category}
            onChange={e => set('category', e.target.value as RepairCategory)}
            className="cursor-pointer text-right font-medium text-accent"
          >
            {REPAIR_CATEGORIES.map(c => <option key={c} value={c} className="bg-card text-text">{repairCategoryInfo[c].title}</option>)}
          </select>
        </FieldRow>
        <FieldRow label="Производитель">
          <FieldInput placeholder="Akebono" value={d.manufacturer} onChange={e => set('manufacturer', e.target.value)} />
        </FieldRow>
        <FieldRow label="Артикул">
          <FieldInput placeholder="AN-690WK" value={d.articleNumber} autoCapitalize="characters"
            onChange={e => set('articleNumber', e.target.value)} />
        </FieldRow>

        <FieldLabel>Ресурс — укажите пробег, срок или оба значения</FieldLabel>
        <FieldRow label="По пробегу">
          <FieldInput inputMode="numeric" placeholder="30000" value={d.lifeKm} onChange={e => set('lifeKm', e.target.value)} />
          <span className="text-text-2">км</span>
        </FieldRow>
        <FieldRow label="По времени">
          <FieldInput inputMode="numeric" placeholder="—" value={d.lifeMonths} onChange={e => set('lifeMonths', e.target.value)} />
          <span className="text-text-2">мес.</span>
        </FieldRow>
        <FieldRow label="Цена">
          <FieldInput inputMode="decimal" placeholder="0" value={d.price} onChange={e => set('price', e.target.value)} />
          <span className="text-text-2">₽</span>
        </FieldRow>

        <FieldLabel>Заметки</FieldLabel>
        <TextArea placeholder="Например: оригинал, гарантия 1 год" value={d.notes} onChange={e => set('notes', e.target.value)} />
        <button type="submit" hidden />
      </form>
    </Sheet>
  )
}
