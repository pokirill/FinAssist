import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss

    @State private var want: String = ""
    @State private var soThat: String = ""
    @State private var showSuccess: Bool = false

    var isValid: Bool {
        !want.trimmingCharacters(in: .whitespaces).isEmpty &&
        !soThat.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Я бы хотел...").foregroundColor(Color(hex: "#2563EB"))) {
                    TextField("Например, «копить на отпуск»", text: $want)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Section(header: Text("...чтобы").foregroundColor(Color(hex: "#2563EB"))) {
                    TextField("Например, «чувствовать себя увереннее»", text: $soThat)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Section {
                    Button(action: {
                        // Здесь можно добавить отправку на сервер или в аналитику
                        showSuccess = true
                        want = ""
                        soThat = ""
                    }) {
                        Text("Отправить")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color(hex: "#2563EB") : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Обратная связь")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showSuccess) {
                Alert(
                    title: Text("Спасибо!"),
                    message: Text("Ваше пожелание отправлено."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .accentColor(Color(hex: "#2563EB"))
    }
}
