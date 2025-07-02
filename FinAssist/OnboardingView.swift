import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let imageName: String
    let text: String
}

struct OnboardingView: View {
    let slides: [OnboardingSlide] = [
        OnboardingSlide(
            imageName: "basket.fill",
            text: "Всё о целях и крупных покупках в одном месте — не держи всё в голове!"
        ),
        OnboardingSlide(
            imageName: "calendar.badge.clock",
            text: "Узнай реальные сроки достижения целей с учетом твоих возможностей."
        ),
        OnboardingSlide(
            imageName: "list.bullet.rectangle.portrait",
            text: "Составь оптимальный план по приоритетам и следи за прогрессом."
        ),
        OnboardingSlide(
            imageName: "function",
            text: "FinAssist сам рассчитает, сколько ты сможешь откладывать с учётом твоих доходов и расходов — тебе не придётся ничего считать в Excel или на бумаге!"
        ),
        OnboardingSlide(
            imageName: "gamecontroller.fill",
            text: "Геймификация и поддержка — приложение будет подбадривать и мотивировать!"
        )
        
    ]
    @State private var currentIndex = 0
    @State private var timer: Timer? = nil
    var onStart: (() -> Void)?

    var body: some View {
        VStack {
            TabView(selection: $currentIndex) {
                ForEach(0..<slides.count, id: \ .self) { idx in
                    VStack(spacing: 32) {
                        Spacer()
                        Image(systemName: slides[idx].imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .foregroundColor(Color.blue)
                        Text(slides[idx].text)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(.label))
                            .padding(.horizontal, 24)
                        Spacer()
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .animation(.easeInOut, value: currentIndex)
            .frame(height: 400)
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }

            HStack {
                Button(action: {
                    withAnimation {
                        if currentIndex > 0 {
                            currentIndex -= 1
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(currentIndex == 0 ? .gray : .blue)
                        .padding()
                }
                .disabled(currentIndex == 0)

                Spacer()

                HStack(spacing: 10) {
                    ForEach(0..<slides.count, id: \ .self) { idx in
                        Circle()
                            .fill(idx == currentIndex ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                Button(action: {
                    onStart?()
                }) {
                    Text("Начать")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 44)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Timer Logic

    func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            withAnimation {
                if currentIndex < slides.count - 1 {
                    currentIndex += 1
                } else {
                    currentIndex = 0
                }
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
