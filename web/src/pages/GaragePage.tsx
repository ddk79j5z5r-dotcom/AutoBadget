import {
  ArrowLeftRight, BellRing, Camera, CalendarClock, ChevronRight, CircleCheck, Cog, Download, Ellipsis, Eraser, Gauge, Hammer,
  Pencil, Sparkles, Trash, Upload, Waypoints, Wrench, type LucideIcon,
} from 'lucide-react'
import { useRef, useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { Page, PageHeader } from '@/components/AppShell'
import { repairIcon } from '@/components/icons'
import { CarImage, UpcomingServiceRow } from '@/components/rows'
import { ConfirmDialog } from '@/components/Sheet'
import { Appear, Card, Divider, EmptyState, InfoRow, SectionHeader, SymbolBadge, cx } from '@/components/ui'
import { statusInfo } from '@/models/serviceTracking'
import { repairCategoryInfo, repairTotal, type Car } from '@/models/types'
import { exportBackup, importBackup } from '@/services/backup'
import { db } from '@/services/db'
import { clearCarData, deleteCar } from '@/services/dataService'
import { addDemoCar } from '@/services/demoData'
import { dateShort, km, rub } from '@/services/formatters'
import { downscaleImage } from '@/services/images'
import { CarFormSheet } from '@/sheets/CarFormSheet'
import { CarSwitcherSheet } from '@/sheets/CarSwitcherSheet'
import { useCurrentCar } from '@/viewmodels/currentCar'
import { useGarageViewModel } from '@/viewmodels/viewModels'

export const GaragePage = () => {
  const vm = useGarageViewModel()
  const [editing, setEditing] = useState(false)
  const [menu, setMenu] = useState(false)
  const [switching, setSwitching] = useState(false)
  const [confirm, setConfirm] = useState<'clear' | 'delete'>()
  const { select } = useCurrentCar()
  const [confirmImport, setConfirmImport] = useState<File>()
  const [error, setError] = useState<string>()
  const importInput = useRef<HTMLInputElement>(null)
  const car = vm.car

  return (
    <>
      <PageHeader
        title="Гараж"
        actions={
          <div className="relative">
            <button type="button" onClick={() => setMenu(m => !m)} aria-label="Меню" aria-expanded={menu}
              className="flex size-10 items-center justify-center rounded-full border border-stroke bg-card text-accent transition hover:bg-elevated">
              <Ellipsis size={20} />
            </button>
            {menu && (
              <>
                <div className="fixed inset-0 z-30" onClick={() => setMenu(false)} />
                <div className="animate-appear absolute right-0 top-12 z-40 w-64 overflow-hidden rounded-small border border-stroke bg-elevated py-1 shadow-2xl">
                  <MenuItem icon={ArrowLeftRight} onClick={() => { setMenu(false); setSwitching(true) }}>Мои автомобили</MenuItem>
                  <MenuItem icon={Pencil} onClick={() => { setMenu(false); setEditing(true) }}>Редактировать авто</MenuItem>
                  <MenuItem icon={Sparkles} onClick={async () => { setMenu(false); select(await addDemoCar()) }}>Добавить демо-автомобиль</MenuItem>
                  <div className="my-1 h-px bg-stroke" />
                  <MenuItem icon={Download} onClick={() => { setMenu(false); exportBackup() }}>Экспорт данных (JSON)</MenuItem>
                  <MenuItem icon={Upload} onClick={() => { setMenu(false); importInput.current?.click() }}>Импорт из файла</MenuItem>
                  <div className="my-1 h-px bg-stroke" />
                  <MenuItem icon={Eraser} danger onClick={() => { setMenu(false); setConfirm('clear') }}>Очистить данные автомобиля</MenuItem>
                  <MenuItem icon={Trash} danger onClick={() => { setMenu(false); setConfirm('delete') }}>Удалить автомобиль</MenuItem>
                </div>
              </>
            )}
            <input
              ref={importInput} type="file" accept="application/json" hidden
              onChange={e => { const f = e.target.files?.[0]; if (f) setConfirmImport(f); e.target.value = '' }}
            />
          </div>
        }
      />
      <Page>
        {error && <Card className="text-sm text-danger">{error}</Card>}
        {car ? (
          <>
            <Appear><Hero car={car} onEdit={() => setEditing(true)} /></Appear>

            <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
              <div className="space-y-5">
                <Appear delay={0.05}>
                  <Card padding="p-0" className="overflow-hidden">
                    <LinkRow to="/garage/repairs" icon={Wrench} title="Ремонт и обслуживание" subtitle="История ремонтов, фото, стоимость работ" />
                    <Divider inset={70} />
                    <LinkRow to="/garage/parts" icon={Cog} title="Детали и ресурс" subtitle="Износ установленных деталей и сроки замены" />
                    <Divider inset={70} />
                    <LinkRow to="/garage/reminders" icon={BellRing} title="Напоминания" subtitle="ОСАГО, техосмотр и регламентные работы" />
                    <Divider inset={70} />
                    <LinkRow to="/garage/timeline" icon={Waypoints} title="Timeline эксплуатации" subtitle="Вся история ремонтов по годам" />
                  </Card>
                </Appear>

                <Appear delay={0.1} className="space-y-3">
                  <SectionHeader title="Обслуживание" />
                  <Card padding="p-1">
                    <OverviewRow icon={CircleCheck} tint="var(--color-accent)" title="Последнее ТО"
                      value={vm.lastService ? `${dateShort(vm.lastService.date)} · ${km(vm.lastService.mileage)}` : 'Нет данных'} />
                    <Divider inset={44} />
                    <OverviewRow icon={CalendarClock} tint={vm.nextService ? statusInfo[vm.nextService.status].color : 'var(--color-text-3)'}
                      title="Следующее ТО"
                      value={vm.nextService ? `${vm.nextService.tracked.title} · ${vm.nextService.headline.toLowerCase()}` : 'Не запланировано'} />
                    <Divider inset={44} />
                    <OverviewRow icon={Hammer} tint={repairCategoryInfo.engine.color} title="Последний ремонт"
                      value={vm.lastRepair ? `${vm.lastRepair.title} · ${dateShort(vm.lastRepair.date)}` : 'Нет данных'} />
                  </Card>
                  {vm.nearestWorks.length > 0 && (
                    <Card className="space-y-4">
                      <div className="text-sm font-semibold text-text-2">Ближайшие работы</div>
                      {vm.nearestWorks.map(item => (
                        <Link key={item.tracked.key} className="block"
                          to={item.tracked.source.type === 'part' ? `/garage/parts/${item.tracked.source.part.id}` : '/garage/reminders'}>
                          <UpcomingServiceRow item={item} />
                        </Link>
                      ))}
                    </Card>
                  )}
                </Appear>
              </div>

              <div className="space-y-5">
                <Appear delay={0.15} className="space-y-3">
                  <SectionHeader title="Информация" />
                  <div className="grid grid-cols-2 gap-2.5">
                    <InfoCell title="Марка" value={car.make} />
                    <InfoCell title="Модель" value={car.model} />
                    <InfoCell title="Год" value={String(car.year)} />
                    <InfoCell title="Кузов" value={car.bodyCode} />
                    <InfoCell title="Двигатель" value={car.engine} />
                    <InfoCell title="Пробег" value={km(car.mileage)} />
                  </div>
                  <Card className="space-y-2.5">
                    <InfoRow title="VIN / номер кузова" value={car.vin || '—'} />
                    <Divider />
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-text-2">Госномер</span>
                      <Plate plate={car.plate} />
                    </div>
                  </Card>
                </Appear>

                <Appear delay={0.2} className="space-y-3">
                  <SectionHeader title="История обслуживания" />
                  {vm.serviceHistory.length === 0 ? (
                    <Card><EmptyState icon={Wrench} title="Пока нет ТО" message="Добавьте ремонт с категорией «Плановое ТО»" /></Card>
                  ) : (
                    <Card padding="p-1">
                      {vm.serviceHistory.map((r, i) => (
                        <div key={r.id}>
                          <Link to={`/garage/repairs/${r.id}`} className="flex items-center gap-3 rounded-small p-3 transition hover:bg-elevated">
                            <SymbolBadge icon={repairIcon[r.category]} color={repairCategoryInfo[r.category].color} size={38} />
                            <div className="min-w-0 flex-1">
                              <div className="truncate text-sm font-semibold">{r.title}</div>
                              <div className="text-xs text-text-2">{dateShort(r.date)} · {km(r.mileage)}</div>
                            </div>
                            <span className="text-sm font-semibold">{rub(repairTotal(r))}</span>
                          </Link>
                          {i < vm.serviceHistory.length - 1 && <Divider inset={62} />}
                        </div>
                      ))}
                    </Card>
                  )}
                </Appear>
              </div>
            </div>
          </>
        ) : null}
      </Page>

      {editing && car && <CarFormSheet car={car} onClose={() => setEditing(false)} />}
      {switching && <CarSwitcherSheet onClose={() => setSwitching(false)} />}
      {confirm === 'clear' && car && (
        <ConfirmDialog
          title={`Очистить данные ${car.make} ${car.model}?`}
          message="Будут удалены все расходы, заправки, ремонты, детали и напоминания этого автомобиля. Сам автомобиль и его фото останутся."
          confirmTitle="Очистить"
          onConfirm={async () => { setConfirm(undefined); await clearCarData(car.id) }}
          onCancel={() => setConfirm(undefined)}
        />
      )}
      {confirm === 'delete' && car && (
        <ConfirmDialog
          title={`Удалить ${car.make} ${car.model}?`}
          message="Автомобиль и все его записи будут удалены без возможности восстановления."
          onConfirm={async () => { setConfirm(undefined); await deleteCar(car.id) }}
          onCancel={() => setConfirm(undefined)}
        />
      )}
      {confirmImport && (
        <ConfirmDialog
          title="Импортировать данные?"
          message={`Текущие данные будут заменены содержимым файла «${confirmImport.name}».`}
          confirmTitle="Импортировать"
          onConfirm={async () => {
            const file = confirmImport
            setConfirmImport(undefined)
            try {
              await importBackup(file)
              setError(undefined)
            } catch (e) {
              setError(e instanceof Error ? e.message : 'Не удалось импортировать файл')
            }
          }}
          onCancel={() => setConfirmImport(undefined)}
        />
      )}
    </>
  )
}

const Hero = ({ car, onEdit }: { car: Car; onEdit: () => void }) => (
  <div className="flex flex-col items-center gap-3.5 lg:flex-row lg:items-center lg:gap-8">
    <div className="relative h-56 w-full overflow-hidden rounded-card border border-stroke bg-linear-to-b from-elevated to-card lg:h-64 lg:w-1/2">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom,rgb(0_212_170/0.22),transparent_65%)]" />
      <CarImage photo={car.photo} className={cx('relative size-full', !car.photo && 'px-7 pt-3')} />
      <label className="absolute bottom-3 right-3 flex cursor-pointer items-center gap-1.5 rounded-full bg-black/55 px-3 py-2 text-xs font-semibold backdrop-blur">
        <Camera size={14} /> {car.photo ? 'Сменить фото' : 'Добавить фото'}
        <input type="file" accept="image/*" hidden onChange={async e => {
          const file = e.target.files?.[0]
          if (file) await db.cars.update(car.id, { photo: await downscaleImage(file) })
        }} />
      </label>
    </div>
    <div className="flex flex-col items-center gap-1 text-center lg:items-start lg:text-left">
      <h2 className="font-rounded text-4xl font-bold">{car.make} {car.model}</h2>
      <div className="text-text-2">{[car.bodyCode, car.year, car.engine].filter(Boolean).join(' · ')}</div>
      <button
        type="button"
        onClick={onEdit}
        className="mt-3 flex items-center gap-2 rounded-full bg-linear-to-br from-accent to-accent-deep px-5 py-2.5 font-semibold text-black transition active:scale-95"
      >
        <Gauge size={18} /> {km(car.mileage)} <Pencil size={13} />
      </button>
    </div>
  </div>
)

const LinkRow = ({ to, icon, title, subtitle }: { to: string; icon: LucideIcon; title: string; subtitle: string }) => (
  <Link to={to} className="flex items-center gap-3.5 p-3.5 transition hover:bg-elevated">
    <SymbolBadge icon={icon} color="var(--color-accent)" />
    <div className="min-w-0 flex-1">
      <div className="font-semibold">{title}</div>
      <div className="text-xs text-text-2">{subtitle}</div>
    </div>
    <ChevronRight size={18} className="text-text-3" />
  </Link>
)

const OverviewRow = ({ icon: Icon, tint, title, value }: { icon: LucideIcon; tint: string; title: string; value: string }) => (
  <div className="flex items-center gap-3 p-3">
    <Icon size={20} style={{ color: tint }} className="w-6 shrink-0" />
    <div className="min-w-0">
      <div className="text-xs text-text-2">{title}</div>
      <div className="text-sm font-semibold">{value}</div>
    </div>
  </div>
)

const InfoCell = ({ title, value }: { title: string; value: string }) => (
  <Card padding="p-3.5">
    <div className="text-xs text-text-2">{title}</div>
    <div className="font-rounded truncate font-semibold">{value || '—'}</div>
  </Card>
)

const MenuItem = ({ icon: Icon, onClick, danger, children }: {
  icon: LucideIcon; onClick: () => void; danger?: boolean; children: ReactNode
}) => (
  <button type="button" onClick={onClick}
    className={cx('flex w-full items-center gap-3 px-4 py-2.5 text-left text-sm hover:bg-field', danger && 'text-danger')}>
    <Icon size={17} className={danger ? 'text-danger' : 'text-accent'} /> {children}
  </button>
)

/** Российский госномер в стилизованной рамке */
const Plate = ({ plate }: { plate: string }) => {
  const [number, region] = plate.split(' ')
  return (
    <span className="inline-flex h-7 items-stretch overflow-hidden rounded-[5px] border-[1.5px] border-black bg-white font-mono text-sm font-bold text-black">
      <span className="flex items-center px-2">{number}</span>
      {region && (
        <span className="flex flex-col items-center justify-center border-l-[1.5px] border-black px-1.5 leading-none">
          <span className="text-[11px]">{region}</span>
          <span className="text-[6px]">RUS</span>
        </span>
      )}
    </span>
  )
}
