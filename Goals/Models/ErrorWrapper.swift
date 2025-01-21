//
//  ErrorWrapper.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-01-25.
//

import Foundation

struct ErrorWrapper: Identifiable {
    let id: UUID
    let error: Error
    let guidance: String

    init(id: UUID = UUID(), error: Error, guidance: String) {
        self.id = id
        self.error = error
        self.guidance = guidance
    }
}

