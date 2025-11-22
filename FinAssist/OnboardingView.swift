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
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentIndex) {
                    ForEach(0..<slides.count, id: \.self) { idx in
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: slides[idx].imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .foregroundColor(AppColors.primary)
                            Text(slides[idx].text)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 24)
                            Spacer()
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentIndex) { newValue in
                    stopTimer()
                    startTimer()
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    stopTimer()
                }

                // Индикаторы страниц
                HStack(spacing: 10) {
                    ForEach(0..<slides.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == currentIndex ? AppColors.primary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)

                // Кнопка "Начать" внизу экрана
                if currentIndex == slides.count - 1 {
                    Button(action: {
                        stopTimer()
                        onStart?()
                    }) {
                        Text("Начать")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.primary)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
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
