//
//  MovingLogo.swift
//  DVDScreenSaver-TestApp
//
//  Created by Kevin Wojniak on 3/23/19.
//  Copyright © 2019 Kevin Wojniak. All rights reserved.
//

import Cocoa

typealias RectDbl = NSRect

extension RectDbl {

    public var right: CGFloat {
        return origin.x + width
    }
    
    public var bottom: CGFloat {
        return origin.y + height
    }
    
    public var diagonal: CGFloat {
        return sqrt(pow(width, 2) + pow(height, 2))
    }

}

class Stopwatch {
    
    private var time = Date()

    public func start() {
        time = Date()
    }
    
    public var elapsedMilliseconds: CGFloat {
        return round(CGFloat(Date().timeIntervalSince(time)) * 1000)
    }
    
    public func restart() {
        start()
    }
    
}

class MovingLogo {
    
    enum MoveMode {
        case normal
        case opposite
        case allCorners
    }
    
    typealias OnNewPosition = (NSRect) -> Void
    private let onNewPosition: OnNewPosition
    typealias OnRedraw = (NSImage) -> Void
    private let onRedraw: OnRedraw
    
    private var colorIdx = -1
    private let watch = Stopwatch()
    private var rect = RectDbl()
    private var bounds = RectDbl()
    private var scale = CGFloat()

    private let image: NSImage
    private let colors: [NSColor]
    private var mode: MoveMode = .normal
    private var moveRight = true
    private var moveDown = true
    private var speed: CGFloat = 2
    
    init(image: NSImage, colors: [NSColor], onNewPosition: @escaping OnNewPosition, onRedraw: @escaping OnRedraw) {
        self.image = image
        self.colors = colors
        self.onNewPosition = onNewPosition
        self.onRedraw = onRedraw
        self.rect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        self.watch.start()
    }
    
    public func animate() {
        let origX = rect.origin.x
        let origY = rect.origin.y
        var x = origX
        var y = origY
        var bOutOfBounds = false
        
        if rect.right >= bounds.right {
            moveRight = false
            bOutOfBounds = true
        } else if rect.origin.x <= bounds.origin.x {
            moveRight = true
            bOutOfBounds = true
        }
        
        if rect.bottom >= bounds.bottom {
            moveDown = false
            bOutOfBounds = true
        } else if rect.origin.y <= bounds.origin.y {
            moveDown = true
            bOutOfBounds = true
        }
        
        if bOutOfBounds {
            nextColor()
        }

        switch mode {
        case .normal:
            x += moveRight ? speed : -speed
            y += moveDown ? speed : -speed
        case .opposite:
            let width = bounds.width - rect.width
            let height = bounds.height - rect.height
            let theta = atan(height / width)
            let hyppos = sqrt(pow(x - bounds.origin.x, 2) + pow(y - bounds.origin.y, 2))
            x = (hyppos + (moveRight ? speed : -speed) * 2) * cos(theta)
            y = (hyppos + (moveDown ? speed : -speed) * 2) * sin(theta)
        case .allCorners:
            //TODO
            break
        }

        let step = watch.elapsedMilliseconds / 10
        let moveX = (x - origX) * step
        let moveY = (y - origY) * step
        rect.origin.x += moveX
        rect.origin.y += moveY

        onNewPosition(rect)
        watch.restart()
    }
    
    public func rescale(bounds: NSRect, scale: CGFloat) {
        self.bounds = bounds
        self.scale = scale
        let ratio = image.size.width / image.size.height
        rect.size.height = bounds.diagonal / scale / ratio
        rect.size.width = rect.height * ratio
        rect.origin.x = min(max(rect.origin.x, 0), bounds.width - rect.width)
        rect.origin.y = min(max(rect.origin.y, 0), bounds.height - rect.height)
        animate()
    }
    
    public func nextMode() {
        switch mode {
        case .normal:
            mode = .opposite
        case .opposite:
            mode = .normal
            placeInRandomSpot()
        case .allCorners:
            mode = .normal
        }
    }

    public func nextColor() {
        colorIdx = (colorIdx + 1) % colors.count
        let image = recolorLogo(colors[colorIdx])
        onRedraw(image)
    }

    public func placeInRandomSpot() {
        rect.origin.x = floor(CGFloat.random(in: 0 ..< (bounds.width - rect.width)))
        rect.origin.y = floor(CGFloat.random(in: 0 ..< (bounds.height - rect.height)))
        animate()
    }

    private func recolorLogo(_ color: NSColor) -> NSImage {
        return NSImage(size: image.size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current else {
                return false
            }
            ctx.saveGraphicsState()
            defer {
                ctx.restoreGraphicsState()
            }
            ctx.compositingOperation = .sourceAtop
            self.image.draw(in: rect)
            color.setFill()
            NSBezierPath.fill(rect)
            return true
        }
    }

}
