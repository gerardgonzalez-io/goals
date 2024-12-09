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
                    .font(.headline)
                Spacer()
                Text("Daily goal")
                Text(String("\(Int(dailyTimeSpend))/\(Int(dailyGoal))"))
            }

            Spacer()

            PercentageView(topic: topic)
        }
        .padding()
 
    }
}

#Preview {
    let topics = TopicManager().topics
    GoalRow(topic: topics[0])
        .background(.yellow)
}
