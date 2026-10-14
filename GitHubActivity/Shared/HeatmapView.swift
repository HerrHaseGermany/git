import SwiftUI
import WidgetKit

struct HeatmapView: View {
    let days: [ContributionDay]
    var columns = 16
    @Environment(\.widgetRenderingMode) private var renderingMode
    private let intensity = [0.10, 0.28, 0.50, 0.74, 1.0]

    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 4
            let cell = min((geometry.size.width - CGFloat(columns - 1) * gap) / CGFloat(columns), (geometry.size.height - 6 * gap) / 7)
            let calendar = Self.calendar
            let today = calendar.startOfDay(for: Date())
            let latest = min(days.last.flatMap { Self.formatter.date(from: $0.date) } ?? today, today)
            let weekday = calendar.component(.weekday, from: latest) - 1
            let sunday = calendar.date(byAdding: .day, value: -weekday, to: latest)!
            let start = calendar.date(byAdding: .day, value: -7 * (columns - 1), to: sunday)!
            let startKey = Self.formatter.string(from: start)
            let latestKey = Self.formatter.string(from: latest)
            let visible = days.filter { $0.date >= startKey && $0.date <= latestKey }
            let levels = Dictionary(visible.map { day in
                (day.date, ContributionScale.level(day))
            }, uniquingKeysWith: { first, _ in first })
            HStack(spacing: gap) {
                ForEach(0..<columns, id: \.self) { column in
                    VStack(spacing: gap) {
                        ForEach(0..<7, id: \.self) { row in
                            let date = calendar.date(byAdding: .day, value: column * 7 + row, to: start)!
                            let key = Self.formatter.string(from: date)
                            let level = levels[key] ?? 0
                            RoundedRectangle(cornerRadius: max(2, cell * 0.09))
                                .fill(cellColor(level))
                                // Accented mode discards RGB; opacity retains the activity level.
                                .opacity((renderingMode == .accented ? intensity[level] : 1) * (date > latest ? 0.3 : 1))
                                .frame(width: cell, height: cell)
                                .accessibilityLabel(Text("\(key): activity level \(levels[key] ?? 0) of 4"))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    private func cellColor(_ level: Int) -> Color {
        switch renderingMode {
        case .accented: return .white
        case .vibrant: return Color(white: intensity[level])
        default: return WidgetAppearance.activityColors[level]
        }
    }
    static var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        return result
    }
    static var formatter: DateFormatter {
        let result = DateFormatter()
        result.calendar = calendar
        result.locale = Locale(identifier: "en_US_POSIX")
        result.timeZone = calendar.timeZone
        result.dateFormat = "yyyy-MM-dd"
        return result
    }
}
