//
//  TopicView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 08-08-25.
//

import SwiftUI

struct TopicView: View
{
    var topics: [String] = ["iOS", "C"]
    @State private var isPresentingNewTopicView = false
    
    var body: some View
    {
        VStack
        {
            NavigationStack
            {
                List(topics, id: \.self)
                { topic in
                    Text(topic)
                }
                .navigationTitle("Topics")
                .toolbar
                {
                    Button(action: {
                        isPresentingNewTopicView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview
{
    TopicView()
}
