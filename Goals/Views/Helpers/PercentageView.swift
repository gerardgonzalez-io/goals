//
//  PercentageView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 06-12-24.
//

import SwiftUI

struct PercentageView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                .frame(width: 90, height: 90)
            Circle()
                .trim(from: 0.0, to: CGFloat(0.75))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 90, height: 90)
            Text("\(Int(0.75 * 100))%")
                .font(.headline)
        }
    }
}

#Preview {
    PercentageView()
}
