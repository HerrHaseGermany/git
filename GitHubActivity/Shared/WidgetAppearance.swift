import SwiftUI

// sRGB values sampled from the supplied original widget after ICC conversion.
enum WidgetAppearance {
    static let activityColors: [Color] = [
        rgb(0x0D1117), rgb(0x012D11), rgb(0x054F1E), rgb(0x1B7F37), rgb(0x2BA44E)
    ]
    static var background: LinearGradient {
        LinearGradient(stops: [
            .init(color: rgb(0x202020), location: 0),
            .init(color: rgb(0x171717), location: 0.46),
            .init(color: rgb(0x0B0B0B), location: 1)
        ], startPoint: .top, endPoint: .bottom)
    }
    private static func rgb(_ hex: UInt32) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255, opacity: 1)
    }
}
