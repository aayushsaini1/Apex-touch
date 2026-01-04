import Foundation
import CoreText
import SwiftUI

enum CustomFont {
    static func register() {
        guard let fontURL = Bundle.main.url(forResource: "Orbitron", withExtension: "ttf") else {
            print("Orbitron.ttf not found in bundle")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            print("Failed to register font: \(error!.takeRetainedValue())")
        } else {
            print("Orbitron font registered successfully")
        }
    }
}

extension Font {
    static func orbitron(size: CGFloat, weight: CGFloat = 400) -> Font {
        let fontName = "Orbitron"
        
        // NSCTFontVariationAttribute is the underlying key for variable font axes
        let variationKey = UIFontDescriptor.AttributeName(rawValue: "NSCTFontVariationAttribute")
        
        // 2003265652 is the 'wght' axis tag
        let variation: [NSNumber: Any] = [
            2003265652 as NSNumber: weight as NSNumber
        ]
        
        let descriptor = UIFontDescriptor(name: fontName, size: size)
            .addingAttributes([
                variationKey: variation
            ])
        
        let uiFont = UIFont(descriptor: descriptor, size: size)
        return Font(uiFont)
    }
}
