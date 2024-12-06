//
//  GoalRow.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct GoalRow: View {
    let topic: Topic

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(topic.name)
                    .font(.headline)
                Spacer()
                Text("Daily goal")
                Text(String("0/\(topic.goal.dailyTimeGoal)"))
            }
            Spacer()
            PercentageView()
        }
        .padding()
 
    }
}

#Preview {
    let topics = TopicManager().topics
    GoalRow(topic: topics[0])
        .background(.yellow)
}
