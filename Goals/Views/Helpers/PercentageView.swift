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
        if topic.theme == .goldenyellow {
            return .darkergray
        }
        return .neutralgray
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackRingColor, lineWidth: 10)
                .frame(width: 90, height: 90)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(.goldenyellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 90, height: 90)
            
            Text("\(Int(progress * 100))%")
                .font(.headline)
        }
    }
}

#Preview {
    let topics = TopicManager().topics
    PercentageView(topic: topics[1])
}
