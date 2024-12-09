//
//  GoalRow.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct GoalRow: View {
    let topic: Topic
    
    var dailyGoal: Double {
        topic.goal.dailyTimeGoal
    }

    var dailyTimeSpend: Double {
        topic.timeSpend.dailyTimeSpend
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(topic.name)
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                Spacer()
                Text("Daily goal")
                    .font(.system(.body, design: .default))
                Text(String("\(Int(dailyTimeSpend))/\(Int(dailyGoal))MIN"))
                    .font(.system(.body, design: .default))
            }

            Spacer()

            PercentageView(topic: topic)
        }
        .padding()
        .foregroundStyle(topic.theme.accentColor)
 
    }
}

#Preview {
    let topics = TopicManager().topics
    GoalRow(topic: topics[0])
        .background(.deepnavy)
}
