import SwiftUI

struct AppView: View {
    var body: some View {
        TabView {
            MainAppView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Мои цели")
                }
            
            IncomeExpenseView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Доходы и расходы")
                }
        }
        .accentColor(AppColors.primary)
    }
} 
