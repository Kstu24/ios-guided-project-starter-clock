//
//  ClockView.swift
//  Clock
//
//  Created by Ben Gohlke on 6/24/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

struct Hand {
    let width: CGFloat // in points
    // length is proportionate to size of view, so the higher the number,
    // the shorter the hand length
    let length: CGFloat
    let color: UIColor
    // 1-12 for hour, 0-60 for minutes/seconds
    var value: Double = 0
}

@IBDesignable
class ClockView: UIView {
    
    // MARK: - Properties
    
    // Used to sync timing of animation events to the refresh rate of the display
    private var animationTimer: CADisplayLink?
    
    /// Tracks the current timezone of the clock.
    /// Automatically configures the timer to run in sync with the screen
    /// and update the face each second.
    var timezone: TimeZone? {
        didSet {
            let aTimer = CADisplayLink(target: self, selector: #selector(timerFired(_:)))
            aTimer.preferredFramesPerSecond = 60
            aTimer.add(to: .current, forMode: .common)
            animationTimer = aTimer
        }
    }
    
    private var seconds = Hand(width: 1.0, length: 2.4, color: .red, value: 0)
    private var minutes = Hand(width: 3.0, length: 3.2, color: .white, value: 0)
    private var hours = Hand(width: 4.0, length: 4.6, color: .white, value: 0)
    
    private var secondHandEndPoint: CGPoint {
        let secondsAsRadians = Float(Double(seconds.value) / 60.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / seconds.length)
        return handEndPoint(with: secondsAsRadians, and: handLength)
    }
    
    private var minuteHandEndPoint: CGPoint {
        let minutesAsRadians = Float(Double(minutes.value) / 60.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / minutes.length)
        return handEndPoint(with: minutesAsRadians, and: handLength)
    }
    
    private var hourHandEndPoint: CGPoint {
        let totalHours = Double(hours.value) + Double(minutes.value) / 60.0
        let hoursAsRadians = Float(totalHours / 12.0 * 2.0 * Double.pi - Double.pi / 2)
        let handLength = CGFloat(frame.size.width / hours.length)
        return handEndPoint(with: hoursAsRadians, and: handLength)
    }
    
    private let clockBgColor = UIColor.black
    
    private let borderColor = UIColor.white
    private let borderWidth: CGFloat = 2.0
    
    private let digitColor = UIColor.white
    private let digitOffset: CGFloat = 15.0
    private var digitFont: UIFont {
        return UIFont.systemFont(ofSize: 8.0 + frame.size.width / 50.0)
    }
    
    // MARK: - View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        /// Note: elements are drawn on the the screen from back to front
        /// in the order they appear below.
        
        if let context = UIGraphicsGetCurrentContext() {
            
            // clock face
            context.addEllipse(in: rect)
            context.setFillColor(clockBgColor.cgColor)
            context.fillPath()
            
            
            
            // clock's border: USE THIS CODE FOR EVERY PROJECT when needing a clock!!!
            context.addEllipse(in: CGRect(x: rect.origin.x + borderWidth / 2.0,
                                          y: rect.origin.y + borderWidth / 2.9,
                                          width: rect.size.width - borderWidth,
                                          height: rect.size.height - borderWidth))
            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(borderWidth)
            context.strokePath()
            
            
            
//             numerals
            let clockCenter = CGPoint(x: rect.size.width / 2.0,
                                      y: rect.size.height / 2.0)
            let numeralDistanceFromCenter = rect.size.width / 2.0 - digitFont.lineHeight / 4.0 - digitOffset
            let offset = 3 // offsets numerals, putting "12" at the top of the clock

            for i in 1...12 {
                let hourString: NSString
                if i < 10 {
                    hourString = " \(i)" as NSString
                } else {
                    hourString = "\(i)" as NSString
                }
                let labelX = clockCenter.x + (numeralDistanceFromCenter - digitFont.lineHeight / 2.0)
                    * CGFloat(cos((Double.pi / 180) * Double(i + offset) * 30 + Double.pi))
                let labelY = clockCenter.y - 1 * (numeralDistanceFromCenter - digitFont.lineHeight / 2.0)
                    * CGFloat(sin((Double.pi / 180) * Double(i + offset) * 30))
                hourString.draw(in: CGRect(x: labelX - digitFont.lineHeight / 2.0,
                                           y: labelY - digitFont.lineHeight / 2.0,
                                           width: digitFont.lineHeight,
                                           height: digitFont.lineHeight),
                                withAttributes: [NSAttributedString.Key.foregroundColor: digitColor,
                                                 NSAttributedString.Key.font: digitFont])
            }
            
            // minute hand
            context.setStrokeColor(minutes.color.cgColor)
            context.beginPath() // begins drawing the minute hand
            context.move(to: clockCenter) // begins drawing the line at the center of the clock
            context.setLineWidth(minutes.width) // makes the line thicker
            context.addLine(to: minuteHandEndPoint) // draws line to the noon position
            context.strokePath() // completes drawing
            
            
            // hour hand
            context.setStrokeColor(hours.color.cgColor)
            context.beginPath()
            context.move(to: clockCenter)
            context.setLineWidth(hours.width)
            context.addLine(to: hourHandEndPoint)
            context.strokePath()
            
            // hour/minute's center
            let largeDotRadius: CGFloat = 6.0
            let centerCirlceRect = CGRect(
                        x: clockCenter.x - largeDotRadius,
                        y: clockCenter.y - largeDotRadius,
                        width: 2 * largeDotRadius,
                        height: 2 * largeDotRadius)
            context.addEllipse(in: centerCirlceRect)
            context.setFillColor(hours.color.cgColor)
            context.fillPath()
            
            
            // second hand
            context.setStrokeColor(seconds.color.cgColor)
            context.beginPath()
            context.move(to: clockCenter)
            context.setLineWidth(seconds.width)
            context.addLine(to: secondHandEndPoint)
            context.strokePath()
            
            
            
            // second's center
            let smallDotRadius: CGFloat = 3.0
            let secondCirlceRect = CGRect(
                        x: clockCenter.x - smallDotRadius,
                        y: clockCenter.y - smallDotRadius,
                        width: 2 * smallDotRadius,
                        height: 2 * smallDotRadius)
            context.addEllipse(in: secondCirlceRect)
            context.setFillColor(hours.color.cgColor)
            context.fillPath()
            
        }
    }
    
    @objc func timerFired(_ sender: CADisplayLink) {
        // Get current time
        let currentTime = Date()
        
        // Get calendar and set timezone
        var calendar = Calendar(identifier: .gregorian) // american calendar
        calendar.timeZone = timezone!
        
        // Extract hour, minute, second components from current time
        let timeComponents = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: currentTime)
        
        let hourComponent = Double(timeComponents.hour ?? 0)//making it a double changes it to a smooth tick to make it reload the clock more than once per second
        let minuteComponent = Double(timeComponents.minute ?? 0)
        let secondComponent = Double(timeComponents.second ?? 0)
        let nanoSecondComponent = Double(timeComponents.nanosecond ?? 0)
        
        // Set above components to hours, minutes, seconds properties
        hours.value = hourComponent
        minutes.value = minuteComponent + (secondComponent / 60.0)
        seconds.value = secondComponent + (nanoSecondComponent / pow(10, 9))

        // Trigger a screen refresh
        setNeedsDisplay()
    }
    
    deinit {
        // Animation timer is removed from the current run loop when this view object
        // is deallocated.
        animationTimer?.remove(from: .current, forMode: .common)
    }
    
    // MARK: - Private
    
    private func handEndPoint(with radianValue: Float, and handLength: CGFloat) -> CGPoint {
        return CGPoint(x: handLength * CGFloat(cosf(radianValue)) + frame.size.width / 2.0,
                       y: handLength * CGFloat(sinf(radianValue)) + frame.size.height / 2.0)
    }
}
