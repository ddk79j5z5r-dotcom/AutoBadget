// Строки списков — порт SharedRows.swift

import { Link as LinkIcon } from 'lucide-react'
import { useEffect, useState } from 'react'
import {
  nextServiceDescription, progress, remainingDescription, status, statusInfo, statusTitle, trackPart,
} from '@/models/serviceTracking'
import { fuelTypeInfo, repairCategoryInfo, type Expense, type Part } from '@/models/types'
import { dateCompact, km, rub } from '@/services/formatters'
import type { UpcomingService } from '@/services/maintenance'
import { repairIcon, trackedIcon } from './icons'
import { CategoryIcon, ProgressBar, StatusPill, SymbolBadge } from './ui'

export const ExpenseRow = ({ expense }: { expense: Expense }) => {
  const subtitle = [dateCompact(expense.date)]
  if (expense.category === 'fuel' && expense.liters) {
    subtitle.push(`${Math.round(expense.liters)} л`)
    if (expense.fuelType) subtitle.push(fuelTypeInfo[expense.fuelType].title)
  } else if (expense.mileage > 0) {
    subtitle.push(km(expense.mileage))
  }
  return (
    <div className="flex items-center gap-3 py-1.5">
      <CategoryIcon category={expense.category} />
      <div className="min-w-0 flex-1">
        <div className="truncate text-sm font-semibold">{expense.title}</div>
        <div className="flex items-center gap-1 truncate text-xs text-text-3">
          {subtitle.join(' · ')}
          {expense.repairId && <LinkIcon size={11} aria-label="Из истории ремонтов" />}
        </div>
      </div>
      <div className="font-rounded shrink-0 text-sm font-semibold">{rub(expense.amount)}</div>
    </div>
  )
}

/** «Через 2 000 км — Передние колодки» */
export const UpcomingServiceRow = ({ item }: { item: UpcomingService }) => {
  const color = statusInfo[item.status].color
  return (
    <div className="flex items-center gap-3">
      <SymbolBadge icon={trackedIcon(item.tracked)} color={color} size={38} />
      <div className="min-w-0 flex-1 space-y-1.5">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <div className="text-xs font-semibold" style={{ color }}>{item.headline}</div>
            <div className="truncate text-sm font-semibold">{item.tracked.title}</div>
          </div>
          {item.status !== 'ok' && (
            <StatusPill text={item.status === 'overdue' ? item.tracked.overdueTitle : statusInfo[item.status].title} color={color} />
          )}
        </div>
        <ProgressBar value={item.progress} color={color} height={5} />
      </div>
    </div>
  )
}

/** Деталь в списке: износ, остаток ресурса, следующая замена */
export const PartRow = ({ part, mileage }: { part: Part; mileage: number }) => {
  const t = trackPart(part)
  const s = status(t, mileage)
  const color = statusInfo[s].color
  return (
    <div className="space-y-2.5 py-3">
      <div className="flex items-start gap-3">
        <SymbolBadge icon={repairIcon[part.category]} color={color} size={38} />
        <div className="min-w-0 flex-1">
          <div className="text-sm font-semibold">{part.name}</div>
          <div className="truncate text-xs text-text-3">{[part.manufacturer, part.articleNumber].filter(Boolean).join(' · ')}</div>
        </div>
        <StatusPill text={statusTitle(t, mileage)} color={color} />
      </div>
      <ProgressBar value={progress(t, mileage)} color={color} />
      <div>
        <div className="text-xs font-medium" style={{ color: s === 'ok' ? 'var(--color-text-2)' : color }}>
          {remainingDescription(t, mileage)}
        </div>
        <div className="truncate text-xs text-text-3">Следующая замена: {nextServiceDescription(t)}</div>
      </div>
    </div>
  )
}

export const RepairBadge = ({ category, size = 40 }: { category: Part['category']; size?: number }) => (
  <SymbolBadge icon={repairIcon[category]} color={repairCategoryInfo[category].color} size={size} />
)

/** Фото автомобиля или фирменная иллюстрация */
export const CarImage = ({ photo, className }: { photo?: Blob; className?: string }) => {
  const url = useObjectURL(photo)
  return url
    ? <img src={url} alt="Фото автомобиля" className={`object-cover ${className ?? ''}`} />
    : <img src="/car-hero.png" alt="" className={`object-contain ${className ?? ''}`} />
}

/** URL для Blob из IndexedDB с автоматическим освобождением */
export const useObjectURL = (blob?: Blob) => {
  const [url, setUrl] = useState<string>()
  useEffect(() => {
    if (!blob) {
      setUrl(undefined)
      return
    }
    const u = URL.createObjectURL(blob)
    setUrl(u)
    return () => URL.revokeObjectURL(u)
  }, [blob])
  return url
}
