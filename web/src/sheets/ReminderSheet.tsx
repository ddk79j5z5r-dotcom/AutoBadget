import { Trash } from 'lucide-react'
import { useState } from 'react'
import { ConfirmDialog, Sheet } from '@/components/Sheet'
import { ChipBar, DangerButton, FieldInput, FieldLabel, FieldRow, FilterChip, PrimaryButton } from '@/components/ui'
import { REMINDER_KINDS, newId, reminderKindInfo, type Reminder, type ReminderKind } from '@/models/types'
import { db } from '@/services/db'
import { days, fromDateInput, parseNumber, toDateInput } from '@/services/formatters'
import { useCar } from '@/viewmodels/useData'

const text = (n: number) => (n > 0 ? String(n) : '')

/** Новое напоминание / редактирование — порт ReminderEditView + ReminderEditViewModel */
export const ReminderSheet = ({ reminder, onClose }: {
  reminder?: Reminder
  onClose: () => void
}) => {
  const car = useCar()
  const carId = reminder?.carId ?? car?.id
  const currentMileage = car?.mileage ?? 0
  const [kind, setKind] = useState<ReminderKind>(reminder?.kind ?? 'custom')
  const [title, setTitle] = useState(reminder?.title ?? reminderKindInfo.custom.title)
  const [intervalKm, setIntervalKm] = useState(text(reminder?.intervalKm ?? reminderKindInfo.custom.intervalKm))
  const [intervalMonths, setIntervalMonths] = useState(text(reminder?.intervalMonths ?? reminderKindInfo.custom.intervalMonths))
  const [lastDate, setLastDate] = useState(toDateInput(reminder?.lastDate ?? Date.now()))
  const [lastMileage, setLastMileage] = useState(String(reminder?.lastMileage ?? currentMileage))
  const [notify, setNotify] = useState(reminder?.notificationsEnabled ?? true)
  const [notifyDays, setNotifyDays] = useState(reminder?.notifyDaysBefore ?? 7)
  const [confirmDelete, setConfirmDelete] = useState(false)

  const km = Math.round(parseNumber(intervalKm) ?? 0)
  const months = Math.round(parseNumber(intervalMonths) ?? 0)
  const valid = title.trim() !== '' && (km > 0 || months > 0) && !!carId

  const changeKind = (k: ReminderKind) => {
    if (!title || title === reminderKindInfo[kind].title) setTitle(reminderKindInfo[k].title)
    setIntervalKm(text(reminderKindInfo[k].intervalKm))
    setIntervalMonths(text(reminderKindInfo[k].intervalMonths))
    setKind(k)
  }

  const save = async () => {
    if (!valid || !carId) return
    await db.reminders.put({
      id: reminder?.id ?? newId(),
      carId,
      kind,
      title: title.trim(),
      intervalKm: km,
      intervalMonths: months,
      lastDate: fromDateInput(lastDate),
      lastMileage: Math.round(parseNumber(lastMileage) ?? 0),
      notificationsEnabled: notify,
      notifyDaysBefore: notifyDays,
    })
    onClose()
  }

  const remove = async () => {
    if (reminder) await db.reminders.delete(reminder.id)
    onClose()
  }

  return (
    <Sheet
      title={reminder ? 'Напоминание' : 'Новое напоминание'}
      onClose={onClose}
      footer={<PrimaryButton disabled={!valid} onClick={save}>Сохранить</PrimaryButton>}
    >
      <div className="space-y-2.5">
        <ChipBar>
          {REMINDER_KINDS.map(k => (
            <FilterChip key={k} title={reminderKindInfo[k].title} selected={k === kind} onClick={() => changeKind(k)} />
          ))}
        </ChipBar>
        <FieldRow label="Название">
          <FieldInput value={title} onChange={e => setTitle(e.target.value)} />
        </FieldRow>

        <FieldLabel>ИНТЕРВАЛ</FieldLabel>
        <FieldRow label="Каждые">
          <FieldInput inputMode="numeric" placeholder="—" value={intervalKm} onChange={e => setIntervalKm(e.target.value)} />
          <span className="text-text-2">км</span>
        </FieldRow>
        <FieldRow label="Каждые">
          <FieldInput inputMode="numeric" placeholder="—" value={intervalMonths} onChange={e => setIntervalMonths(e.target.value)} />
          <span className="text-text-2">мес.</span>
        </FieldRow>

        <FieldLabel>ПОСЛЕДНЕЕ ВЫПОЛНЕНИЕ</FieldLabel>
        <FieldRow label="Дата">
          <input type="date" value={lastDate} onChange={e => setLastDate(e.target.value)} className="text-right" />
        </FieldRow>
        <FieldRow label="Пробег">
          <FieldInput inputMode="numeric" value={lastMileage} onChange={e => setLastMileage(e.target.value)} />
          <span className="text-text-2">км</span>
        </FieldRow>

        <FieldLabel>УВЕДОМЛЕНИЯ</FieldLabel>
        <FieldRow label="Уведомлять">
          <input type="checkbox" checked={notify} onChange={e => setNotify(e.target.checked)} className="size-5 accent-[#00D4AA]" />
        </FieldRow>
        <FieldRow label="Заранее">
          <input
            type="range" min={1} max={60} value={notifyDays} disabled={!notify}
            onChange={e => setNotifyDays(Number(e.target.value))}
            className="w-32 accent-[#00D4AA] disabled:opacity-40"
          />
          <span className="w-16 text-right text-sm">{days(notifyDays)}</span>
        </FieldRow>

        {reminder && (
          <div className="pt-3">
            <DangerButton onClick={() => setConfirmDelete(true)}><Trash size={17} /> Удалить напоминание</DangerButton>
          </div>
        )}
      </div>
      {confirmDelete && (
        <ConfirmDialog title="Удалить напоминание?" onConfirm={remove} onCancel={() => setConfirmDelete(false)} />
      )}
    </Sheet>
  )
}
