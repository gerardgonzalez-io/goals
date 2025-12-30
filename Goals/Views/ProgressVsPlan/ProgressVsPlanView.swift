//
//  ProgressVsPlanView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 29-12-25.
//

import SwiftUI
import SwiftData
import Charts

struct ProgressVsPlanView: View
{
    let topic: Topic

    @Query private var sessions: [StudySession]

    @State private var selectedRange: ProgressVsPlan.Range = .days7
    @State private var pageOffset: Int = 0

    init(topic: Topic)
    {
        self.topic = topic

        let topicID = topic.id
        let predicate = #Predicate<StudySession> { session in
            session.topic.id == topicID
        }

        _sessions = Query(
            filter: predicate,
            sort: [SortDescriptor(\.startDate, order: .reverse)]
        )
    }

    private var report: ProgressVsPlan.Report
    {
        ProgressVsPlan.compute(
            topic: topic,
            sessions: sessions,
            range: selectedRange,
            pageOffset: pageOffset,
            now: Date()
        )
    }

    private var firstGoalDay: Date?
    {
        topic.goalChanges.map(\.effectiveFromDay).min()
    }

    private var canGoNext: Bool
    {
        // Apple-like: no “future” browsing; allow only going back and returning to current.
        pageOffset < 0
    }

    private var canGoPrevious: Bool
    {
        guard let fg = firstGoalDay else { return false }
        let cal = calendar
        let today = cal.startOfDay(for: Date())

        switch selectedRange
        {
        case .days7:
            let len = 7
            let prevEnd = cal.date(byAdding: .day, value: (pageOffset - 1) * len, to: today)!
            return cal.startOfDay(for: prevEnd) >= cal.startOfDay(for: fg)

        case .days30:
            let len = 30
            let prevEnd = cal.date(byAdding: .day, value: (pageOffset - 1) * len, to: today)!
            return cal.startOfDay(for: prevEnd) >= cal.startOfDay(for: fg)

        case .months12:
            let prevEnd = cal.date(byAdding: .month, value: (pageOffset - 1) * 12, to: today)!
            return cal.startOfDay(for: prevEnd) >= cal.startOfDay(for: fg)
        }
    }

    private var headerSubtitle: String
    {
        guard let first = report.points.first?.periodDate,
              let last  = report.points.last?.periodDate
        else
        {
            return selectedRangeLabel
        }

        switch selectedRange
        {
        case .days7, .days30:
            return "\(formatDay(first)) – \(formatDay(last))"
        case .months12:
            return "\(formatMonthYear(first)) – \(formatMonthYear(last))"
        }
    }

    var body: some View
    {
        ScrollView
        {
            VStack(spacing: 24)
            {
                header
                progressCard
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Header

private extension ProgressVsPlanView
{
    var header: some View
    {
        VStack(spacing: 8)
        {
            Text(topic.name)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Progress Card

private extension ProgressVsPlanView
{
    var progressCard: some View
    {
        VStack(spacing: 14)
        {
            cardTopBar
            kpisRow
            chartSection
            insightSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    var cardTopBar: some View
    {
        VStack(spacing: 10)
        {
            HStack
            {
                Text("Progress")
                    .font(.headline)

                Spacer()

                Picker("", selection: $selectedRange)
                {
                    Text("7D").tag(ProgressVsPlan.Range.days7)
                    Text("30D").tag(ProgressVsPlan.Range.days30)
                    Text("12M").tag(ProgressVsPlan.Range.months12)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)
            }

            HStack
            {
                Button
                {
                    guard canGoPrevious else { return }
                    pageOffset -= 1
                }
                label:
                {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .frame(width: 34, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(canGoPrevious ? .primary : .tertiary)
                .disabled(!canGoPrevious)

                Text(selectedRangeLabel.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button
                {
                    guard canGoNext else { return }
                    pageOffset += 1
                }
                label:
                {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 34, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(canGoNext ? .primary : .tertiary)
                .disabled(!canGoNext)

                Spacer()
            }
        }
    }

    var kpisRow: some View
    {
        HStack(spacing: 12)
        {
            KPIStat(
                title: "Actual",
                value: durationString(report.actualTotalMinutes),
                subtitle: selectedRangeShortLabel
            )

            KPIStat(
                title: "Plan",
                value: report.isPlanAvailable ? durationString(report.planTotalMinutes ?? 0) : "—",
                subtitle: report.isPlanAvailable ? "Target" : "Unavailable"
            )

            KPIStat(
                title: report.isPlanAvailable ? (report.status == .ahead ? "Ahead" : "Behind") : "Status",
                value: deltaString(deltaMinutes: report.deltaMinutes, status: report.status),
                subtitle: report.isPlanAvailable ? "vs plan" : "—",
                emphasized: true,
                emphasizedIsPositive: report.status == .ahead
            )
        }
    }

    var chartSection: some View
    {
        VStack(alignment: .leading, spacing: 10)
        {
            if report.points.isEmpty
            {
                // Should be rare because we clamp to first goal day; keep graceful.
                Text("No data for this period.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
            else
            {
                Chart
                {
                    // Actual (serie única)
                    ForEach(report.points.indices, id: \.self)
                    { idx in
                        let p = report.points[idx]
                        LineMark(
                            x: .value("Date", p.periodDate),
                            y: .value("Minutes", p.actualCumulativeMinutes)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .foregroundStyle(by: .value("Series", "Actual"))
                    }

                    // Plan (serie única)
                    if report.isPlanAvailable
                    {
                        ForEach(report.points.indices, id: \.self)
                        { idx in
                            let p = report.points[idx]
                            if let plan = p.planCumulativeMinutes
                            {
                                LineMark(
                                    x: .value("Date", p.periodDate),
                                    y: .value("Minutes", plan)
                                )
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                                .foregroundStyle(by: .value("Series", "Plan"))
                            }
                        }
                    }

                    // End-of-period marker (Today when pageOffset == 0)
                    if let lastDate = report.points.last?.periodDate
                    {
                        RuleMark(x: .value("End", lastDate))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                            .foregroundStyle(.tertiary)
                            .annotation(position: .top, alignment: .trailing)
                            {
                                if pageOffset == 0
                                {
                                    Text("Today")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }
                .chartForegroundStyleScale(
                    domain: ["Actual", "Plan"],
                    range: [ Color.orange, Color.accentColor ]
                )
                .chartYAxis
                {
                    AxisMarks(position: .leading)
                }
                .chartXAxis
                {
                    switch selectedRange
                    {
                    case .days7:
                        AxisMarks(values: .stride(by: .day))
                        { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel
                            {
                                if let d = value.as(Date.self) { Text(shortWeekday(d)) }
                            }
                        }

                    case .days30:
                        AxisMarks(values: .stride(by: .day, count: 5))
                        { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel
                            {
                                if let d = value.as(Date.self) { Text(dayNumber(d)) }
                            }
                        }

                    case .months12:
                        AxisMarks(values: .stride(by: .month))
                        { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel
                            {
                                if let d = value.as(Date.self) { Text(shortMonth(d)) }
                            }
                        }
                    }
                }
                .frame(height: 190)
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    var insightSection: some View
    {
        if report.isPlanAvailable, let insight = report.insight
        {
            Text(insight)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
        }
        else
        {
            VStack(alignment: .leading, spacing: 4)
            {
                Text("Plan not available")
                    .font(.subheadline.weight(.semibold))
                Text("Set a goal to see your plan and compare your pace.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
    }
}

// MARK: - Small KPI view (matches your card typography)

private struct KPIStat: View
{
    let title: String
    let value: String
    let subtitle: String
    var emphasized: Bool = false
    var emphasizedIsPositive: Bool? = nil

    var body: some View
    {
        VStack(alignment: .leading, spacing: 4)
        {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(emphasized ? .headline.bold() : .headline)
                .foregroundStyle(valueColor)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    private var valueColor: Color
    {
        guard emphasized, let isPositive = emphasizedIsPositive else { return .primary }
        return isPositive ? .green : .red
    }
}

// MARK: - Formatting helpers

private extension ProgressVsPlanView
{
    var calendar: Calendar
    {
        var c = Calendar.current
        c.timeZone = .current
        return c
    }

    var selectedRangeLabel: String
    {
        switch selectedRange
        {
        case .days7: return "last 7 days"
        case .days30: return "last 30 days"
        case .months12: return "last 12 months"
        }
    }

    var selectedRangeShortLabel: String
    {
        switch selectedRange
        {
        case .days7: return "7 days"
        case .days30: return "30 days"
        case .months12: return "12 months"
        }
    }

    func durationString(_ minutes: Int) -> String
    {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return "\(m)m"
    }

    func deltaString(deltaMinutes: Int?, status: ProgressVsPlan.Status?) -> String
    {
        guard let deltaMinutes, let status else { return "—" }
        let absText = durationString(abs(deltaMinutes))
        return status == .ahead ? "+\(absText)" : "−\(absText)"
    }

    func formatDay(_ date: Date) -> String
    {
        let df = DateFormatter()
        df.calendar = calendar
        df.timeZone = .current
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return df.string(from: date)
    }

    func formatMonthYear(_ date: Date) -> String
    {
        let df = DateFormatter()
        df.calendar = calendar
        df.timeZone = .current
        df.setLocalizedDateFormatFromTemplate("MMM yyyy")
        return df.string(from: date)
    }

    func shortWeekday(_ date: Date) -> String
    {
        let df = DateFormatter()
        df.calendar = calendar
        df.timeZone = .current
        df.setLocalizedDateFormatFromTemplate("EEE")
        return df.string(from: date)
    }

    func dayNumber(_ date: Date) -> String
    {
        let df = DateFormatter()
        df.calendar = calendar
        df.timeZone = .current
        df.setLocalizedDateFormatFromTemplate("d")
        return df.string(from: date)
    }

    func shortMonth(_ date: Date) -> String
    {
        let df = DateFormatter()
        df.calendar = calendar
        df.timeZone = .current
        df.setLocalizedDateFormatFromTemplate("MMM")
        return df.string(from: date)
    }
}

// MARK: - Preview (self-contained)

#Preview("Progress vs Plan (Dark)")
{
    NavigationStack
    {
        ProgressVsPlanView(topic: SampleData.shared.topic)
            .modelContainer(SampleData.shared.modelContainer)
            .preferredColorScheme(.dark)
    }
}
