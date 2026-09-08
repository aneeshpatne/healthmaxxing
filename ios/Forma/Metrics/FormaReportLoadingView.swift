import SwiftUI
import WebKit

/// Full-screen brand motion shown only while the server is generating a report.
struct FormaReportLoadingView: View {
    let status: String
    var context = "REPORT GENERATION"
    var showsSuccess = false
    var isMinimal = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealsGeometry = false
    @State private var revealsMark = false
    @State private var revealsWordmark = false
    @State private var loadingWord = Self.loadingWords.randomElement() ?? "Brewing"

    private let mint = Color(red: 0, green: 0.918, blue: 0.796)
    private let lime = Color(red: 0.667, green: 1, blue: 0.31)
    private static let loadingWords = [
        "Brewing",
        "Analyzing",
        "Distilling",
        "Refining",
        "Shaping"
    ]

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(min(proxy.size.width * 0.82, proxy.size.height * 0.62), 650)

            ZStack {
                if !isMinimal {
                    Color(red: 0.027, green: 0.035, blue: 0.039)
                    ambientBackground(size: proxy.size)

                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, mint.opacity(0.14), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 1)
                        .scaleEffect(x: revealsGeometry ? 1 : 0.35)

                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, mint.opacity(0.14), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 1)
                        .scaleEffect(y: revealsGeometry ? 1 : 0.35)

                    concentricRings(diameter: diameter)
                }

                if showsSuccess {
                    VStack(spacing: 18) {
                        FormaReportSuccessMark(mint: mint, diameter: min(diameter * 0.34, 170))

                        Text("Ready")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(2.2)
                            .foregroundStyle(Color.white.opacity(0.48))
                    }
                    .transition(.scale(scale: 0.72).combined(with: .opacity))
                } else {
                    animatedMark(diameter: diameter)
                        .transition(.opacity)
                }

                if !isMinimal {
                    VStack {
                        header
                        Spacer()

                        if context != "REPORT GENERATION" {
                            statusLabel
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .task { await reveal() }
        .animation(.spring(duration: 0.55, bounce: 0.2), value: showsSuccess)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(showsSuccess ? "Your report is ready." : "Forma is generating your report. \(status)")
        .accessibilityIdentifier("metrics-loading")
    }

    private func ambientBackground(size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [mint.opacity(0.12), .clear],
                center: UnitPoint(x: 0.48, y: 0.43),
                startRadius: 0,
                endRadius: min(size.width, size.height) * 0.42
            )
            RadialGradient(
                colors: [lime.opacity(0.055), .clear],
                center: UnitPoint(x: 0.6, y: 0.56),
                startRadius: 0,
                endRadius: min(size.width, size.height) * 0.48
            )
        }
    }

    private func concentricRings(diameter: CGFloat) -> some View {
        ZStack {
            ForEach([1.0, 0.79, 0.56], id: \.self) { scale in
                Circle()
                    .stroke(mint.opacity(0.13), lineWidth: 0.7)
                    .frame(width: diameter * scale, height: diameter * scale)
            }
        }
        .opacity(revealsGeometry ? 1 : 0)
        .scaleEffect(revealsGeometry ? 1 : 0.72)
        .rotationEffect(.degrees(revealsGeometry ? 0 : -8))
        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: reduceMotion ? 0 : 1.8), value: revealsGeometry)
    }

    private func animatedMark(diameter: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let drift = reduceMotion ? 0 : sin(time * 0.8)

            VStack(spacing: 2) {
                FormaSVGPathAnimation(reduceMotion: reduceMotion)
                    .frame(width: diameter * 0.42, height: diameter * 0.42)
                    .shadow(color: Color.black.opacity(0.8), radius: 28, y: 22)
                    .offset(y: drift * 3)

                if !isMinimal {
                    Text("Forma")
                        .font(FormaTypography.wordmark(size: min(diameter * 0.14, 84)))
                        .tracking(-2)
                        .foregroundStyle(Color(red: 0.94, green: 1, blue: 0.98))
                        .opacity(revealsWordmark ? 1 : 0)
                        .blur(radius: revealsWordmark ? 0 : 7)
                        .offset(y: revealsWordmark ? 0 : 18)
                }

                Text(context == "REPORT GENERATION" ? loadingWord : "Initializing")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(2.2)
                    .foregroundStyle(Color.white.opacity(0.48))
                    .opacity(revealsWordmark ? 1 : 0)
                    .padding(.top, 8)
            }
            .opacity(revealsMark ? 1 : 0)
            .scaleEffect(revealsMark ? 0.9 : 0.68)
            .rotation3DEffect(.degrees(revealsMark ? drift : 58), axis: (x: 1, y: 0.18, z: -0.08))
            .animation(.timingCurve(0.22, 0.78, 0.2, 1, duration: reduceMotion ? 0 : 2.4), value: revealsMark)
            .animation(.timingCurve(0.16, 1, 0.3, 1, duration: reduceMotion ? 0 : 1), value: revealsWordmark)
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(mint)
                    .frame(width: 5, height: 5)
                    .shadow(color: mint, radius: 6)

                Text("FORMA / ACTIVE")
            }

            Spacer()
            Text(showsSuccess ? "REPORT COMPLETE" : context)
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .tracking(1.7)
        .foregroundStyle(Color.white.opacity(0.44))
        .opacity(revealsWordmark ? 1 : 0)
    }

    private var statusLabel: some View {
        Text(status.uppercased())
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(Color.white.opacity(0.44))
            .padding(.bottom, 10)
            .opacity(revealsWordmark ? 1 : 0)
    }

    @MainActor
    private func reveal() async {
        if reduceMotion {
            revealsGeometry = true
            revealsMark = true
            revealsWordmark = true
            return
        }

        withAnimation { revealsGeometry = true }
        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }
        withAnimation { revealsMark = true }
        try? await Task.sleep(for: .milliseconds(900))
        guard !Task.isCancelled else { return }
        withAnimation { revealsWordmark = true }
    }
}

/// Renders the original SVG geometry so the outline is genuinely drawn along
/// each path, rather than revealing or transforming a pre-rendered image.
private struct FormaSVGPathAnimation: UIViewRepresentable {
    let reduceMotion: Bool

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        webView.accessibilityElementsHidden = true
        webView.loadHTMLString(Self.html(reduceMotion: reduceMotion), baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    private static func html(reduceMotion: Bool) -> String {
        let motionOverride = reduceMotion
            ? "*{animation-duration:1ms!important;animation-delay:0ms!important;animation-iteration-count:1!important}"
            : ""

        return """
        <!doctype html>
        <html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        *{box-sizing:border-box}html,body{width:100%;height:100%;margin:0;overflow:hidden;background:transparent}
        body{display:grid;place-items:center}
        svg{display:block;width:100%;height:100%;overflow:visible;filter:drop-shadow(0 18px 28px rgba(0,4,3,.82))}
        .trace,.bloom{fill:none;vector-effect:non-scaling-stroke;stroke-dasharray:1;stroke-dashoffset:1}
        .trace{stroke:rgba(218,255,244,.72);stroke-width:.55;animation:draw 4.8s var(--delay) cubic-bezier(.65,0,.22,1) infinite}
        .bloom{stroke:url(#gradient);stroke-width:2.5;filter:url(#glow);animation:bloom 4.8s var(--delay) cubic-bezier(.65,0,.22,1) infinite}
        .face{opacity:0;animation:fill 4.8s var(--fill-delay) cubic-bezier(.16,.8,.2,1) infinite}
        .main{fill:url(#gradient)}.ribbon{fill:url(#ribbon)}
        .comet{fill:none;stroke:url(#comet);stroke-width:1.4;stroke-linecap:round;vector-effect:non-scaling-stroke;filter:url(#hot);opacity:0;stroke-dasharray:.012 .988;animation:cometOn .6s 3.5s forwards,comet 3.2s 3.5s linear infinite}
        @keyframes draw{0%,8%{opacity:0;stroke-dashoffset:1}18%{opacity:.82}62%{opacity:.82;stroke-dashoffset:0}88%{opacity:.18;stroke-dashoffset:0}100%{opacity:0;stroke-dashoffset:1}}
        @keyframes bloom{0%,8%{opacity:0;stroke-dashoffset:1}18%{opacity:.48}58%{opacity:.7;stroke-dashoffset:0}78%,100%{opacity:0;stroke-dashoffset:0}}
        @keyframes fill{0%,34%{opacity:0;transform:scale(.985);transform-origin:center}48%,82%{opacity:1;transform:scale(1)}100%{opacity:0;transform:scale(1)}}
        @keyframes cometOn{to{opacity:.95}}@keyframes comet{to{stroke-dashoffset:-1}}
        \(motionOverride)
        </style></head><body>
        <svg viewBox="0 0 160 160" aria-hidden="true">
          <defs>
            <linearGradient id="gradient" x1="50.3" x2="108.1" y1="11.83" y2="150.1" gradientUnits="userSpaceOnUse"><stop stop-color="#00eae5"/><stop offset=".5056" stop-color="#01edb1"/><stop offset="1" stop-color="#afff4f"/></linearGradient>
            <linearGradient id="ribbon" x1="66.09" x2="88.46" y1="29.42" y2="51.78" gradientUnits="userSpaceOnUse"><stop stop-color="#00daca"/><stop offset="1" stop-color="#01dfbc"/></linearGradient>
            <linearGradient id="comet"><stop stop-color="#fff" stop-opacity="0"/><stop offset=".65" stop-color="#dcfff5" stop-opacity=".35"/><stop offset="1" stop-color="#fff"/></linearGradient>
            <filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="2.6"/></filter>
            <filter id="hot" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation=".8" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
            <path id="main" pathLength="1" d="m103.5 148.6c-3.6-2.1-19.9-13.7-15.1-31.4 1.4-5.2 3.5-8.8 4.8-14.7 2-10.8-3.1-21-15.2-22.8-1.5-.2-3.5-.3-4.9-.2-15.4.6-31.9 15.5-31.9 34.4.3 12.6 9.4 32.2 39.2 37.6-9.1-3.1-26.5-12.9-26.5-30.7 0-8.2 5.4-17.4 13.7-17.4 6.4.2 9.9 6.8 5.4 13.1-2 2.8-3.1 6-2.9 9.7.3 6.5 6.9 18.9 27.6 25.3 1.3.3 1.2 2.3-.1 2.6-4.3 1.1-9.3 1.9-15.6 1.9-30.6 0-58.2-20-58.2-50.1 0-25.9 21.2-38.3 25.8-46.6 3.5-5.7 3.4-11.8.5-15.9-2.2-3.4-4.3-7.9-4.3-13-.1-12 11.2-27.5 30.2-27.5 15.9 0 22.5 10.8 22.5 21.7l.1 6.3c.3 16.6 16.7 11.1 28.7 25 6.7 7.6 9.8 16.5 9.8 28.1-.6 29.2-23 32.6-22.5 59.9.2 1.5-1.1 1.6-1.4.4-2.5-8.3-2.5-17.3 3.7-27 4.1-6.6 11-14.3 11-30.2s-7.9-25.1-18.1-30.8c-10-5.6-17.9-9.2-17.9-21.8v-3.1c0-8.9-4.3-17.1-14.8-17.1-10.9 0-20 8.9-20 18 0 3.2 1.2 6.4 4 10.1 2.4 3 4 5.8 3.9 10.1-.7 16.9-15.8 20.9-23.5 34.5-3.8 6.3-6 13.4-5.9 20.8.7 30.8 27.9 41.1 44.4 43.4-16.5-.8-43.6-11.1-43.7-38.2-.1-21.1 18.6-40.6 38.4-40.6 13.7 0 23.8 9.6 23.8 23.6 0 11-5.4 16-6.1 26.2-.2 9.2 3.7 17.7 11.7 25.7.3.3 0 1-.6.7z"/>
            <path id="ribbonPath" pathLength="1" d="m65.6 34c0-4.7 3.8-10 9.4-10 4.9 0 9 3.5 9 10 .1 6.9-3.2 14.6 6.8 22.6 9.5 7.3 28.3 11.3 28.3 32.3 0 17-12.9 23.7-12.9 42.1 0 4.4 1.1 10.1 3.9 16.3.6 1.1-1.7 2-2.5.9-7.2-7.8-10.3-14.3-10.3-22.7.3-15.1 10.3-21.4 10.3-36.1 0-25.4-27.5-27.6-38.2-45.9-2.1-2.4-3.8-5.5-3.8-9.5z"/>
          </defs>
          <use href="#main" class="bloom" style="--delay:.15s;--time:2.35s"/><use href="#main" class="trace" style="--delay:.15s;--time:2.35s"/>
          <use href="#ribbonPath" class="bloom" style="--delay:.62s;--time:1.8s"/><use href="#ribbonPath" class="trace" style="--delay:.62s;--time:1.8s"/>
          <use href="#main" class="face main" style="--fill-delay:1.85s"/><use href="#ribbonPath" class="face ribbon" style="--fill-delay:2.05s"/>
          <use href="#main" class="comet"/>
        </svg></body></html>
        """
    }
}

private struct FormaReportSuccessMark: View {
    let mint: Color
    let diameter: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ringScale: CGFloat = 0.72
    @State private var checkProgress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(mint.opacity(0.1))
                .overlay(Circle().stroke(mint.opacity(0.72), lineWidth: 1.5))
                .shadow(color: mint.opacity(0.35), radius: 24)

            CheckmarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(mint, style: StrokeStyle(lineWidth: diameter * 0.075, lineCap: .round, lineJoin: .round))
                .frame(width: diameter * 0.48, height: diameter * 0.38)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(ringScale)
        .task {
            if reduceMotion {
                ringScale = 1
                checkProgress = 1
                return
            }

            withAnimation(.spring(duration: 0.5, bounce: 0.28)) { ringScale = 1 }
            try? await Task.sleep(for: .milliseconds(160))
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.42)) { checkProgress = 1 }
        }
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY * 1.03))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview {
    FormaReportLoadingView(status: "Report running.")
}
