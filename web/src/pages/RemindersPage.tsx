import { Bell, BellOff, Check, Plus } from 'lucide-react'
import { useMemo, useState } from 'react'
import { IconButton, Page, PageHeader } from '@/components/AppShell'
import { NotificationBanner } from '@/components/controls'
import { reminderIcon } from '@/components/icons'
import { Card, EmptyState, InfoRow, ProgressBar, StatusPill, SymbolBadge } from '@/components/ui'
import {
  nextServiceDescription, progress, remainingDescription, resourceDescription, status, statusInfo, statusTitle,
  trackReminder, type ServiceStatus,
} from '@/models/serviceTracking'
import type { Reminder } from '@/models/types'
import { db } from '@/services/db'
import { dateShort, km } from '@/services/formatters'
import { ReminderSheet } from '@/sheets/ReminderSheet'
import { useCar, useReminders } from '@/viewmodels/useData'

export const RemindersPage = () => {
  const reminders = useReminders()
  const mileage = useCar()?.mileage ?? 0
  const [editing, setEditing] = useState<Reminder>()
  const [adding, setAdding] = useState(false)

  const sorted = useMemo(
    () => [...reminders].sort((a, b) => progress(trackReminder(b), mileage) - progress(trackReminder(a), mileage)),
    [reminders, mileage],
  )
  const statuses = reminders.map(r => status(trackReminder(r), mileage))
  const count = (...s: ServiceStatus[]) => statuses.filter(x => s.includes(x)).length

  return (
    <>
      <PageHeader title="Напоминания" back="/garage" actions={<IconButton icon={Plus} label="Добавить" onClick={() => setAdding(true)} />} />
      <Page className="max-w-3xl">
        <NotificationBanner message="Напомним об ОСАГО, техосмотре и регламентных работах заранее." />
        <div className="grid grid-cols-3 gap-2.5">
          <Summary value={count('overdue')} title="Просрочено" color={statusInfo.overdue.color} />
          <Summary value={count('warning', 'critical')} title="Скоро" color={statusInfo.warning.color} />
          <Summary value={count('ok')} title="В норме" color={statusInfo.ok.color} />
        </div>
        {reminders.length === 0 && <EmptyState icon={Bell} title="Нет напоминаний" message="Добавьте первое кнопкой «+»" />}
        {sorted.map(r => <ReminderCard key={r.id} reminder={r} mileage={mileage} onEdit={() => setEditing(r)} />)}
      </Page>
      {(adding || editing) && (
        <ReminderSheet
          reminder={editing}
          currentMileage={mileage}
          onClose={() => { setAdding(false); setEditing(undefined) }}
        />
      )}
    </>
  )
}

const Summary = ({ value, title, color }: { value: number; title: string; color: string }) => (
  <Card padding="p-3" className="text-center">
    <div className="font-rounded text-2xl font-bold" style={{ color }}>{value}</div>
    <div className="text-xs text-text-2">{title}</div>
  </Card>
)

const ReminderCard = ({ reminder, mileage, onEdit }: { reminder: Reminder; mileage: number; onEdit: () => void }) => {
  const t = trackReminder(reminder)
  const s = status(t, mileage)
  const color = statusInfo[s].color

  const markDone = () => db.reminders.update(reminder.id, { lastDate: Date.now(), lastMileage: mileage })
  const toggle = () => db.reminders.update(reminder.id, { notificationsEnabled: !reminder.notificationsEnabled })

  return (
    <Card className="space-y-3.5">
      <button type="button" onClick={onEdit} className="flex w-full items-center gap-3 text-left">
        <SymbolBadge icon={reminderIcon[reminder.kind]} color={color} />
        <div className="min-w-0 flex-1">
          <div className="font-semibold">{reminder.title}</div>
          <div className="text-xs" style={{ color }}>{remainingDescription(t, mileage)}</div>
        </div>
        <StatusPill text={statusTitle(t, mileage)} color={color} />
      </button>
      <ProgressBar value={progress(t, mileage)} color={color} height={8} />
      <div className="space-y-1.5">
        <InfoRow title="Последний раз" value={`${dateShort(reminder.lastDate)} · ${km(reminder.lastMileage)}`} />
        <InfoRow title="Следующий" value={nextServiceDescription(t)} />
        <InfoRow title="Интервал" value={resourceDescription(t)} />
      </div>
      <div className="flex gap-2.5">
        <button type="button" onClick={markDone}
          className="flex h-10 flex-1 items-center justify-center gap-1.5 rounded-xl bg-accent text-sm font-semibold text-black transition active:scale-[0.98]">
          <Check size={16} strokeWidth={3} /> Выполнено
        </button>
        <button type="button" onClick={toggle}
          aria-label={reminder.notificationsEnabled ? 'Выключить уведомления' : 'Включить уведомления'}
          className={`flex h-10 w-12 items-center justify-center rounded-xl bg-elevated ${reminder.notificationsEnabled ? 'text-accent' : 'text-text-3'}`}>
          {reminder.notificationsEnabled ? <Bell size={17} /> : <BellOff size={17} />}
        </button>
      </div>
    </Card>
  )
}
