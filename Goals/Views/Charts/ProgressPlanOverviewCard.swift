import Charts
import SwiftData
import SwiftUI

struct ProgressPlanOverviewCard: View
{
    @Query private var sessions: [StudySession]
    @Query private var goals: [Goal]

    let topicID: UUID
    let topicName: String

    @Environment(\.calendar) private var calendar
    @State private var chartData: [ProgressPlanChartData.Series] = []

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

    private var summaryText: String
    {
        guard let plan = chartData.first(where: { $0.name == ProgressPlanChartData.planSeriesName })?.points.last?.hours,
              let progress = chartData.first(where: { $0.name == ProgressPlanChartData.progressSeriesName })?.points.last?.hours
        else
        {
            return "No progress data yet"
        }

        return "\(formattedHours(progress)) studied of \(formattedHours(plan)) planned"
    }

    var body: some View
    {
        HStack(alignment: .center, spacing: 12)
        {
            VStack(alignment: .leading, spacing: 8)
            {
                VStack(alignment: .leading, spacing: 2)
                {
                    Text("Progress vs Plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(topicName)
                        .font(.title2.bold())
                        .lineLimit(1)
                }

                ProgressPlanOverviewChart(data: chartData)
                    .frame(height: 110)

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .task(id: refreshID)
        {
            refreshChartData()
        }
    }

    private var refreshID: String
    {
        "\(sessions.count)-\(goals.count)-\(topicID)"
    }

    private func refreshChartData()
    {
        chartData = ProgressPlanChartData.series(
            for: topicID,
            sessions: sessions,
            goals: goals,
            timeRange: .currentWeek,
            calendar: calendar
        )
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

private struct ProgressPlanOverviewChart: View
{
    let data: [ProgressPlanChartData.Series]

    private var latestProgressPoint: ProgressPlanChartData.Point?
    {
        data.first { $0.name == ProgressPlanChartData.progressSeriesName }?.points.last
    }

    var body: some View
    {
        Chart
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
            }
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .symbolSize(80)

            if let latestProgressPoint
            {
                PointMark(
                    x: .value("Day", latestProgressPoint.day, unit: .day),
                    y: .value("Hours", latestProgressPoint.hours)
                )
                .foregroundStyle(Color.orange)
                .symbolSize(90)
            }
        }
        .chartForegroundStyleScale([
            ProgressPlanChartData.planSeriesName: Color.accentColor,
            ProgressPlanChartData.progressSeriesName: Color.orange
        ])
        .chartSymbolScale(range: [.square, .circle])
        .chartXAxis
        {
            AxisMarks(values: .stride(by: .day))
            { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(range: .plotDimension(startPadding: 8, endPadding: 18))
        .chartLegend(.hidden)
    }
}

#Preview
{
    ProgressPlanOverviewCard(
        topicID: SampleData.shared.topic.id,
        topicName: SampleData.shared.topic.name
    )
    .padding()
    .modelContainer(SampleData.shared.modelContainer)
}
