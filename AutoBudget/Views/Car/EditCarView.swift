import SwiftData
import SwiftUI

struct EditCarView: View {
    let car: Car

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var make = ""
    @State private var model = ""
    @State private var bodyCode = ""
    @State private var yearText = ""
    @State private var engine = ""
    @State private var vin = ""
    @State private var plate = ""
    @State private var mileageText = ""

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.trimmingCharacters(in: .whitespaces).isEmpty
            && Int(yearText) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Автомобиль") { dismiss() }
            ScrollView {
                VStack(spacing: 20) {
                    FormSection(title: "Основное") {
                        FormRow(symbol: "car.fill") { AppTextField(placeholder: "Марка", text: $make) }
                        FormRow(symbol: "tag.fill") { AppTextField(placeholder: "Модель", text: $model) }
                        FormRow(symbol: "calendar") { AppTextField(placeholder: "Год", text: $yearText, keyboard: .numberPad) }
                        FormRow(symbol: "square.3.layers.3d") { AppTextField(placeholder: "Кузов (например, JZS160)", text: $bodyCode) }
                        FormRow(symbol: "engine.combustion.fill", showDivider: false) {
                            AppTextField(placeholder: "Двигатель", text: $engine)
                        }
                    }
                    FormSection(title: "Документы") {
                        FormRow(symbol: "barcode") {
                            AppTextField(placeholder: "VIN / номер кузова", text: $vin)
                                .textInputAutocapitalization(.characters)
                        }
                        FormRow(symbol: "rectangle.and.text.magnifyingglass", showDivider: false) {
                            AppTextField(placeholder: "Госномер (А160РС 178)", text: $plate)
                                .textInputAutocapitalization(.characters)
                        }
                    }
                    FormSection(title: "Пробег") {
                        FormRow(symbol: "gauge.with.dots.needle.67percent", showDivider: false) {
                            AppTextField(placeholder: "Текущий пробег", text: $mileageText, keyboard: .numberPad)
                            Text("км").foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            Button("Сохранить", action: save)
                .buttonStyle(PrimaryButtonStyle(enabled: isValid))
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
        }
        .background(Theme.background)
        .onAppear {
            make = car.make
            model = car.model
            bodyCode = car.bodyCode
            yearText = String(car.year)
            engine = car.engine
            vin = car.vin
            plate = car.plate
            mileageText = String(car.mileage)
        }
    }

    private func save() {
        car.make = make.trimmingCharacters(in: .whitespaces)
        car.model = model.trimmingCharacters(in: .whitespaces)
        car.bodyCode = bodyCode.trimmingCharacters(in: .whitespaces)
        car.year = Int(yearText) ?? car.year
        car.engine = engine.trimmingCharacters(in: .whitespaces)
        car.vin = vin.trimmingCharacters(in: .whitespaces).uppercased()
        car.plate = plate.trimmingCharacters(in: .whitespaces).uppercased()
        if let km = Formatters.parseNumber(mileageText) {
            DataService.updateMileage(to: Int(km), in: context, onlyIncrease: false)
        }
        try? context.save()
        dismiss()
    }
}
