import SwiftData
import SwiftUI

/// Вкладка «Расходы»
struct ExpensesView: View {
    @State private var vm = ExpensesViewModel()

    var body: some View {
        NavigationStack {
            ExpenseListScreen(vm: vm, showsFilters: true)
                .navigationTitle("Расходы")
        }
    }
}

/// Расходы одной категории (переход с главного экрана)
struct CategoryExpensesView: View {
    @State private var vm: ExpensesViewModel

    init(category: ExpenseCategory) {
        _vm = State(initialValue: ExpensesViewModel(category: category))
    }

    var body: some View {
        ExpenseListScreen(vm: vm, showsFilters: false)
            .navigationTitle(vm.selectedCategory?.title ?? "Расходы")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExpenseListScreen: View {
    @Bindable var vm: ExpensesViewModel
    let showsFilters: Bool

    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    var body: some View {
        let items = vm.filtered(expenses)
        let groups = vm.sort == .date ? vm.grouped(expenses) : []

        List {
            Section {
                VStack(spacing: 12) {
                    SearchField(text: $vm.searchText, prompt: "Поиск")
                    if showsFilters { filterBar }
                    totalBanner(total: items.reduce(0) { $0 + $1.amount }, count: items.count)
                }
                .plainRow(top: 4, bottom: 8)
            }

            if items.isEmpty {
                EmptyStateView(symbol: "magnifyingglass",
                               title: "Ничего не найдено",
                               message: "Попробуйте изменить фильтр или поисковый запрос")
                    .plainRow()
            }

            if vm.sort == .date {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { row($0) }
                    } header: {
                        HStack {
                            Text(group.month.ruMonthYear)
                            Spacer()
                            Text(group.total.rub)
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .textCase(nil)
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
            } else {
                ForEach(items) { row($0) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ScreenBackground())
        .animation(Theme.spring, value: vm.selectedCategory)
        .animation(Theme.spring, value: vm.sort)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { filterMenu }
        }
        .sheet(item: $vm.editingExpense) { expense in
            AddExpenseView(expense: expense)
                .autoSheetStyle()
        }
    }

    private func row(_ expense: Expense) -> some View {
        Button { vm.editingExpense = expense } label: {
            ExpenseRow(expense: expense)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(Theme.stroke)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 52 }
        .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation(Theme.spring) { vm.delete(expense, context: context) }
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
        .contextMenu {
            Button { vm.editingExpense = expense } label: { Label("Изменить", systemImage: "pencil") }
            Button(role: .destructive) { vm.delete(expense, context: context) } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Сортировка", selection: $vm.sort.animation(Theme.spring)) {
                ForEach(ExpenseSort.allCases) { Text($0.title).tag($0) }
            }
            if showsFilters {
                Picker("Категория", selection: $vm.selectedCategory.animation(Theme.spring)) {
                    Text("Все категории").tag(ExpenseCategory?.none)
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.title, systemImage: category.symbol).tag(Optional(category))
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityLabel("Фильтр и сортировка")
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(title: "Все", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(ExpenseCategory.filterOrder) { category in
                    FilterChip(title: category.title, isSelected: vm.selectedCategory == category) {
                        vm.selectedCategory = vm.selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func totalBanner(total: Double, count: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Итого")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(total.rub)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
            }
            Spacer()
            Text("\(count) \(Plural.form(count, "операция", "операции", "операций"))")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .card(padding: 14)
    }
}

private extension View {
    func plainRow(top: CGFloat = 8, bottom: CGFloat = 8) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: bottom, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
