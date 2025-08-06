import SwiftUI

struct ContentView: View {
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false

    var body: some View {
        if !didShowOnboarding {
            OnboardingView {
                didShowOnboarding = true
            }
        } else {
            AppView()
        }
    }
} 
