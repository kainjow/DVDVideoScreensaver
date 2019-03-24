//
//  DVDScreenSaverView.swift
//  DVDScreenSaver-TestApp
//
//  Created by Kevin Wojniak on 3/23/19.
//  Copyright © 2019 Kevin Wojniak. All rights reserved.
//

import Cocoa

extension NSColor {
    
    convenience init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        self.init(calibratedRed: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1)
    }
    
}

class DVDScreenSaverView: NSView {
    
    @IBOutlet weak var imageView: NSImageView!
    
    private let logoScale: CGFloat = 6
    private var logo: MovingLogo?
    private var timer: Timer?
    
    override func awakeFromNib() {
        guard let image = NSImage(named: "DVDVideo360"),
            let superview = self.imageView.superview else {
            print("Setup failed")
            return
        }
        logo = MovingLogo(
            image: image,
            colors: [
                NSColor(190, 0, 255),
                NSColor(255, 0, 139),
                NSColor(255, 131, 0),
                NSColor(0, 38, 255),
                NSColor(255, 250, 0),
            ],
            onNewPosition: { rect in
                self.imageView.frame = rect
            },
            onRedraw: { image in
                self.imageView.image = image
            }
        )
        let rescale = {
            self.logo?.rescale(bounds: superview.bounds, scale: self.logoScale)
        }
        logo?.nextColor()
        rescale()
        logo?.placeInRandomSpot()
        superview.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: superview, queue: nil) { _ in
            rescale()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            self.logo?.animate()
        }
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .eventTracking)
        }
    }
    
    override func viewDidMoveToWindow() {
        if let win = window {
            win.backgroundColor = .black
        }
    }
    
}
