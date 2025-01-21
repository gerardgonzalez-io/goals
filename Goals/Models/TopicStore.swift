//
//  TopicStore.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-01-25.
//

import SwiftUI

@MainActor
@Observable
class TopicStore: ObservableObject {
    var topics: [Topic] = []
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("topics.data")
    }
    
    func load() async throws {
        let task = Task<[Topic], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let topics = try JSONDecoder().decode([Topic].self, from: data)
            return topics
        }
        let topics = try await task.value
        self.topics = topics
    }

    func save(topics: [Topic]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(topics)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}

