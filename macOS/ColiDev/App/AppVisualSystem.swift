import AppKit
import SwiftUI

struct ColorToken: Equatable {
    let lightHex: UInt32
    let darkHex: UInt32

    var color: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return Self.nsColor(hex: isDark ? darkHex : lightHex)
        })
    }

    private static func nsColor(hex: UInt32) -> NSColor {
        NSColor(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum ColiDevVisualSystem {
    static let soundPreferenceKey = "colidev.soundEffectsEnabled"
    static let routineTransitionDuration = 0.18

    static func subjectToken(_ subject: String) -> ColorToken {
        switch subject {
        case "mathematics": return ColorToken(lightHex: 0x5747B8, darkHex: 0xB6A8FF)
        case "english": return ColorToken(lightHex: 0xB64B2B, darkHex: 0xFF9778)
        case "physics": return ColorToken(lightHex: 0x176FAD, darkHex: 0x68B9FF)
        case "biology": return ColorToken(lightHex: 0x1F7652, darkHex: 0x65D39B)
        case "zoology": return ColorToken(lightHex: 0x8A5E13, darkHex: 0xF2BD63)
        case "programming": return ColorToken(lightHex: 0x0E6F79, darkHex: 0x55D4DF)
        default: return ColorToken(lightHex: 0x405F9B, darkHex: 0x91B9FF)
        }
    }

    static func subjectColor(_ subject: String) -> Color {
        subjectToken(subject).color
    }
}

enum AppSoundFeedback {
    private static let completionSound = NSSound(named: NSSound.Name("Glass"))

    static func playCompletion() {
        guard UserDefaults.standard.bool(forKey: ColiDevVisualSystem.soundPreferenceKey),
              let sound = completionSound else {
            return
        }
        sound.play()
    }
}

struct ColiDevGlassControlModifier: ViewModifier {
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            legacyMaterial(content)
        }
#else
        legacyMaterial(content)
#endif
    }

    private func legacyMaterial(_ content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        return content
            .background(.regularMaterial, in: shape)
            .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

extension View {
    func coliGlassControl(cornerRadius: CGFloat = 16) -> some View {
        modifier(ColiDevGlassControlModifier(cornerRadius: cornerRadius))
    }
}
