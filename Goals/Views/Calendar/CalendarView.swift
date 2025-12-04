//
//  CalendarView.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 20-10-25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    let topic: Topic
    private let topicID: Topic.ID

    @Query private var topicSessions: [StudySession]
    @State private var completionCache: [Date: Bool] = [:]
    @State private var monthOffset: Int = 0   // 0 = current month, -1 = previous, etc.

    init(topic: Topic)
    {
        self.topic = topic
        self.topicID = topic.id

        let topicID = topic.id
        self._topicSessions = Query(filter: #Predicate<StudySession> { session in
            session.topic.id == topicID
        })
    }

    private let calendar: Calendar =
    {
        var cal = Calendar.current
        cal.firstWeekday = Calendar.current.firstWeekday
        return cal
    }()

    private let today = Date()

    // MARK: - Progress logic (unchanged)

    private func earliestTopicDay() -> Date?
    {
        topicSessions.map(\.normalizedDay).min()
    }

    // Show indicator only for past days. For today, only if the goal was met.
    private func shouldShowIndicator(on date: Date) -> Bool
    {
        if topicSessions.isEmpty { return false }

        let startOfDate = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: today)

        if let rawFirstDay = earliestTopicDay() {
            let firstDay = calendar.startOfDay(for: rawFirstDay)
            if startOfDate < firstDay { return false }
        }

        if startOfDate < startOfToday { return true }
        if calendar.isDate(startOfDate, inSameDayAs: startOfToday) { return isCompleted(on: date) }
        return false
    }

    private func isCompleted(on date: Date) -> Bool
    {
        let dayKey = calendar.startOfDay(for: date)

        let sessionsForDay = topicSessions.filter { session in
            calendar.isDate(session.normalizedDay, inSameDayAs: dayKey)
        }

        guard let status = DailyStatus.compute(from: sessionsForDay) else {
            return false
        }

        return status.isMet.contains(true)
    }

    // MARK: - Month navigation (same logic as Habits)

    private var todayStart: Date {
        calendar.startOfDay(for: today)
    }

    /// First day of the base month (current) shifted by `monthOffset`
    private var startOfMonth: Date
    {
        let components = calendar.dateComponents([.year, .month], from: todayStart)
        let baseMonthStart = calendar.date(from: components) ?? todayStart
        return calendar.date(byAdding: .month, value: monthOffset, to: baseMonthStart) ?? baseMonthStart
    }

    private var monthTitle: String
    {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: startOfMonth)
    }

    private var canGoNextMonth: Bool {
        monthOffset < 0 // never go into the future
    }

    private var canGoPreviousMonth: Bool {
        true // you can later clamp this using earliestTopicDay()
    }

    private func goToPreviousMonth() {
        monthOffset -= 1
    }

    private func goToNextMonth() {
        guard canGoNextMonth else { return }
        monthOffset += 1
    }

    // MARK: - Body

    var body: some View
    {
        ScrollView
        {
            VStack(spacing: 20)
            {
                header

                // Calendar card
                VStack(spacing: 12)
                {
                    WeekdayRow(calendar: calendar)

                    MonthGrid(
                        month: startOfMonth,
                        calendar: calendar,
                        today: today,
                        isCompleted: isCompleted(on:),
                        shouldShowIndicator: shouldShowIndicator(on:)
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 16)
            }
            .padding(.top, 16)
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

// MARK: - Header with arrows

private extension CalendarView
{
    var header: some View
    {
        // Brand colors
        let brandLight = Color(red: 63/255, green: 167/255, blue: 214/255) // #3FA7D6
        let brandDark  = Color(red: 29/255, green: 53/255,  blue: 87/255)  // #1D3557

        return ZStack
        {
            LinearGradient(
                colors: [brandDark, brandLight],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.18)
            .ignoresSafeArea(edges: .horizontal)

            HStack(alignment: .center, spacing: 16)
            {
                Button
                {
                    goToPreviousMonth()
                }
                label:
                {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                        )
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!canGoPreviousMonth)
                .opacity(canGoPreviousMonth ? 1 : 0.35)

                Spacer(minLength: 8)

                VStack(spacing: 4)
                {
                    Text(monthTitle)
                        .font(.headline.weight(.semibold))

                    Text("See your study streak for this topic")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                Spacer(minLength: 8)

                Button
                {
                    goToNextMonth()
                }
                label:
                {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                        )
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(!canGoNextMonth)
                .opacity(canGoNextMonth ? 1 : 0.35)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Weekday row

private struct WeekdayRow: View
{
    let calendar: Calendar

    var body: some View
    {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let ordered = Array(symbols[calendar.firstWeekday-1..<symbols.count]) + Array(symbols[0..<calendar.firstWeekday-1])

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7))
        {
            ForEach(ordered, id: \.self)
            { s in
                Text(s.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Month grid

private struct MonthGrid: View
{
    let month: Date
    let calendar: Calendar
    let today: Date
    let isCompleted: (Date) -> Bool
    let shouldShowIndicator: (Date) -> Bool

    var body: some View
    {
        let days = makeDays()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 24), spacing: 0), count: 7), spacing: 10)
        {
            ForEach(days, id: \.self)
            { day in
                if let dayDate = day.date
                {
                    DayCell(
                        date: dayDate,
                        isToday: calendar.isDate(dayDate, inSameDayAs: today),
                        inCurrentMonth: day.inCurrentMonth,
                        completed: isCompleted(dayDate),
                        showIndicator: shouldShowIndicator(dayDate)
                    )
                    .frame(height: 44)
                }
                else
                {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    // Build slots including leading blanks to align weekdays
    private func makeDays() -> [DaySlot]
    {
        let range = calendar.range(of: .day, in: .month, for: month) ?? (1..<31)
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let firstWeekdayIndex = calendar.component(.weekday, from: firstOfMonth)

        let leadingEmpty = (firstWeekdayIndex - calendar.firstWeekday + 7) % 7

        var result: [DaySlot] = []
        result.append(contentsOf: Array(repeating: DaySlot(date: nil, inCurrentMonth: false), count: leadingEmpty))

        for day in range
        {
            if let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth)
            {
                result.append(DaySlot(date: date, inCurrentMonth: true))
            }
        }

        while result.count % 7 != 0
        {
            result.append(DaySlot(date: nil, inCurrentMonth: false))
        }
        return result
    }

    struct DaySlot: Hashable
    {
        let date: Date?
        let inCurrentMonth: Bool
    }
}

// MARK: - Day cell (new elegant design)

private struct DayCell: View
{
    let date: Date
    let isToday: Bool
    let inCurrentMonth: Bool
    let completed: Bool
    let showIndicator: Bool

    // Brand colors
    private var brandLight: Color {
        Color(red: 63/255, green: 167/255, blue: 214/255) // #3FA7D6
    }

    private var brandDark: Color {
        Color(red: 29/255, green: 53/255, blue: 87/255)   // #1D3557
    }

    private var successGradient: LinearGradient {
        LinearGradient(
            colors: [brandLight, brandDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private enum VisualStatus {
        case none      // no indicator (future, before start, etc.)
        case success   // goal met
        case missed    // goal not met
    }

    private var status: VisualStatus {
        guard showIndicator else { return .none }
        return completed ? .success : .missed
    }

    var body: some View
    {
        let config = colorsAndIcon(for: status)

        return ZStack
        {
            // Base circle with background + border
            Circle()
                .fill(config.bg)
                .overlay(
                    Circle()
                        .strokeBorder(config.border, lineWidth: 1.4)
                )
                .frame(width: 32, height: 32)
                .overlay(
                    // Extra ring for "today" when there is no status yet
                    Group {
                        if isToday && status == .none {
                            Circle()
                                .strokeBorder(brandLight.opacity(0.9), lineWidth: 1.6)
                        }
                    }
                )

            // Day number
            Text(dayNumber)
                .font(.subheadline.weight(isToday ? .semibold : .regular))
                .foregroundStyle(config.text)

            // Icon (check / x) in the corner when applicable
            if let iconName = config.iconName
            {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: iconName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(config.iconColor)
                            .padding(2)
                    }
                }
            }
        }
        .frame(height: 40)
        .opacity(inCurrentMonth ? 1 : 0.4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var dayNumber: String
    {
        let comps = Calendar.current.dateComponents([.day], from: date)
        return String(comps.day ?? 0)
    }

    private func colorsAndIcon(for status: VisualStatus)
        -> (bg: AnyShapeStyle, border: Color, text: Color, iconName: String?, iconColor: Color)
    {
        switch status {
        case .success:
            return (
                bg: AnyShapeStyle(successGradient),
                border: .clear,
                text: .white,
                iconName: "checkmark",
                iconColor: .white
            )

        case .missed:
            return (
                bg: AnyShapeStyle(Color.clear),
                border: Color.red.opacity(0.75),
                text: .primary,
                iconName: "xmark",
                iconColor: Color.red.opacity(0.9)
            )

        case .none:
            if inCurrentMonth {
                return (
                    bg: AnyShapeStyle(Color.secondary.opacity(0.08)),
                    border: Color.secondary.opacity(0.15),
                    text: .primary,
                    iconName: nil,
                    iconColor: .clear
                )
            } else {
                return (
                    bg: AnyShapeStyle(Color.clear),
                    border: Color.clear,
                    text: Color.secondary.opacity(0.4),
                    iconName: nil,
                    iconColor: .clear
                )
            }
        }
    }

    private var accessibilityText: String
    {
        let df = DateFormatter()
        df.dateStyle = .full
        let base = df.string(from: date)

        switch status {
        case .success:
            return "\(base), goal met"
        case .missed:
            return "\(base), goal not met"
        case .none:
            return base
        }
    }
}

// MARK: - Blur helper

private struct VisualEffectBlur: UIViewRepresentable
{
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView
    {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview("Dark")
{
    CalendarView(topic: SampleData.shared.topic)
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    CalendarView(topic: SampleData.shared.topic)
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.light)
}
