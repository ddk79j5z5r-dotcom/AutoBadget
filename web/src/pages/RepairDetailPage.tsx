import { ChevronRight, Cog, Image as ImageIcon, MessageSquare, Package, Pencil, Trash, Wrench, type LucideIcon } from 'lucide-react'
import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Page, PageHeader } from '@/components/AppShell'
import { RepairBadge, useObjectURL } from '@/components/rows'
import { ConfirmDialog } from '@/components/Sheet'
import { Card, Divider, InfoRow, StatusPill } from '@/components/ui'
import { remainingDescription, status, statusInfo, statusTitle, trackPart } from '@/models/serviceTracking'
import { repairCategoryInfo, repairTotal } from '@/models/types'
import { deleteRepair } from '@/services/dataService'
import { dateShort, km, rub } from '@/services/formatters'
import { AddRepairSheet } from '@/sheets/AddRepairSheet'
import { useCar, usePartsOfRepair, useRepair } from '@/viewmodels/useData'

export const RepairDetailPage = () => {
  const { id } = useParams()
  const repair = useRepair(id)
  const parts = usePartsOfRepair(id)
  const car = useCar()
  const navigate = useNavigate()
  const [editing, setEditing] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [photo, setPhoto] = useState<string>()
  const mileage = car?.mileage ?? 0

  if (!repair) return <PageHeader title="" back="/garage/repairs" />

  return (
    <>
      <PageHeader
        title=""
        back="/garage/repairs"
        actions={
          <div className="flex gap-2">
            <HeaderButton icon={Pencil} label="Изменить" onClick={() => setEditing(true)} />
            <HeaderButton icon={Trash} label="Удалить" onClick={() => setConfirmDelete(true)} danger />
          </div>
        }
      />
      <Page className="max-w-3xl">
        <div className="flex flex-col items-center gap-2.5 py-2 text-center">
          <RepairBadge category={repair.category} size={64} />
          <h1 className="font-rounded text-2xl font-bold">{repair.title}</h1>
          <div className="flex gap-2">
            <StatusPill text={repairCategoryInfo[repair.category].title} color={repairCategoryInfo[repair.category].color} />
            <StatusPill text={dateShort(repair.date)} color="var(--color-text-2)" />
          </div>
        </div>

        <Card className="space-y-2.5">
          <InfoRow title="Работы" value={rub(repair.laborCost)} />
          <InfoRow title="Запчасти" value={rub(repair.partsCost)} />
          <Divider />
          <div className="flex items-center justify-between">
            <span className="font-semibold">Итого</span>
            <span className="font-rounded text-xl font-bold text-accent">{rub(repairTotal(repair))}</span>
          </div>
        </Card>

        {repair.worksDone && <TextCard icon={Wrench} title="Выполненные работы" text={repair.worksDone} />}

        {parts.length > 0 && (
          <Card className="space-y-1">
            <div className="flex items-center gap-2 pb-1 text-sm font-semibold text-accent"><Cog size={16} /> Заменённые детали</div>
            {parts.map(p => {
              const t = trackPart(p)
              const s = status(t, mileage)
              return (
                <Link key={p.id} to={`/garage/parts/${p.id}`} className="flex items-center gap-2.5 rounded-small py-2 transition hover:opacity-80">
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold">{p.name}</div>
                    <div className="text-xs text-text-2">
                      {p.isActive ? remainingDescription(t, mileage) : `Заменена · прослужила ${km(Math.max(0, (p.removedMileage ?? 0) - p.installMileage))}`}
                    </div>
                  </div>
                  {p.isActive === 1 && <StatusPill text={statusTitle(t, mileage)} color={statusInfo[s].color} />}
                  <ChevronRight size={16} className="text-text-3" />
                </Link>
              )
            })}
          </Card>
        )}

        {repair.partsUsed && <TextCard icon={Package} title="Использованные запчасти" text={repair.partsUsed} />}

        <Card className="space-y-2.5">
          <InfoRow title="Дата" value={dateShort(repair.date)} />
          <InfoRow title="Пробег" value={km(repair.mileage)} />
          {repair.shop && <InfoRow title="СТО / исполнитель" value={repair.shop} />}
        </Card>

        {(repair.photoBefore || repair.photoAfter) && (
          <Card className="space-y-2.5">
            <div className="flex items-center gap-2 text-sm font-semibold text-accent"><ImageIcon size={16} /> Фото</div>
            <div className="grid grid-cols-2 gap-2.5">
              <Photo blob={repair.photoBefore} label="До ремонта" onOpen={setPhoto} />
              <Photo blob={repair.photoAfter} label="После ремонта" onOpen={setPhoto} />
            </div>
          </Card>
        )}

        {repair.comment && <TextCard icon={MessageSquare} title="Комментарий" text={repair.comment} />}
      </Page>

      {editing && <AddRepairSheet repair={repair} onClose={() => setEditing(false)} />}
      {confirmDelete && (
        <ConfirmDialog
          title="Удалить запись о ремонте?"
          message="Связанный расход и заменённые детали тоже будут удалены."
          onConfirm={async () => { await deleteRepair(repair); navigate('/garage/repairs', { replace: true }) }}
          onCancel={() => setConfirmDelete(false)}
        />
      )}
      {photo && (
        <div className="animate-fade-in fixed inset-0 z-50 flex items-center justify-center bg-black p-4" onClick={() => setPhoto(undefined)}>
          <img src={photo} alt="" className="max-h-full max-w-full object-contain" />
        </div>
      )}
    </>
  )
}

const HeaderButton = ({ icon: Icon, label, onClick, danger }: { icon: LucideIcon; label: string; onClick: () => void; danger?: boolean }) => (
  <button type="button" onClick={onClick} aria-label={label} title={label}
    className={`flex size-10 items-center justify-center rounded-full border border-stroke bg-card transition hover:bg-elevated ${danger ? 'text-danger' : 'text-accent'}`}>
    <Icon size={18} />
  </button>
)

const TextCard = ({ icon: Icon, title, text }: { icon: LucideIcon; title: string; text: string }) => (
  <Card className="space-y-2">
    <div className="flex items-center gap-2 text-sm font-semibold text-accent"><Icon size={16} /> {title}</div>
    <p className="whitespace-pre-line">{text}</p>
  </Card>
)

const Photo = ({ blob, label, onOpen }: { blob?: Blob; label: string; onOpen: (url: string) => void }) => {
  const url = useObjectURL(blob)
  return (
    <div className="space-y-1.5">
      {url ? (
        <button type="button" onClick={() => onOpen(url)} className="block h-32 w-full overflow-hidden rounded-small">
          <img src={url} alt={label} className="size-full object-cover" />
        </button>
      ) : (
        <div className="flex h-32 items-center justify-center rounded-small bg-elevated text-text-3"><ImageIcon size={22} /></div>
      )}
      <div className="text-xs text-text-2">{label}</div>
    </div>
  )
}
