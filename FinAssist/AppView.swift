import SwiftUI

struct AppView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            IncomeExpenseTabView()
                .tabItem {
                    Image(systemName: "creditcard")
                    Text("Доходы и расходы")
                }
                .tag(0)

            MainAppView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Мои цели")
                }
                .tag(1)
        }
    }
}
