# ProgressPlan Hang Risk Fix

Yes. The hang risk was fixed mainly in two places.

In `ProgressPlanChartView.swift`, chart data is now stored in state:

```swift
@State private var chartData: [ProgressPlanChartData.Series] = []
```

The view renders from `chartData` instead of recomputing the report every time `body` is evaluated.

The refresh happens here:

```swift
.task(id: refreshID)
{
    refreshChartData()
}
.onChange(of: timeRange)
{
    rawSelectedDate = nil
    rawSelectedRange = nil
    refreshChartData()
}
```

So the calculation runs only when the input changes: range, sessions count, goals count, or topic.

The second fix is in `ProgressPlanChartData.swift`.

Before, the risky pattern was effectively:

```text
for each day:
    scan every session
        scan every interval
```

That becomes expensive as data grows.

Now this method builds a dictionary once:

```swift
private static func indexedProgressSecondsByDay(...) -> [Date: TimeInterval]
```

Inside it, each completed interval is assigned to the correct day bucket:

```swift
totals[day, default: 0] += overlapEnd.timeIntervalSince(overlapStart)
```

Then the chart loop does cheap lookups:

```swift
cumulativeProgress += progressByDay[day, default: 0]
```

So the expensive work changed from:

```text
days * sessions * intervals
```

to roughly:

```text
sessions * intervals + days
```

That is the key performance improvement. SwiftUI and Charts can redraw the screen without repeatedly doing full-history aggregation inside `body`.
