import { useLiveQuery } from 'dexie-react-hooks'
import { ChevronRight, MessageSquare, Pencil, Trash } from 'lucide-react'
import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Page, PageHeader } from '@/components/AppShell'
import { RepairBadge } from '@/components/rows'
import { ConfirmDialog } from '@/components/Sheet'
import { Card, Divider, InfoRow, ProgressBar, StatusPill } from '@/components/ui'
import {
  nextServiceDescription, progress, remainingDays, remainingKm, resourceDescription, status, statusInfo, statusTitle,
  trackPart, traveledKm,
} from '@/models/serviceTracking'
import { repairCategoryInfo, repairTotal, type Part } from '@/models/types'
import { db } from '@/services/db'
import { deletePart, replacementHistory } from '@/services/dataService'
import { dateShort, days, km, rub } from '@/services/formatters'
import { PartFormSheet, draftFromPart, draftValues } from '@/sheets/PartFormSheet'
import { useCar, usePart, useRepair } from '@/viewmodels/useData'

export const PartDetailPage = () => {
  const { id } = useParams()
  const part = usePart(id)
  const repair = useRepair(part?.repairId)
  const history = useLiveQuery(() => (part ? replacementHistory(part) : []), [part]) ?? []
  const mileage = useCar()?.mileage ?? 0
  const navigate = useNavigate()
  const [editing, setEditing] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)

  if (!part) return <PageHeader title="" back="/garage/parts" />

  const t = trackPart(part)
  const active = part.isActive === 1
  const s = status(t, mileage)
  const color = statusInfo[s].color
  // Для снятой детали ресурс считается на момент снятия
  const atMileage = part.removedMileage ?? mileage
  const atDate = part.removedDate ?? Date.now()
  const served = (p: Part) => km(Math.max(0, (p.removedMileage ?? 0) - p.installMileage))

  const remainingHeadline = () => {
    if (s === 'overdue') return t.overdueTitle
    const k = remainingKm(t, mileage)
    if (k !== undefined) return km(k)
    const d = remainingDays(t)
    return d !== undefined ? days(d) : '—'
  }

  return (
    <>
      <PageHeader
        title=""
        back="/garage/parts"
        actions={
          <div className="flex gap-2">
            <button type="button" onClick={() => setEditing(true)} aria-label="Изменить"
              className="flex size-10 items-center justify-center rounded-full border border-stroke bg-card text-accent hover:bg-elevated">
              <Pencil size={18} />
            </button>
            <button type="button" onClick={() => setConfirmDelete(true)} aria-label="Удалить"
              className="flex size-10 items-center justify-center rounded-full border border-stroke bg-card text-danger hover:bg-elevated">
              <Trash size={18} />
            </button>
          </div>
        }
      />
      <Page className="max-w-3xl">
        <div className="flex flex-col items-center gap-2.5 py-2 text-center">
          <RepairBadge category={part.category} size={64} />
          <h1 className="font-rounded text-2xl font-bold">{part.name}</h1>
          <div className="flex gap-2">
            <StatusPill text={repairCategoryInfo[part.category].title} color={repairCategoryInfo[part.category].color} />
            {active ? <StatusPill text={statusTitle(t, mileage)} color={color} /> : <StatusPill text="Снята" color="var(--color-text-2)" />}
          </div>
        </div>

        <Card padding="p-5" className="space-y-3.5">
          <div>
            <div className="text-xs text-text-2">{active ? 'Остаток ресурса' : 'Прослужила'}</div>
            <div className="font-rounded text-3xl font-bold" style={{ color: active ? color : undefined }}>
              {active ? remainingHeadline() : served(part)}
            </div>
          </div>
          <ProgressBar value={progress(t, atMileage, atDate)} color={active ? color : 'var(--color-text-3)'} height={10} />
          <div className="flex justify-between">
            <Metric title="Пройдено" value={km(traveledKm(t, atMileage))} />
            <Metric title="Ресурс" value={resourceDescription(t)} right />
          </div>
        </Card>

        <Card className="space-y-2.5">
          <InfoRow title="Производитель" value={part.manufacturer || '—'} />
          <InfoRow title="Артикул" value={part.articleNumber || '—'} />
          <Divider />
          <InfoRow title="Дата установки" value={dateShort(part.installDate)} />
          <InfoRow title="Пробег установки" value={km(part.installMileage)} />
          <InfoRow title="Ресурс" value={resourceDescription(t)} />
          {active ? (
            <>
              <InfoRow title="Текущий пробег" value={km(mileage)} />
              <InfoRow title="Остаток" value={remainingHeadline()} />
              <InfoRow title="Следующая замена" value={nextServiceDescription(t)} />
            </>
          ) : part.removedDate && (
            <InfoRow title="Снята" value={`${dateShort(part.removedDate)} · ${km(part.removedMileage ?? 0)}`} />
          )}
          {part.purchasePrice > 0 && (<><Divider /><InfoRow title="Цена" value={rub(part.purchasePrice)} /></>)}
        </Card>

        {part.notes && (
          <Card className="space-y-2">
            <div className="flex items-center gap-2 text-sm font-semibold text-accent"><MessageSquare size={16} /> Заметки</div>
            <p className="whitespace-pre-line">{part.notes}</p>
          </Card>
        )}

        {repair && (
          <section className="space-y-2.5">
            <h2 className="text-lg font-bold">Связанный ремонт</h2>
            <Link to={`/garage/repairs/${repair.id}`} className="block">
              <Card padding="p-3.5" className="flex items-center gap-3 hover:bg-elevated">
                <RepairBadge category={repair.category} />
                <div className="min-w-0 flex-1">
                  <div className="truncate font-semibold">{repair.title}</div>
                  <div className="truncate text-xs text-text-2">{dateShort(repair.date)} · {repair.shop || km(repair.mileage)}</div>
                </div>
                <span className="text-sm font-semibold">{rub(repairTotal(repair))}</span>
                <ChevronRight size={16} className="text-text-3" />
              </Card>
            </Link>
          </section>
        )}

        <section className="space-y-2.5">
          <h2 className="text-lg font-bold">История замен</h2>
          <Card padding="px-4 py-1">
            {history.map((item, i) => {
              const row = (
                <div className="flex items-start gap-3 py-3">
                  <span className={`mt-1.5 size-2.5 shrink-0 rounded-full ${item.isActive ? 'bg-accent' : 'bg-text-3'}`} />
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold">{dateShort(item.installDate)} · {km(item.installMileage)}</div>
                    <div className="truncate text-xs text-text-2">{[item.manufacturer, item.articleNumber].filter(Boolean).join(' · ')}</div>
                    <div className={`text-xs font-medium ${item.isActive ? 'text-accent' : 'text-text-3'}`}>
                      {item.isActive ? 'Установлена сейчас' : `Прослужила ${served(item)}`}
                    </div>
                  </div>
                  {item.id !== part.id && <ChevronRight size={16} className="mt-1 text-text-3" />}
                </div>
              )
              return (
                <div key={item.id}>
                  {item.id === part.id ? row : <Link to={`/garage/parts/${item.id}`} className="block hover:opacity-85">{row}</Link>}
                  {i < history.length - 1 && <Divider inset={22} />}
                </div>
              )
            })}
            {history.length === 1 && (
              <p className="pb-3 text-xs text-text-3">Это первая деталь на этой позиции. При следующей замене здесь появится история.</p>
            )}
          </Card>
        </section>
      </Page>

      {editing && (
        <PartFormSheet
          draft={draftFromPart(part)}
          onSave={d => db.parts.update(part.id, draftValues(d))}
          onClose={() => setEditing(false)}
        />
      )}
      {confirmDelete && (
        <ConfirmDialog
          title="Удалить деталь?"
          message={part.replacesId && active ? 'Предыдущая деталь на этой позиции снова станет активной.' : 'Деталь будет удалена из ремонта и истории.'}
          onConfirm={async () => { await deletePart(part); navigate('/garage/parts', { replace: true }) }}
          onCancel={() => setConfirmDelete(false)}
        />
      )}
    </>
  )
}

const Metric = ({ title, value, right }: { title: string; value: string; right?: boolean }) => (
  <div className={right ? 'text-right' : ''}>
    <div className="text-xs text-text-3">{title}</div>
    <div className="text-sm font-semibold">{value}</div>
  </div>
)
