import SwiftUI

/// Fork replacement for the upstream logo: three equalizer bars, in unit coordinates.
/// Keeps the upstream API (`LogoShape`, `AppLogo`, `menuBarImage`) so the rest of the
/// app compiles unchanged. Installed by fork/debrand.sh.
struct LogoShape: Shape {
    static let aspectRatio: CGFloat = 223.0 / 256.0

    /// (x, width, height) of each bar, bottom aligned.
    private static let bars: [(x: CGFloat, width: CGFloat, height: CGFloat)] = [
        (0, 0.26, 0.55),
        (0.37, 0.26, 1),
        (0.74, 0.26, 0.75),
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for bar in Self.bars {
            let width = bar.width * rect.width
            let height = bar.height * rect.height
            let barRect = CGRect(x: rect.minX + bar.x * rect.width, y: rect.maxY - height,
                                 width: width, height: height)
            path.addRoundedRect(in: barRect, cornerSize: CGSize(width: width / 2, height: width / 2))
        }
        return path
    }
}

/// The app glyph. In glass mode it's clear Liquid Glass in the glyph's outline, like
/// the playback icons; otherwise white, tinted with `color` (the song's colour) when given.
struct AppLogo: View {
    let height: CGFloat
    let glass: Bool
    /// White mixed into the glass, for the selected state.
    var highlight: Double = 0
    var color: Color? = nil

    /// No bitmap logo in the fork; callers fall back to drawing `LogoShape`.
    static let image: NSImage? = nil

    var body: some View {
        let size = CGSize(width: height * LogoShape.aspectRatio, height: height)
        Group {
            if glass {
                GlassIcon(shape: LogoShape(), size: size, highlight: highlight)
            } else {
                LogoShape().fill(color ?? .white)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

extension LogoShape {
    /// The glyph as a template image for the menu bar (tinted by macOS).
    static func menuBarImage(height: CGFloat = 14) -> NSImage {
        let size = NSSize(width: (height * aspectRatio).rounded(.up), height: height)
        let image = NSImage(size: size, flipped: true) { rect in
            NSColor.black.setFill()
            NSBezierPath(cgPath: LogoShape().path(in: rect).cgPath).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
