import { useLiveQuery } from 'dexie-react-hooks'
import { createContext, useCallback, useContext, useState, type ReactNode } from 'react'
import type { Car, ID } from '@/models/types'
import { db } from '@/services/db'

const STORAGE_KEY = 'autobudget.currentCarId'

interface CurrentCarState {
  /** undefined — база ещё не ответила */
  cars?: Car[]
  /** Выбранный автомобиль; если выбор не сохранён или машина удалена — первый в списке */
  car?: Car
  select: (id: ID) => void
}

const CurrentCarContext = createContext<CurrentCarState>({ select: () => {} })

const readStored = () => {
  try {
    return localStorage.getItem(STORAGE_KEY) ?? undefined
  } catch {
    return undefined
  }
}

export const CurrentCarProvider = ({ children }: { children: ReactNode }) => {
  const cars = useLiveQuery(() => db.cars.orderBy('createdAt').toArray(), [])
  const [selectedId, setSelectedId] = useState(readStored)

  const select = useCallback((id: ID) => {
    setSelectedId(id)
    try {
      localStorage.setItem(STORAGE_KEY, id)
    } catch {
      // Хранилище недоступно (приватный режим) — выбор действует до перезагрузки
    }
  }, [])

  const car = cars?.find(c => c.id === selectedId) ?? cars?.[0]
  return <CurrentCarContext.Provider value={{ cars, car, select }}>{children}</CurrentCarContext.Provider>
}

export const useCurrentCar = () => useContext(CurrentCarContext)
