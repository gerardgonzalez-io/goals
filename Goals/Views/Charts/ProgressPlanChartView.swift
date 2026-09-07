import Charts
import SwiftData
import SwiftUI

struct ProgressPlanChartView: View
{
    @Query private var sessions: [StudySession]
    @Query private var goals: [Goal]

    let topicID: UUID
    let topicName: String

    @Environment(\.calendar) private var calendar
    @State private var timeRange: ProgressPlanChartData.TimeRange = .currentWeek
    @State private var pageOffset: Int = 0
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -6, to: Date.now) ?? Date.now
    @State private var customEndDate: Date = Date.now
    @State private var chartData: [ProgressPlanChartData.Series] = []
    @State private var rawSelectedDate: Date?
    @State private var rawSelectedRange: ClosedRange<Date>?

    init(topicID: UUID, topicName: String)
    {
        self.topicID = topicID
        self.topicName = topicName

        let topicID = topicID
        _sessions = Query(
            filter: #Predicate<StudySession> { session in
                session.topicID == topicID && !session.isArchived
            },
            sort: [SortDescriptor(\.startDate, order: .reverse)]
        )
        _goals = Query(
            filter: #Predicate<Goal> { goal in
                goal.topicID == topicID && !goal.isArchived
            },
            sort: [SortDescriptor(\.createdAt)]
        )
    }

    private let colorPerSeries: [String: Color] = [
        ProgressPlanChartData.planSeriesName: .accentColor,
        ProgressPlanChartData.progressSeriesName: .orange
    ]

    var body: some View
    {
        List
        {
            VStack(alignment: .leading, spacing: 12)
            {
                Picker("Time Range", selection: $timeRange)
                {
                    ForEach(ProgressPlanChartData.TimeRange.allCases)
                    { range in
                        Text(range.rawValue)
                            .tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if timeRange == .custom
                {
                    customDateSelector
                        .padding(.bottom, 4)
                }
                else
                {
                    periodSelector
                        .padding(.bottom, 4)
                }

                VStack(alignment: .leading, spacing: 4)
                {
                    title
                    legend
                }
                .opacity(rawSelectedDate == nil && rawSelectedRange == nil ? 1 : 0)

                ProgressPlanChart(
                    data: chartData,
                    rawSelectedDate: $rawSelectedDate,
                    rawSelectedRange: $rawSelectedRange,
                    timeRange: timeRange,
                    colorPerSeries: colorPerSeries
                )
                .frame(height: 240)
                .padding(.top, 4)

                descriptionText
                    .font(progressPlanDescriptionFont)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationTitle("Progress vs Plan")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: refreshID)
        {
            refreshChartData()
        }
        .onChange(of: timeRange)
        {
            pageOffset = 0
            clearSelection()
            refreshChartData()
        }
        .onChange(of: pageOffset)
        {
            clearSelection()
            refreshChartData()
        }
        .onChange(of: customStartDate)
        {
            normalizeCustomRange(changedStartDate: true)
            clearSelection()
            refreshChartData()
        }
        .onChange(of: customEndDate)
        {
            normalizeCustomRange(changedStartDate: false)
            clearSelection()
            refreshChartData()
        }
    }

    private var refreshID: String
    {
        let customStart = calendar.startOfDay(for: customStartDate).timeIntervalSinceReferenceDate
        let customEnd = calendar.startOfDay(for: customEndDate).timeIntervalSinceReferenceDate
        return "\(timeRange.id)-\(pageOffset)-\(customStart)-\(customEnd)-\(sessions.count)-\(goals.count)-\(topicID)"
    }

    private var periodSelector: some View
    {
        HStack(spacing: 10)
        {
            Button
            {
                pageOffset -= 1
            }
            label:
            {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.plain)

            Text(periodTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            Button
            {
                guard pageOffset < 0 else { return }
                pageOffset += 1
            }
            label:
            {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.plain)
            .foregroundStyle(pageOffset < 0 ? .primary : .tertiary)
            .disabled(pageOffset == 0)
        }
    }

    private var customDateSelector: some View
    {
        VStack(alignment: .leading, spacing: 20)
        {
            Text("Custom range")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 12)
            {
                roundedDatePicker(
                    title: "Start date",
                    selection: $customStartDate,
                    range: Date.distantPast...customEndDate
                )

                roundedDatePicker(
                    title: "End date",
                    selection: $customEndDate,
                    range: customStartDate...Date.now
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var periodTitle: String
    {
        ProgressPlanChartData.periodTitle(
            for: timeRange,
            pageOffset: pageOffset,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            calendar: calendar
        )
    }

    private var title: some View
    {
        VStack(alignment: .leading, spacing: 2)
        {
            Text("Progress vs Plan")
                .font(progressPlanPreTitleFont)
                .foregroundStyle(.secondary)
            Text(topicName)
                .font(progressPlanTitleFont)
        }
    }

    private var legend: some View
    {
        HStack(spacing: 14)
        {
            HStack(spacing: 5)
            {
                progressPlanLegendSquare
                Text(ProgressPlanChartData.planSeriesName)
                    .font(progressPlanLabelFont)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 5)
            {
                progressPlanLegendCircle
                Text(ProgressPlanChartData.progressSeriesName)
                    .font(progressPlanLabelFont)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var descriptionText: Text
    {
        guard let plan = chartData.first(where: { $0.name == ProgressPlanChartData.planSeriesName })?.points.last?.hours,
              let progress = chartData.first(where: { $0.name == ProgressPlanChartData.progressSeriesName })?.points.last?.hours
        else
        {
            return Text("No chart data is available yet.")
        }

        return Text("For \(periodTitle), you studied \(formattedHours(progress)) against \(formattedHours(plan)) planned.")
    }

    private func refreshChartData()
    {
        chartData = ProgressPlanChartData.series(
            for: topicID,
            sessions: sessions,
            goals: goals,
            timeRange: timeRange,
            pageOffset: pageOffset,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            calendar: calendar
        )
    }

    private func roundedDatePicker(
        title: String,
        selection: Binding<Date>,
        range: ClosedRange<Date>
    ) -> some View
    {
        DatePicker(
            title,
            selection: selection,
            in: range,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .font(.caption)
        .labelsHidden()
        .frame(maxWidth: .infinity, alignment: .leading)
        //.padding(10)
        .overlay(alignment: .topLeading)
        {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .offset(x: 0, y: -16)
        }

    }

    private func clearSelection()
    {
        rawSelectedDate = nil
        rawSelectedRange = nil
    }

    private func normalizeCustomRange(changedStartDate: Bool)
    {
        if customEndDate > Date.now
        {
            customEndDate = Date.now
        }

        if customStartDate > customEndDate
        {
            if changedStartDate
            {
                customEndDate = customStartDate
            }
            else
            {
                customStartDate = customEndDate
            }
        }
    }


    private func formattedHours(_ hours: Double) -> String
    {
        if hours < 1
        {
            return "\(Int((hours * 60).rounded()))m"
        }

        return "\(hours.formatted(.number.precision(.fractionLength(0...1))))h"
    }
}

private struct ProgressPlanChart: View
{
    let data: [ProgressPlanChartData.Series]
    @Binding var rawSelectedDate: Date?
    @Binding var rawSelectedRange: ClosedRange<Date>?
    let timeRange: ProgressPlanChartData.TimeRange
    let colorPerSeries: [String: Color]

    @Environment(\.calendar) private var calendar
    @Environment(\.colorScheme) private var colorScheme

    private var selectedDate: Date?
    {
        if let rawSelectedDate
        {
            return data.first?.points.first
            { point in
                (point.day..<endOfDay(for: point.day)).contains(rawSelectedDate)
            }?.day
        }
        else if let selectedRange, selectedRange.lowerBound == selectedRange.upperBound
        {
            return selectedRange.lowerBound
        }

        return nil
    }

    private var selectedRange: ClosedRange<Date>?
    {
        guard let rawSelectedRange else { return nil }

        let lower = data.first?.points.first
        { point in
            (point.day..<endOfDay(for: point.day)).contains(rawSelectedRange.lowerBound)
        }?.day

        let upper = data.first?.points.first
        { point in
            (point.day..<endOfDay(for: point.day)).contains(rawSelectedRange.upperBound)
        }?.day

        guard let lower, let upper else { return nil }
        return min(lower, upper)...max(lower, upper)
    }

    var body: some View
    {
        Chart
        {
            lineMarks
            selectionMarks
        }
        .chartForegroundStyleScale([
            ProgressPlanChartData.planSeriesName: colorPerSeries[ProgressPlanChartData.planSeriesName] ?? .accentColor,
            ProgressPlanChartData.progressSeriesName: colorPerSeries[ProgressPlanChartData.progressSeriesName] ?? .orange
        ])
        .chartSymbolScale(range: [.square, .circle])
        .chartXAxis
        {
            AxisMarks(values: axisValues)
            { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: axisLabelFormat, centered: true)
            }
        }
        .chartYAxis
        {
            AxisMarks(position: .trailing)
            { value in
                AxisGridLine()
                AxisValueLabel
                {
                    if let hours = value.as(Double.self)
                    {
                        Text("\(hours.formatted(.number.precision(.fractionLength(0))))h")
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartXSelection(value: $rawSelectedDate)
        .chartXSelection(range: $rawSelectedRange)
    }

    @ChartContentBuilder
    private var lineMarks: some ChartContent
    {
        ForEach(data)
        { series in
            ForEach(series.points)
            { point in
                LineMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Hours", point.hours)
                )
            }
            .foregroundStyle(by: .value("Series", series.name))
            .symbol(by: .value("Series", series.name))
            .interpolationMethod(.catmullRom)
        }
    }

    @ChartContentBuilder
    private var selectionMarks: some ChartContent
    {
        if let selectedDate
        {
            RuleMark(x: .value("Selected", selectedDate, unit: .day))
                .foregroundStyle(Color.secondary.opacity(0.3))
                .offset(yStart: -10)
                .zIndex(-1)
                .annotation(
                    position: .top,
                    spacing: 0,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                )
                {
                    valueSelectionPopover
                }
        }
        else if let selectedRange
        {
            Plot
            {
                RuleMark(x: .value("Selected upper bound", selectedRange.upperBound, unit: .day))
                RuleMark(x: .value("Selected lower bound", selectedRange.lowerBound, unit: .day))
            }
            .foregroundStyle(Color.secondary.opacity(0.3))
            .offset(yStart: -10)
            .zIndex(-1)
            .annotation(
                position: .top,
                spacing: 0,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            )
            { context in
                let markWidth = context.targetSize.width

                rangeSelectionPopover
                    .frame(minWidth: markWidth > 0 ? markWidth : 0, alignment: .leading)
                    .fixedSize()
                    .padding(6)
                    .background
                    {
                        RoundedRectangle(cornerRadius: 4)
                            .foregroundStyle(Color.secondary.opacity(0.12))
                    }
            }
        }
    }

    @ViewBuilder
    private var valueSelectionPopover: some View
    {
        if let selectedDate,
           let values = valuesBySeries(on: selectedDate)
        {
            VStack(alignment: .leading, spacing: 4)
            {
                Text("Total by \(selectedDate, format: .dateTime.weekday(.wide).day().month(.abbreviated))")
                    .font(progressPlanPreTitleFont)
                    .foregroundStyle(.secondary)
                    .fixedSize()

                HStack(spacing: 20)
                {
                    ForEach(values)
                    { value in
                        chartValueColumn(value)
                    }
                }
            }
            .padding(6)
            .background
            {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(Color.secondary.opacity(0.12))
            }
        }
    }

    @ViewBuilder
    private var rangeSelectionPopover: some View
    {
        if let selectedRange,
           let values = valuesBySeries(in: selectedRange)
        {
            VStack(alignment: .leading, spacing: 4)
            {
                Text("Added from \(selectedRange.lowerBound, format: .dateTime.day().month(.abbreviated)) to \(selectedRange.upperBound, format: .dateTime.day().month(.abbreviated))")
                    .font(progressPlanPreTitleFont)
                    .foregroundStyle(.secondary)
                    .fixedSize()

                HStack(spacing: 20)
                {
                    ForEach(values)
                    { value in
                        chartValueColumn(value)
                    }
                }
            }
        }
    }

    private var axisValues: AxisMarkValues
    {
        switch timeRange
        {
        case .currentWeek:
            return .stride(by: .day)
        case .currentMonth:
            return .stride(by: .day, count: 7)
        case .custom:
            if dataPointCount > 45
            {
                return .stride(by: .day, count: 14)
            }
            else if dataPointCount > 14
            {
                return .stride(by: .day, count: 7)
            }

            return .stride(by: .day)
        }
    }

    private var axisLabelFormat: Date.FormatStyle
    {
        switch timeRange
        {
        case .currentWeek:
            return .dateTime.weekday(.abbreviated)
        case .currentMonth:
            return .dateTime.day()
        case .custom:
            return dataPointCount > 14 ? .dateTime.month(.abbreviated).day() : .dateTime.weekday(.abbreviated)
        }
    }

    private var dataPointCount: Int
    {
        data.first?.points.count ?? 0
    }

    private func chartValueColumn(_ value: SeriesValue) -> some View
    {
        VStack(alignment: .leading, spacing: 1)
        {
            HStack(alignment: .lastTextBaseline, spacing: 4)
            {
                Text(formattedHours(value.hours))
                    .font(progressPlanTitleFont)
                    .foregroundColor(colorPerSeries[value.series])
                    .blendMode(colorScheme == .light ? .plusDarker : .normal)

                Text("hours")
                    .font(progressPlanPreTitleFont)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6)
            {
                if value.series == ProgressPlanChartData.planSeriesName
                {
                    progressPlanLegendSquare
                }
                else
                {
                    progressPlanLegendCircle
                }

                Text(value.series)
                    .font(progressPlanLabelFont)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func valuesBySeries(on selectedDate: Date) -> [SeriesValue]?
    {
        guard let index = index(of: selectedDate) else { return nil }

        return data.map
        { series in
            SeriesValue(series: series.name, hours: series.points[index].hours)
        }
    }

    private func valuesBySeries(in selectedRange: ClosedRange<Date>) -> [SeriesValue]?
    {
        guard let lowerIndex = index(of: selectedRange.lowerBound),
              let upperIndex = index(of: selectedRange.upperBound)
        else
        {
            return nil
        }

        return data.map
        { series in
            let lowerPrevious = lowerIndex > 0 ? series.points[lowerIndex - 1].hours : 0
            let upperValue = series.points[upperIndex].hours
            return SeriesValue(series: series.name, hours: max(0, upperValue - lowerPrevious))
        }
    }

    private func index(of selectedDate: Date) -> Int?
    {
        data.first?.points.firstIndex
        { point in
            calendar.isDate(point.day, inSameDayAs: selectedDate)
        }
    }

    private func endOfDay(for date: Date) -> Date
    {
        calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    private func formattedHours(_ hours: Double) -> String
    {
        if hours < 1
        {
            return "\(Int((hours * 60).rounded()))m"
        }

        return hours.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private struct SeriesValue: Identifiable
{
    let series: String
    let hours: Double

    var id: String { series }
}

@ViewBuilder
private var progressPlanLegendSquare: some View
{
    RoundedRectangle(cornerRadius: 1)
        .stroke(lineWidth: 2)
        .frame(width: 5.3, height: 5.3)
        .foregroundColor(.accentColor)
        .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
}

@ViewBuilder
private var progressPlanLegendCircle: some View
{
    Circle()
        .stroke(lineWidth: 2)
        .frame(width: 5.7, height: 5.7)
        .foregroundColor(.orange)
        .padding(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 0))
}

#if os(macOS)
private let progressPlanTitleFont: Font = .title.bold()
#else
private let progressPlanTitleFont: Font = .title2.bold()
#endif

#if os(macOS)
private let progressPlanPreTitleFont: Font = .headline
#else
private let progressPlanPreTitleFont: Font = .callout
#endif

#if os(macOS)
private let progressPlanLabelFont: Font = .subheadline
#else
private let progressPlanLabelFont: Font = .caption2
#endif

#if os(macOS)
private let progressPlanDescriptionFont: Font = .body
#else
private let progressPlanDescriptionFont: Font = .subheadline
#endif

#Preview
{
    NavigationStack
    {
        ProgressPlanChartView(
            topicID: SampleData.shared.topic.id,
            topicName: SampleData.shared.topic.name
        )
        .modelContainer(SampleData.shared.modelContainer)
    }
}
