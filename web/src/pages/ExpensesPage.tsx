import { ArrowDownWideNarrow, CalendarArrowDown, Search, Trash } from 'lucide-react'
import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { IconButton, Page, PageHeader } from '@/components/AppShell'
import { ExpenseRow } from '@/components/rows'
import { ConfirmDialog } from '@/components/Sheet'
import { Card, ChipBar, Divider, EmptyState, FilterChip, SearchField } from '@/components/ui'
import { EXPENSE_FILTER_ORDER, expenseCategoryInfo, type Expense, type ExpenseCategory } from '@/models/types'
import { db } from '@/services/db'
import { monthName, plural, rub } from '@/services/formatters'
import { AddExpenseSheet } from '@/sheets/AddExpenseSheet'
import { useExpensesViewModel } from '@/viewmodels/viewModels'

/** Вкладка «Расходы» и расходы одной категории (переход с главного экрана) */
export const ExpensesPage = () => {
  const { category } = useParams<{ category?: ExpenseCategory }>()
  const vm = useExpensesViewModel(category)
  const [editing, setEditing] = useState<Expense>()
  const [deleting, setDeleting] = useState<Expense>()

  const row = (e: Expense, last: boolean) => (
    <div key={e.id} className="group relative">
      <button type="button" className="w-full text-left" onClick={() => setEditing(e)}>
        <ExpenseRow expense={e} />
      </button>
      <button
        type="button"
        onClick={() => setDeleting(e)}
        aria-label="Удалить"
        className="absolute right-0 top-1/2 hidden size-9 -translate-y-1/2 items-center justify-center rounded-full bg-danger/15 text-danger group-hover:flex"
      >
        <Trash size={16} />
      </button>
      {!last && <Divider inset={52} />}
    </div>
  )

  return (
    <>
      <PageHeader
        title={category ? expenseCategoryInfo[category].title : 'Расходы'}
        back={category ? '/' : undefined}
        actions={
          <IconButton
            icon={vm.sort === 'date' ? CalendarArrowDown : ArrowDownWideNarrow}
            label={vm.sort === 'date' ? 'Сортировка по дате' : 'Сортировка по сумме'}
            onClick={() => vm.setSort(vm.sort === 'date' ? 'amount' : 'date')}
          />
        }
      />
      <Page>
        <SearchField value={vm.search} onChange={vm.setSearch} placeholder="Поиск" />
        {!category && (
          <ChipBar>
            <FilterChip title="Все" selected={!vm.category} onClick={() => vm.setCategory(undefined)} />
            {EXPENSE_FILTER_ORDER.map(c => (
              <FilterChip key={c} title={expenseCategoryInfo[c].title} selected={vm.category === c}
                onClick={() => vm.setCategory(vm.category === c ? undefined : c)} />
            ))}
          </ChipBar>
        )}
        <Card className="flex items-center justify-between" padding="p-3.5">
          <div>
            <div className="text-xs text-text-2">Итого</div>
            <div className="font-rounded text-xl font-bold">{rub(vm.total)}</div>
          </div>
          <div className="text-sm text-text-2">
            {vm.filtered.length} {plural(vm.filtered.length, 'операция', 'операции', 'операций')}
          </div>
        </Card>

        {vm.filtered.length === 0 && (
          <EmptyState icon={Search} title="Ничего не найдено" message="Попробуйте изменить фильтр или поисковый запрос" />
        )}

        {vm.sort === 'date'
          ? vm.groups.map(g => (
              <section key={g.month} className="space-y-2">
                <div className="flex justify-between px-1 text-sm font-semibold text-text-3">
                  <span>{monthName(g.month)}</span>
                  <span>{rub(g.total)}</span>
                </div>
                <Card padding="px-4 py-1.5">{g.items.map((e, i) => row(e, i === g.items.length - 1))}</Card>
              </section>
            ))
          : vm.filtered.length > 0 && (
              <Card padding="px-4 py-1.5">{vm.filtered.map((e, i) => row(e, i === vm.filtered.length - 1))}</Card>
            )}
      </Page>

      {editing && <AddExpenseSheet expense={editing} onClose={() => setEditing(undefined)} />}
      {deleting && (
        <ConfirmDialog
          title="Удалить расход?"
          message={deleting.title}
          onConfirm={async () => { await db.expenses.delete(deleting.id); setDeleting(undefined) }}
          onCancel={() => setDeleting(undefined)}
        />
      )}
    </>
  )
}
