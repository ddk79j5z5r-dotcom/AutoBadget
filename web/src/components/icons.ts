import {
  ArrowUpDown, Armchair, BadgeCheck, Bell, Car, CircleDot, Cog, Disc, Droplet, Engine, FileText, Fuel, Hammer,
  Paintbrush, Settings2, ShieldCheck, Wind, Wrench, Zap, type LucideIcon,
} from 'lucide-react'
import type { Tracked } from '@/models/serviceTracking'
import type { ExpenseCategory, ReminderKind, RepairCategory } from '@/models/types'

/** Иконки — аналоги SF Symbols из iOS-версии */
export const expenseIcon: Record<ExpenseCategory, LucideIcon> = {
  fuel: Fuel,
  maintenance: Wrench,
  tires: CircleDot,
  tuning: Paintbrush,
  insurance: ShieldCheck,
  taxes: FileText,
  repair: Hammer,
  parts: Cog,
}

export const repairIcon: Record<RepairCategory, LucideIcon> = {
  engine: Engine,
  gearbox: Settings2,
  suspension: ArrowUpDown,
  brakes: Disc,
  electrics: Zap,
  body: Car,
  interior: Armchair,
  service: Wrench,
}

export const reminderIcon: Record<ReminderKind, LucideIcon> = {
  oil: Droplet,
  filters: Wind,
  brakePads: Disc,
  timingBelt: Cog,
  osago: FileText,
  inspection: BadgeCheck,
  custom: Bell,
}

export const trackedIcon = (t: Tracked): LucideIcon =>
  t.source.type === 'part' ? repairIcon[t.source.part.category] : reminderIcon[t.source.reminder.kind]
