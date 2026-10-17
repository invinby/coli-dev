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

    static let managementKnowledge = ColorToken(lightHex: 0x4B4294, darkHex: 0xB6A9FF)
    static let managementSources = ColorToken(lightHex: 0x0E6F66, darkHex: 0x68DCCB)
    static let managementReviewDue = ColorToken(lightHex: 0xA64055, darkHex: 0xFF98AA)

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

    static func studyAccentToken(subjectID: String, resource: String? = nil) -> ColorToken {
        let resolvedSubjectID: String
        switch subjectID {
        case "intro":
            resolvedSubjectID = resource ?? ""
        case let value where value.hasPrefix("custom-builtin:"):
            resolvedSubjectID = String(value.dropFirst("custom-builtin:".count))
        case let value where value.hasPrefix("custom-user:"):
            resolvedSubjectID = "custom-user"
        default:
            resolvedSubjectID = subjectID
        }
        return subjectToken(resolvedSubjectID)
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

struct ColiDevContentCardModifier: ViewModifier {
    let tint: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        content
            .background {
                shape
                    .fill(.regularMaterial)
                    .overlay {
                        LinearGradient(
                            colors: [tint.opacity(0.15), tint.opacity(0.035)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(shape)
                    }
            }
            .overlay {
                shape.strokeBorder(tint.opacity(0.20), lineWidth: 1)
            }
    }
}

extension View {
    func coliGlassControl(cornerRadius: CGFloat = 16) -> some View {
        modifier(ColiDevGlassControlModifier(cornerRadius: cornerRadius))
    }

    func coliContentCard(tint: Color, cornerRadius: CGFloat = 16) -> some View {
        modifier(ColiDevContentCardModifier(tint: tint, cornerRadius: cornerRadius))
    }
}
