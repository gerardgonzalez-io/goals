//
//  PercentageView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct PercentageView: View {
    let topic: Topic

    var goal: Double {
        topic.goal.dailyMinutesGoal
    }

    var timeSpend: Double {
        topic.timeSpend.dailyMinutesSpend
    }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(timeSpend / goal, 1.0)
    }

    var trackRingColor: Color {
        switch topic.theme {
        case .bubblegum, .buttercup, .lavender, .customOrange, .periwinkle, .poppy, .seafoam, .sky, .tan, .customTeal, .customYellow, .goldenYellow: return .darkergray
        case .customIndigo, .customMagenta, .navy, .oxblood, .customPurple, .kingblue, .deepNavy : return .neutralgray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackRingColor, lineWidth: 10)
                .frame(width: 90, height: 90)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(.goldenYellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 90, height: 90)
            
            Text("\(Int(progress * 100))%")
                .font(.headline)
        }
    }
}

#Preview {
    let topics = TopicStore().topics
    PercentageView(topic: topics[1])
}
