import { lazy, useEffect, type ComponentType } from 'react'
import { createBrowserRouter, RouterProvider, useLocation } from 'react-router-dom'
import { AppShell } from '@/components/AppShell'
import { trackedItems } from '@/services/dataService'
import { notifyDueDates } from '@/services/notifications'
import { WelcomePage } from '@/pages/WelcomePage'
import { CurrentCarProvider, useCurrentCar } from '@/viewmodels/currentCar'

// Экраны грузятся по требованию — первая загрузка не тянет графики и формы всех разделов сразу
const page = <K extends string>(load: () => Promise<Record<K, ComponentType>>, name: K) =>
  lazy(() => load().then(m => ({ default: m[name] })))

const DashboardPage = page(() => import('@/pages/DashboardPage'), 'DashboardPage')
const ExpensesPage = page(() => import('@/pages/ExpensesPage'), 'ExpensesPage')
const FuelPage = page(() => import('@/pages/FuelPage'), 'FuelPage')
const StatisticsPage = page(() => import('@/pages/StatisticsPage'), 'StatisticsPage')
const GaragePage = page(() => import('@/pages/GaragePage'), 'GaragePage')
const RepairsPage = page(() => import('@/pages/RepairsPage'), 'RepairsPage')
const RepairDetailPage = page(() => import('@/pages/RepairDetailPage'), 'RepairDetailPage')
const TimelinePage = page(() => import('@/pages/TimelinePage'), 'TimelinePage')
const PartsPage = page(() => import('@/pages/PartsPage'), 'PartsPage')
const PartDetailPage = page(() => import('@/pages/PartDetailPage'), 'PartDetailPage')
const RemindersPage = page(() => import('@/pages/RemindersPage'), 'RemindersPage')

/** Каждый новый экран открывается с начала */
const ScrollToTop = () => {
  const { pathname } = useLocation()
  useEffect(() => {
    // Скобки обязательны: в новых браузерах scrollTo возвращает Promise, а React ждёт от эффекта функцию очистки
    window.scrollTo(0, 0)
  }, [pathname])
  return null
}

/** Пока нет ни одного автомобиля — приветственный экран с добавлением машины */
const Layout = () => {
  const { cars } = useCurrentCar()
  if (cars === undefined) return null
  if (cars.length === 0) return <WelcomePage />
  return (
    <>
      <ScrollToTop />
      <AppShell />
    </>
  )
}

const router = createBrowserRouter([
  {
    element: <Layout />,
    children: [
      { path: '/', element: <DashboardPage /> },
      { path: '/expenses', element: <ExpensesPage /> },
      { path: '/expenses/:category', element: <ExpensesPage /> },
      { path: '/fuel', element: <FuelPage /> },
      { path: '/stats', element: <StatisticsPage /> },
      { path: '/garage', element: <GaragePage /> },
      { path: '/garage/repairs', element: <RepairsPage /> },
      { path: '/garage/repairs/:id', element: <RepairDetailPage /> },
      { path: '/garage/timeline', element: <TimelinePage /> },
      { path: '/garage/parts', element: <PartsPage /> },
      { path: '/garage/parts/:id', element: <PartDetailPage /> },
      { path: '/garage/reminders', element: <RemindersPage /> },
      { path: '*', element: <DashboardPage /> },
    ],
  },
], {
  // На GitHub Pages сайт живёт в /AutoBadget/ — базовый путь приходит из сборки
  basename: import.meta.env.BASE_URL.replace(/\/$/, '') || '/',
})

export const App = () => {
  useEffect(() => {
    // Проверка сроков для уведомлений по времени — по всем автомобилям
    const checkDue = async () => notifyDueDates(await trackedItems())
    checkDue()
    const onVisible = () => document.visibilityState === 'visible' && checkDue()
    document.addEventListener('visibilitychange', onVisible)
    return () => document.removeEventListener('visibilitychange', onVisible)
  }, [])

  return (
    <CurrentCarProvider>
      <RouterProvider router={router} />
    </CurrentCarProvider>
  )
}
