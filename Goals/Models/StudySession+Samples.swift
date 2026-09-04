//
//  StudySession+Samples.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 25-12-25.
//

import Foundation

extension StudySession
{
    static let sample = sampleData[0]
    static let longSample = sampleData[1]
    static let shortSample = sampleData[2]

    static let sampleData = [
        StudySession(
            topicID: Topic.sampleData[0].id,
            startDate: .now.addingTimeInterval(-7_200),
            endDate: .now.addingTimeInterval(-3_600),
            sessionIntervals: [
                SessionInterval(
                    startDate: .now.addingTimeInterval(-7_200),
                    endDate: .now.addingTimeInterval(-3_600)
                )
            ]
        ),
        StudySession(
            topicID: Topic.sampleData[1].id,
            startDate: .now.addingTimeInterval(-172_800),
            endDate: .now.addingTimeInterval(-151_200),
            sessionIntervals: [
                SessionInterval(
                    startDate: .now.addingTimeInterval(-172_800),
                    endDate: .now.addingTimeInterval(-165_600)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-160_200),
                    endDate: .now.addingTimeInterval(-153_000)
                )
            ]
        ),
        StudySession(
            topicID: Topic.sampleData[2].id,
            startDate: .now.addingTimeInterval(-86_400),
            endDate: .now.addingTimeInterval(-79_200),
            sessionIntervals: [
                SessionInterval(
                    startDate: .now.addingTimeInterval(-86_400),
                    endDate: .now.addingTimeInterval(-85_200)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-84_600),
                    endDate: .now.addingTimeInterval(-83_700)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-83_100),
                    endDate: .now.addingTimeInterval(-79_500)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-79_440),
                    endDate: .now.addingTimeInterval(-79_260)
                )
            ]
        ),
        StudySession(
            topicID: Topic.sampleData[0].id,
            startDate: .now.addingTimeInterval(-18_000),
            endDate: .now.addingTimeInterval(-9_000),
            sessionIntervals: [
                SessionInterval(
                    startDate: .now.addingTimeInterval(-18_000),
                    endDate: .now.addingTimeInterval(-9_000)
                )
            ]
        ),
        StudySession(
            topicID: Topic.sampleData[1].id,
            startDate: .now.addingTimeInterval(-10_800),
            endDate: .now.addingTimeInterval(0),
            sessionIntervals: [
                SessionInterval(
                    startDate: .now.addingTimeInterval(-10_800),
                    endDate: .now.addingTimeInterval(-9_300)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-9_180),
                    endDate: .now.addingTimeInterval(-7_980)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-7_800),
                    endDate: .now.addingTimeInterval(-6_900)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-6_600),
                    endDate: .now.addingTimeInterval(-3_000)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-2_880),
                    endDate: .now.addingTimeInterval(-2_700)
                ),
                SessionInterval(
                    startDate: .now.addingTimeInterval(-2_520),
                    endDate: .now.addingTimeInterval(-2_100)
                )
            ]
        )
    ]
}
