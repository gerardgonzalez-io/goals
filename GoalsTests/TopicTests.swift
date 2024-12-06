//
//  TopicTests.swift
//  GoalsTests
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import Testing
import Foundation

@testable import Goals // Import your app module

struct TopicTests {

    @Test func testTopicDecoding() async throws {
        // Sample JSON for testing
        let sampleJSON = """
        [
            {
                "id": "b12a05be-5f67-4bda-9b15-ef5d3b475cee",
                "name": "Mathematics",
                "description": "Study algebra and calculus.",
                "goal": {
                    "dailyTimeGoal": 120
                },
                "reminders": [
                    {
                        "id": "3f65bfa4-8c5e-4d8e-9f88-76c56e8f3b42",
                        "time": "2023-10-29T05:00:00Z",
                        "isEnabled": true
                    }
                ],
                "history": [
                    {
                        "id": "8b65f5c7-d7a6-4e19-87aa-1c8c15e5479e",
                        "date": "2023-10-28T05:00:00Z",
                        "duration": 60
                    },
                    {
                        "id": "f5c31776-3b6d-4c7a-94c6-d3bb7e5268ba",
                        "date": "2023-10-27T05:00:00Z",
                        "duration": 90
                    }
                ]
            },
            {
                "id": "a3d7e05d-6c58-4f20-b7c6-1e9d45f8a96e",
                "name": "Physics",
                "description": "Learn classical mechanics.",
                "goal": {
                    "dailyTimeGoal": 90
                },
                "reminders": [
                    {
                        "id": "e1a7c9b9-5d4b-4f9a-bf3e-8e2a6b4d5f60",
                        "time": "2023-10-29T06:00:00Z",
                        "isEnabled": true
                    }
                ],
                "history": [
                    {
                        "id": "c8d9a2f3-8f0a-4d2b-b5b7-e9f3d2c7a1b6",
                        "date": "2023-10-28T06:00:00Z",
                        "duration": 45
                    }
                ]
            },
            {
                "id": "d2f8a3b7-6c9d-4f0e-9b5c-3a1e2d7f6b8c",
                "name": "Programming",
                "description": "Practice Swift programming.",
                "goal": {
                    "dailyTimeGoal": 150
                },
                "reminders": [
                    {
                        "id": "f1a2b3c4-d5e6-7f8a-9b0c-d1e2f3a4b5c6",
                        "time": "2023-10-29T07:00:00Z",
                        "isEnabled": true
                    },
                    {
                        "id": "6e5d4c3b-2a1f-0e9d-8c7b-6a5d4e3f2b1c",
                        "time": "2023-10-29T19:00:00Z",
                        "isEnabled": false
                    }
                ],
                "history": [
                    {
                        "id": "7c6b5a4d-3e2f-1d0c-9b8a-7c6d5e4f3b2a",
                        "date": "2023-10-28T07:00:00Z",
                        "duration": 120
                    },
                    {
                        "id": "0f9e8d7c-6b5a-4c3d-2e1f-0a9b8c7d6e5f",
                        "date": "2023-10-27T07:00:00Z",
                        "duration": 150
                    },
                    {
                        "id": "5e4d3c2b-1a0f-9e8d-7c6b-5a4d3e2f1b0c",
                        "date": "2023-10-26T07:00:00Z",
                        "duration": 90
                    }
                ]
            }
        ]
        """.data(using: .utf8)!

        // JSONDecoder setup
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Decode the JSON
        let topics = try decoder.decode([Topic].self, from: sampleJSON)

        // Assertions using `expect`
        #expect(topics.count == 3, "Expected 1 topic in the JSON.")
        #expect(topics[0].name == "Mathematics", "Topics name should match.")
        #expect(topics[0].goal.dailyTimeGoal == 120, "Daily time goal should match.")
        #expect(topics[0].reminders.count == 1, "Expected 1 reminder.")
        #expect(topics[0].reminders[0].isEnabled, "Reminder should be enabled.")
        #expect(topics[0].history[0].duration == 60, "History duration should match.")
    }
}

