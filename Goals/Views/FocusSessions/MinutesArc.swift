//
//  MinutesArc.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 12-12-24.
//

import SwiftUI

struct MinutesArc: Shape {
    let minuteIndex: Int
    let totalMinutes: Int

    private var degreesPerMinute: Double {
        360.0 / Double(totalMinutes)
    }

    private var startAngle: Angle {
        Angle(degrees: degreesPerMinute * Double(minuteIndex))
    }

    private var endAngle: Angle {
        Angle(degrees: startAngle.degrees + degreesPerMinute)
    }

    func path(in rect: CGRect) -> Path {
        let diameter = min(rect.size.width, rect.size.height) - 24.0
        let radius = diameter / 2.0
        let center = CGPoint(x: rect.midX, y: rect.midY)

        return Path { path in
            path.addArc(center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
        }
    }
}
