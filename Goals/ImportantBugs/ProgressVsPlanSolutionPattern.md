# ProgressVsPlanView Solution Pattern

Use a **cached view-model aggregation pattern**.

Move the expensive report calculation out of SwiftUI `body` and into a dedicated `@State` / `@Observable` view model that recomputes only when its inputs change.

The shape would be:

1. `ProgressVsPlanView` keeps a stored report state:

```swift
@State private var report: ProgressVsPlan.Report?
```

2. The view renders from that stored value, not from a computed property.

3. Recompute the report only on meaningful changes:

```swift
.task(id: selectedRange)
.onChange(of: pageOffset)
.onChange(of: sessions)
.onChange(of: goals)
```

4. Do the aggregation outside the render pass, ideally off the main actor:

```swift
let newReport = await Task.detached {
    ProgressVsPlan.compute(...)
}.value
```

5. Assign the finished result back on the main actor:

```swift
report = newReport
```

6. Optimize the calculator itself so it does not scan all sessions for every day. Build a dictionary once:

```swift
[Date: totalSecondsForThatDay]
```

Then chart generation becomes:

```text
periods * O(1) lookup
```

instead of:

```text
periods * sessions * intervals
```

So the preferred pattern is:

```text
SwiftUI View
  -> owns selection state
  -> asks ViewModel/loader to compute report
  -> displays cached report

Report Builder
  -> pre-indexes sessions by day/month
  -> computes chart points from indexed totals
```

That solves the hang because SwiftUI can reevaluate the view freely without repeatedly redoing the heavy full-history aggregation on the main thread.
