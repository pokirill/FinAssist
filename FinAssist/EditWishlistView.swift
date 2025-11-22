import SwiftUI

struct EditWishlistView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var wishlistItems: [WishlistItem]
    let item: WishlistItem
    
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var note: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Название
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Название")
                                .font(.subheadline).bold()
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("Например: iPhone, отпуск, велосипед", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(AppColors.surface)
                                .cornerRadius(8)
                        }
                        
                        // Сумма
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Сумма")
                                .font(.subheadline).bold()
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack {
                                TextField("0", text: $amountText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(AppColors.surface)
                                    .cornerRadius(8)
                                    .onChange(of: amountText) { newValue in
                                        amountText = AppUtils.formatInput(newValue)
                                    }
                                
                                Text("₽")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        // Заметка (опционально)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Заметка (необязательно)")
                                .font(.subheadline).bold()
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextEditor(text: $note)
                                .frame(height: 80)
                                .padding(8)
                                .background(AppColors.surface)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Spacer()
                        
                        // Кнопка сохранения
                        Button(action: saveWishlist) {
                            Text("Сохранить")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isValid ? AppColors.primary : AppColors.textSecondary.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .disabled(!isValid)
                    }
                    .padding()
                }
            }
            .navigationTitle("Изменить хотелку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                name = item.name
                amountText = AppUtils.numberFormatter.string(from: NSNumber(value: item.amount)) ?? ""
                note = item.note ?? ""
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && Double(amountText.replacingOccurrences(of: " ", with: "")) ?? 0 > 0
    }
    
    private func saveWishlist() {
        guard isValid, let amount = Double(amountText.replacingOccurrences(of: " ", with: "")) else { return }
        
        if let index = wishlistItems.firstIndex(where: { $0.id == item.id }) {
            wishlistItems[index].name = name
            wishlistItems[index].amount = amount
            wishlistItems[index].note = note.isEmpty ? nil : note
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

