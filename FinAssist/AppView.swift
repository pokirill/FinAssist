import SwiftUI

struct AppView: View {
    var body: some View {
        TabView {
            MainAppView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Цели")
                }
            
            WishlistView()
                .tabItem {
                    Image(systemName: "star.circle")
                    Text("Хотелки")
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
