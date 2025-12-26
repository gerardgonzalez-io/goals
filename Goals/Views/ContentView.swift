//
//  ContentView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-10-25.
//

import SwiftUI
import SwiftData

struct ContentView: View
{
    @Environment(\.modelContext) private var modelContext
    @State private var timer = Timer()

    private enum Route: Hashable
    {
        case topics
        case studyHistory
    }

    var body: some View
    {
        NavigationStack
        {
            ScrollView
            {
                VStack(alignment: .leading, spacing: 24)
                {
                    Text("Summary")
                        .font(.largeTitle.bold())
                        .padding(.top, 8)

                    Text("Your only job: be a bit better than yesterday.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 16)
                    {
                        NavigationLink(value: Route.topics)
                        {
                            SummaryCard(
                                title: "Topics",
                                subtitle: "Manage what you study and start focus sessions.",
                                systemImage: "list.bullet.rectangle",
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: Route.studyHistory)
                        {
                            SummaryCard(
                                title: "Study history",
                                subtitle: "See what you studied each day and your total time.",
                                systemImage: "calendar.badge.clock",
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationDestination(for: Route.self)
            { route in
                switch route
                {
                case .topics:
                    TopicListView(timer: timer)
                case .studyHistory:
                    StudyHistoryView()
                }
            }
        }
        .onAppear
        {
            UserDefaults.standard.set(UUID().uuidString, forKey: "currentLaunchID")
        }
    }
}

#Preview
{
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
        .preferredColorScheme(.dark)
}
