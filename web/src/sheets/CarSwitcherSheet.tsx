import { Check, Plus } from 'lucide-react'
import { useState } from 'react'
import { CarImage } from '@/components/rows'
import { Sheet } from '@/components/Sheet'
import { cx } from '@/components/ui'
import { km } from '@/services/formatters'
import { useCurrentCar } from '@/viewmodels/currentCar'
import { CarFormSheet } from './CarFormSheet'

/** Выбор автомобиля и добавление нового — открывается по тапу на название машины */
export const CarSwitcherSheet = ({ onClose }: { onClose: () => void }) => {
  const { cars = [], car: current, select } = useCurrentCar()
  const [adding, setAdding] = useState(false)

  return (
    <Sheet title="Мои автомобили" onClose={onClose}>
      <div className="space-y-2.5">
        {cars.map(c => {
          const active = c.id === current?.id
          return (
            <button
              key={c.id}
              type="button"
              onClick={() => { select(c.id); onClose() }}
              className={cx(
                'flex w-full items-center gap-3.5 rounded-card border p-3 text-left transition active:scale-[0.99]',
                active ? 'border-accent/60 bg-accent/8' : 'border-stroke bg-card hover:bg-elevated',
              )}
            >
              <div className="h-14 w-24 shrink-0 overflow-hidden rounded-small bg-elevated">
                <CarImage photo={c.photo} className="size-full" />
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate font-semibold">{c.make} {c.model}</div>
                <div className="truncate text-xs text-text-2">
                  {[c.bodyCode, c.year, c.plate].filter(Boolean).join(' · ')}
                </div>
                <div className="text-xs text-text-3">{km(c.mileage)}</div>
              </div>
              {active && <Check size={20} strokeWidth={2.6} className="shrink-0 text-accent" />}
            </button>
          )
        })}
        <button
          type="button"
          onClick={() => setAdding(true)}
          className="flex h-14 w-full items-center justify-center gap-2 rounded-card border border-dashed border-accent/50 font-semibold text-accent transition hover:bg-accent/8"
        >
          <Plus size={20} /> Добавить автомобиль
        </button>
      </div>
      {adding && (
        <CarFormSheet
          onSaved={id => { select(id); onClose() }}
          onClose={() => setAdding(false)}
        />
      )}
    </Sheet>
  )
}
