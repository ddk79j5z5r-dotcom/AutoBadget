import { Sparkles } from 'lucide-react'
import { useState } from 'react'
import { PrimaryButton } from '@/components/ui'
import { addDemoCar } from '@/services/demoData'
import { CarFields, useCarDraft } from '@/sheets/CarFormSheet'
import { useCurrentCar } from '@/viewmodels/currentCar'

/** Первый запуск: добавление своего автомобиля (или демо-машины, чтобы осмотреться) */
export const WelcomePage = () => {
  const { select } = useCurrentCar()
  const draft = useCarDraft()
  const [busy, setBusy] = useState(false)

  const run = async (action: () => Promise<string>) => {
    setBusy(true)
    try {
      select(await action())
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="screen-glow min-h-dvh px-4 pb-10 pt-[calc(env(safe-area-inset-top)+2.5rem)]">
      <div className="mx-auto max-w-md space-y-6">
        <div className="animate-appear flex flex-col items-center gap-3 text-center">
          <img src={`${import.meta.env.BASE_URL}icon.png`} alt="" className="size-20 rounded-[20px] shadow-[0_10px_30px_rgb(0_212_170/0.25)]" />
          <h1 className="text-3xl font-bold">AutoBudget</h1>
          <p className="text-text-2">Расходы, ремонты и ресурс деталей вашего автомобиля — в одном месте.</p>
        </div>

        <div className="animate-appear space-y-4" style={{ animationDelay: '0.08s' }}>
          <h2 className="text-lg font-bold">Добавьте свой автомобиль</h2>
          <form onSubmit={e => { e.preventDefault(); if (draft.valid) run(draft.save) }} className="space-y-4">
            <CarFields draft={draft} />
            <PrimaryButton type="submit" disabled={!draft.valid || busy}>Начать</PrimaryButton>
          </form>
        </div>

        <button
          type="button"
          disabled={busy}
          onClick={() => run(addDemoCar)}
          className="flex w-full items-center justify-center gap-2 py-2 text-sm font-semibold text-accent disabled:opacity-50"
        >
          <Sparkles size={16} /> Посмотреть на демо-данных
        </button>
      </div>
    </div>
  )
}
