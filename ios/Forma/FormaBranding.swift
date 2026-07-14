import SwiftUI

enum FormaBrandLockupVariant {
    case header
    case hero

    fileprivate var textSize: CGFloat {
        switch self {
        case .header: 28
        case .hero: 50
        }
    }

    fileprivate var markSize: CGSize {
        switch self {
        case .header: CGSize(width: 24, height: 32)
        case .hero: CGSize(width: 34, height: 46)
        }
    }

    fileprivate var markCanvasSize: CGFloat {
        switch self {
        case .header: 64
        case .hero: 92
        }
    }

    fileprivate var spacing: CGFloat {
        switch self {
        case .header: 8
        case .hero: 12
        }
    }

    fileprivate var tracking: CGFloat {
        switch self {
        case .header: -0.45
        case .hero: -1
        }
    }
}

struct FormaBrandLockup: View {
    let variant: FormaBrandLockupVariant
    var wordmarkColor: Color = .primary

    var body: some View {
        HStack(alignment: .center, spacing: variant.spacing) {
            Image("Frame 55(3)")
                .resizable()
                .scaledToFit()
                .frame(width: variant.markCanvasSize, height: variant.markCanvasSize)
                .frame(width: variant.markSize.width, height: variant.markSize.height)
                .clipped()
                .accessibilityHidden(true)

            Text("Forma")
                .font(FormaTypography.wordmark(size: variant.textSize))
                .tracking(variant.tracking)
                .foregroundStyle(wordmarkColor)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Forma")
    }
}

#Preview("Brand lockups") {
    VStack(alignment: .leading, spacing: FormaSpacing.xxl) {
        FormaBrandLockup(variant: .header)
        FormaBrandLockup(variant: .hero)
    }
    .padding(FormaSpacing.xxl)
    .background(FormaBackground())
}
