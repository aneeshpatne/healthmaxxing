//
//  CormorantGaramondFont.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI
import CoreText

enum CormorantGaramond {
    static var fontName: String = "CormorantGaramond"
    private static var registered = false

    static func registerIfNeeded() {
        guard !registered else { return }
        registered = true

        guard let url = Bundle.main.url(forResource: "CormorantGaramond-VariableFont_wght", withExtension: "ttf") else {
            return
        }

        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)

        if let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
           let name = descriptors.first.flatMap({ CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String }) {
            fontName = name
        }
    }
}

extension Font {
    static func cormorantGaramond(size: CGFloat) -> Font {
        CormorantGaramond.registerIfNeeded()
        return .custom(CormorantGaramond.fontName, size: size)
    }
}
