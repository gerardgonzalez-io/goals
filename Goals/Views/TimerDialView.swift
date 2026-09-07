//
//  TimerDialView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-10-25.
//

import SwiftUI

struct TimerDialView: View
{
    var time: TimeInterval

    var body: some View
    {
        GeometryReader
        { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let seconds = time.truncatingRemainder(dividingBy: 60)
            let minutesInSubdial = (time / 60).truncatingRemainder(dividingBy: 30)

            Canvas
            { context, _ in
                let center = CGPoint(x: radius, y: radius)

                
                for i in 0..<60
                {
                    let angle = Angle.degrees(Double(i) * 6)
                    var path = Path()
                    let long = i % 5 == 0
                    let len: CGFloat = long ? 18 : 8
                    let width: CGFloat = long ? 3 : 1

                    let start = CGPoint(
                        x: center.x + (radius - 30) * cos(CGFloat(angle.radians)),
                        y: center.y + (radius - 30) * sin(CGFloat(angle.radians))
                    )
                    let end = CGPoint(
                        x: center.x + (radius - 30 - len) * cos(CGFloat(angle.radians)),
                        y: center.y + (radius - 30 - len) * sin(CGFloat(angle.radians))
                    )
                    path.move(to: start)
                    path.addLine(to: end)
                    context.stroke(path, with: .color(.gray.opacity(0.85)), lineWidth: width)
                }

                
                for n in stride(from: 5, through: 60, by: 5)
                {
                    
                    let a = Angle.degrees(Double(n) * 6 - 90)
                    let r = radius - 65
                    let pt = CGPoint(x: center.x + r * cos(CGFloat(a.radians)),
                                     y: center.y + r * sin(CGFloat(a.radians)))
                    let text = Text("\(n)").font(.system(size: 24, weight: .semibold))
                    context.draw(text, at: pt, anchor: .center)
                }

                
                let subR: CGFloat = radius * 0.28
                let subC = CGPoint(x: center.x, y: center.y - radius * 0.30)
                let subCircle = Path(ellipseIn: CGRect(x: subC.x - subR, y: subC.y - subR, width: subR * 2, height: subR * 2))
                context.stroke(subCircle, with: .color(.gray.opacity(0.75)), lineWidth: 0)

                
                for i in 0..<30
                {
                    let angle = Angle.degrees(Double(i) * 12 - 90)
                    var path = Path()
                    let long = i % 5 == 0
                    let len: CGFloat = long ? 10 : 6
                    let width: CGFloat = long ? 2 : 1
                    let start = CGPoint(
                        x: subC.x + (subR - 8) * cos(CGFloat(angle.radians)),
                        y: subC.y + (subR - 8) * sin(CGFloat(angle.radians))
                    )
                    let end = CGPoint(
                        x: subC.x + (subR - 8 - len) * cos(CGFloat(angle.radians)),
                        y: subC.y + (subR - 8 - len) * sin(CGFloat(angle.radians))
                    )
                    path.move(to: start)
                    path.addLine(to: end)
                    context.stroke(path, with: .color(.gray.opacity(0.85)), lineWidth: width)
                }

                
                for n in stride(from: 5, through: 30, by: 5)
                {
                    let a = Angle.degrees(Double(n) * 12 - 90)
                    let r = subR - 24
                    let pt = CGPoint(x: subC.x + r * cos(CGFloat(a.radians)),
                                     y: subC.y + r * sin(CGFloat(a.radians)))
                    let text = Text("\(n)").font(.system(size: 14, weight: .semibold))
                    context.draw(text, at: pt, anchor: .center)
                }

                
                let secAngle = Angle.degrees(seconds / 60 * 360 - 90)
                var sec = Path()
                let end = CGPoint(x: center.x + (radius - 40) * cos(CGFloat(secAngle.radians)),
                                  y: center.y + (radius - 40) * sin(CGFloat(secAngle.radians)))
                let tail = CGPoint(x: center.x + 25 * cos(CGFloat((secAngle + .degrees(180)).radians)),
                                   y: center.y + 25 * sin(CGFloat((secAngle + .degrees(180)).radians)))
                sec.move(to: tail)
                sec.addLine(to: end)
                context.stroke(sec, with: .color(.orange), lineWidth: 3)

                
                let minAngle = Angle.degrees(minutesInSubdial / 30 * 360 - 90)
                var minu = Path()
                let minEnd = CGPoint(x: subC.x + (subR - 14) * cos(CGFloat(minAngle.radians)),
                                     y: subC.y + (subR - 14) * sin(CGFloat(minAngle.radians)))
                minu.move(to: subC)
                minu.addLine(to: minEnd)
                context.stroke(minu, with: .color(.orange), lineWidth: 3)

               
                context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(.orange))
                context.fill(Path(ellipseIn: CGRect(x: subC.x - 3, y: subC.y - 3, width: 6, height: 6)), with: .color(.orange))
            }
        }
    }
}

#Preview
{
    TimerDialView(time: 0)
}
