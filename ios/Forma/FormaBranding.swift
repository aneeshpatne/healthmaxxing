import SwiftUI

enum FormaBrandLockupVariant {
    case header
    case hero

    fileprivate var textSize: CGFloat {
        switch self {
        case .header: 30
        case .hero: 56
        }
    }

    fileprivate var markSize: CGSize {
        switch self {
        case .header: CGSize(width: 30, height: 30)
        case .hero: CGSize(width: 48, height: 48)
        }
    }

    fileprivate var spacing: CGFloat {
        switch self {
        case .header: 8
        case .hero: 14
        }
    }

    fileprivate var tracking: CGFloat {
        switch self {
        case .header: -0.55
        case .hero: -1.2
        }
    }
}

struct FormaBrandLockup: View {
    let variant: FormaBrandLockupVariant
    var wordmarkColor: Color = .primary

    var body: some View {
        HStack(alignment: .center, spacing: variant.spacing) {
            Image("vectorized_019fd7b0-2531-7c0a-98f7-fb339b707a32")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: variant.markSize.width, height: variant.markSize.height)
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
