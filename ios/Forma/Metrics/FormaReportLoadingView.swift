import SwiftUI
import Lottie

/// Only real report work gets a loading state; there is no timed brand intro.
struct FormaReportLoadingView: View {
    let status: String
    var context = "REPORT GENERATION"
    var showsSuccess = false
    var isMinimal = true

    var body: some View {
        VStack(spacing: FormaSpacing.lg) {
            if showsSuccess {
                Image(forma: "checkmark.circle.fill")
                    .resizable().scaledToFit().frame(width: 40, height: 40)
                    .foregroundStyle(Color.formaPositive)
            } else {
                FormaReportLoadingAnimation()
            }
            Text(showsSuccess ? "Report ready" : "Preparing your report")
                .font(FormaTypography.sectionHeadline)
                .foregroundStyle(Color.formaTextPrimary)
            Text(status)
                .font(FormaTypography.supporting)
                .foregroundStyle(Color.formaTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(FormaSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isMinimal ? Color.clear : Color.appBackground)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("metrics-loading")
    }
}

private struct FormaReportLoadingAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LottieView(animation: Self.animation)
            .configure { view in
                view.contentMode = .scaleAspectFit
                view.backgroundBehavior = .pauseAndRestore
                view.isUserInteractionEnabled = false
                view.backgroundColor = .clear
            }
            .playbackMode(
                reduceMotion
                    ? .paused(at: .frame(10))
                    : .playing(.fromProgress(0, toProgress: 1, loopMode: .loop))
            )
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 340, maxHeight: 340)
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    private static let animation = LottieAnimation.named("ExerciseLoader", bundle: .main)
}

#Preview { FormaReportLoadingView(status: "Analyzing your measurements") }
