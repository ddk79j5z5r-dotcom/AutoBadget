// Форматирование на русском: ₽, км, даты, склонения

const locale = 'ru-RU'

const rubFormatter = new Intl.NumberFormat(locale, { style: 'currency', currency: 'RUB', maximumFractionDigits: 0 })
const intFormatter = new Intl.NumberFormat(locale, { maximumFractionDigits: 0 })
const oneDecimalFormatter = new Intl.NumberFormat(locale, { minimumFractionDigits: 1, maximumFractionDigits: 1 })

export const rub = (v: number) => rubFormatter.format(v)
export const grouped = (v: number) => intFormatter.format(v)
export const km = (v: number) => `${grouped(v)} км`
export const oneDecimal = (v: number) => oneDecimalFormatter.format(v)

/** Компактная запись для осей графиков: 12 тыс, 1,2 млн */
export const rubShort = (v: number) => {
  const a = Math.abs(v)
  if (a >= 1_000_000) return `${oneDecimal(v / 1_000_000)} млн`
  if (a >= 1_000) return `${grouped(v / 1_000)} тыс`
  return grouped(v)
}

/** Разбор ввода: «1 234,50» → 1234.5 */
export const parseNumber = (text: string): number | undefined => {
  const cleaned = text.replace(/[\s ]/g, '').replace(',', '.')
  if (cleaned === '') return undefined
  const n = Number(cleaned)
  return Number.isFinite(n) ? n : undefined
}

// MARK: - Даты

const dayMonthYear = new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'short', year: 'numeric' })
const dayMonthShort = new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'short' })
const dayMonthLong = new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'long' })
const monthYear = new Intl.DateTimeFormat(locale, { month: 'long', year: 'numeric' })
const monthShort = new Intl.DateTimeFormat(locale, { month: 'short' })
const monthNarrow = new Intl.DateTimeFormat(locale, { month: 'narrow' })

const stripYearSuffix = (s: string) => s.replace(/\s?г\.$/, '')

export const dateShort = (t: number) => stripYearSuffix(dayMonthYear.format(t))
export const dateDayMonth = (t: number) => dayMonthLong.format(t)
export const monthName = (t: number) => {
  const s = monthYear.format(t).replace(/\s?г\.$/, '')
  return s.charAt(0).toUpperCase() + s.slice(1)
}
export const monthAbbr = (t: number) => monthShort.format(t).replace('.', '')
export const monthLetter = (t: number) => monthNarrow.format(t).toUpperCase()

/** «2 сент.» в текущем году, «2 сент. 2025» — в прошлых */
export const dateCompact = (t: number) =>
  new Date(t).getFullYear() === new Date().getFullYear() ? dayMonthShort.format(t) : dateShort(t)

export const startOfDay = (t: number) => {
  const d = new Date(t)
  d.setHours(0, 0, 0, 0)
  return d.getTime()
}

export const startOfMonth = (t: number) => {
  const d = new Date(t)
  return new Date(d.getFullYear(), d.getMonth(), 1).getTime()
}

export const addMonths = (t: number, months: number) => {
  const d = new Date(t)
  const day = d.getDate()
  d.setDate(1)
  d.setMonth(d.getMonth() + months)
  const last = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
  d.setDate(Math.min(day, last))
  return d.getTime()
}

export const addDays = (t: number, days: number) => t + days * 86_400_000

export const daysBetween = (from: number, to: number) => Math.round((startOfDay(to) - startOfDay(from)) / 86_400_000)

export const sameMonth = (a: number, b: number) => {
  const x = new Date(a), y = new Date(b)
  return x.getFullYear() === y.getFullYear() && x.getMonth() === y.getMonth()
}

export const yearOf = (t: number) => new Date(t).getFullYear()

/** Значение для <input type="date"> */
export const toDateInput = (t: number) => {
  const d = new Date(t)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

export const fromDateInput = (s: string) => {
  const [y, m, d] = s.split('-').map(Number)
  return new Date(y, m - 1, d, 12).getTime()
}

// MARK: - Склонения

export const plural = (n: number, one: string, few: string, many: string) => {
  const n10 = n % 10, n100 = n % 100
  if (n10 === 1 && n100 !== 11) return one
  if (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14)) return few
  return many
}

export const days = (n: number) => `${n} ${plural(n, 'день', 'дня', 'дней')}`

export const capitalizedFirst = (s: string) => s.charAt(0).toUpperCase() + s.slice(1)

/** Ресурс «30 000 км / 24 мес.»; нулевые значения не показываются */
export const resource = (kmValue: number, months: number) =>
  [kmValue > 0 ? km(kmValue) : null, months > 0 ? `${months} мес.` : null].filter(Boolean).join(' / ')
