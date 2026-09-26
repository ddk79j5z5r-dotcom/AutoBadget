import Foundation
import Observation
import SwiftData

struct ExpenseMonthGroup: Identifiable {
    let month: Date
    let items: [Expense]
    var id: Date { month }
    var total: Double { items.reduce(0) { $0 + $1.amount } }
}

enum ExpenseSort: String, CaseIterable, Identifiable {
    case date, amount
    var id: String { rawValue }
    var title: String { self == .date ? "По дате" : "По сумме" }
}

@Observable
final class ExpensesViewModel {
    var searchText = ""
    var selectedCategory: ExpenseCategory?
    var sort: ExpenseSort = .date
    var editingExpense: Expense?

    init(category: ExpenseCategory? = nil) {
        selectedCategory = category
    }

    func filtered(_ expenses: [Expense]) -> [Expense] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return expenses
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .filter { expense in
                guard !query.isEmpty else { return true }
                return expense.title.lowercased().contains(query)
                    || expense.place.lowercased().contains(query)
                    || expense.comment.lowercased().contains(query)
                    || expense.category.title.lowercased().contains(query)
            }
            .sorted { sort == .date ? $0.date > $1.date : $0.amount > $1.amount }
    }

    func grouped(_ expenses: [Expense]) -> [ExpenseMonthGroup] {
        let items = filtered(expenses)
        let dict = Dictionary(grouping: items) { $0.date.startOfMonth }
        return dict.map { ExpenseMonthGroup(month: $0.key, items: $0.value) }
            .sorted { $0.month > $1.month }
    }

    @MainActor
    func delete(_ expense: Expense, context: ModelContext) {
        context.delete(expense)
        try? context.save()
    }
}
