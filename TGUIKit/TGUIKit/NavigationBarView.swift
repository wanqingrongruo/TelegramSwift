//
//  NavigationBarView.swift
//  TGUIKit
//
//  Created by keepcoder on 15/09/16.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa

public struct NavigationBarStyle {
    public let height:CGFloat
    public let enableBorder:Bool
    public init(height:CGFloat, enableBorder:Bool = true) {
        self.height = height
        self.enableBorder = enableBorder
    }
    
    public var has: Bool {
        return height > 0
    }
}

public class NavigationBarView: View {
    
    private var bottomBorder:View = View()
    
    private var leftView:BarView = BarView(frame: NSZeroRect)
    private var centerView:BarView = BarView(frame: NSZeroRect)
    private var rightView:BarView = BarView(frame: NSZeroRect)
    
    override init() {
        super.init()
        self.autoresizingMask = [.width]
        updateLocalizationAndTheme()
    }
    
    required public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.autoresizingMask = [.width]
        updateLocalizationAndTheme()
    }
    
    override public func updateLocalizationAndTheme() {
        super.updateLocalizationAndTheme()
        bottomBorder.backgroundColor = presentation.colors.border
        backgroundColor = presentation.colors.background
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ layer: CALayer, in ctx: CGContext) {
        
        super.draw(layer, in: ctx)
//        ctx.setFillColor(NSColor.white.cgColor)
//        ctx.fill(self.bounds)
//
//        ctx.setFillColor(theme.colors.border.cgColor)
//        ctx.fill(NSMakeRect(0, NSHeight(self.frame) - .borderSize, NSWidth(self.frame), .borderSize))
    }
    
    override public func layout() {
        super.layout()
        self.bottomBorder.setNeedsDisplay()
    }

    override public func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        self.bottomBorder.frame = NSMakeRect(0, newSize.height - .borderSize, newSize.width, .borderSize)
        
        guard let window = window as? Window, !window.inLiveSwiping else {return}

        self.layout(left: leftView, center: centerView, right: rightView)
    }
    
    public override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    
    func layout(left: BarView, center: BarView, right: BarView, force: Bool = false) -> Void {
        
        //

        if frame.height > 0 {
            //proportions = 50 / 25 / 25
            
            let leftWidth = left.isFitted ? left.frame.width : left.fit(to: (right.frame.width == right.minWidth ? frame.width / 3 : frame.width / 4))
            let rightWidth = right.isFitted ? right.frame.width : right.fit(to: (left.frame.width == left.minWidth ? frame.width / 3 : frame.width / 4))
            
            left.frame = NSMakeRect(0, 0, leftWidth, frame.height - .borderSize);
            center.frame = NSMakeRect(left.frame.maxX, 0, frame.width - (leftWidth + rightWidth), frame.height - .borderSize);
            right.frame = NSMakeRect(center.frame.maxX, 0, rightWidth, frame.height - .borderSize);
        }
    }
    
    // ! PUSH !
    //  left from center
    //  right cross fade
    //  center from right
    
    // ! POP !
    // old left -> new center
    // old center -> right
    // old right -> fade
    
    @objc func viewFrameChanged(_ notification:Notification) {
        guard let window = window as? Window, !window.inLiveSwiping else {return}
        layout(left: leftView, center: centerView, right: rightView)
    }
    
    func startMoveViews(left:BarView, center:BarView, right:BarView, direction: SwipeDirection) {
        addSubview(left)
        addSubview(center)
        addSubview(right)
        
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: leftView)
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: centerView)
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: rightView)
        
        
        var nLeft_from:CGFloat = 0, nRight_from:CGFloat = 0, nCenter_from:CGFloat = 0
        
        switch direction {
        case .right:
            
            nLeft_from = round(frame.width - left.frame.width)/2.0
            nCenter_from = left.frame.width + right.frame.width
            nRight_from = right.frame.minX
            
        case .left:
            nLeft_from = 0
            nCenter_from = 0
            nRight_from = right.frame.minX
            
        case .none:
            break
        }
        
        left.setFrameOrigin(nLeft_from, left.frame.minY)
        center.setFrameOrigin(nCenter_from, center.frame.minY)
        right.setFrameOrigin(nRight_from, right.frame.minY)
        
        left.setNeedsDisplay()
        center.setNeedsDisplay()
        right.setNeedsDisplay()
        
        
        left.layer?.opacity = 0
        center.layer?.opacity = 0
        right.layer?.opacity = 0
        
        layout(left: left, center: center, right: right)
        
    }
    
    func moveViews(left:BarView, center:BarView, right:BarView, direction: SwipeDirection, percent: CGFloat, animationStyle:AnimationStyle? = nil) {
        
        var pLeft_to:CGFloat = 0, pRight_to:CGFloat = 0, pCenter_to:CGFloat = 0
        var nLeft_to:CGFloat = 0, nRight_to:CGFloat = 0, nCenter_to:CGFloat = 0
        
        switch direction {
        case .right:
            
            
            //center
            nLeft_to = round(frame.width - left.frame.width)/2.0 - (round(frame.width - left.frame.width)/2.0) * percent
            nCenter_to = left.frame.maxX + right.frame.width - (right.frame.width * percent)
            nRight_to = left.frame.width + center.frame.width
            
            pLeft_to = self.leftView.frame.minX
            pCenter_to = self.leftView.frame.width * (1.0 - percent)
            pRight_to = self.leftView.frame.width + self.centerView.frame.width
            
            break
        case .left:
            
            nLeft_to = 0
            nCenter_to = left.frame.maxX * percent
            nRight_to = left.frame.width + center.frame.width
            
            pLeft_to = self.leftView.frame.minX
            pCenter_to = self.leftView.frame.width + self.centerView.frame.width * percent
            pRight_to = self.leftView.frame.width + self.centerView.frame.width
            break
        case .none:
            break
        }
        
        
        
        left.change(pos: NSMakePoint(floorToScreenPixels(scaleFactor: backingScaleFactor, nLeft_to), left.frame.minY), animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear, completion: { [weak left] completed in
            if completed && animationStyle != nil {
                left?.removeFromSuperview()
            }
        })
        center.change(pos: NSMakePoint(floorToScreenPixels(scaleFactor: backingScaleFactor, nCenter_to), center.frame.minY), animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear, completion: { [weak center] completed in
            if completed && animationStyle != nil {
                center?.removeFromSuperview()
            }
        })
        right.change(pos: NSMakePoint(floorToScreenPixels(scaleFactor: backingScaleFactor, nRight_to), right.frame.minY), animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear, completion: { [weak right] completed in
            if completed && animationStyle != nil {
                right?.removeFromSuperview()
            }
        })
        
        
        self.leftView.change(pos: NSMakePoint(floorToScreenPixels(scaleFactor: backingScaleFactor, pLeft_to), self.leftView.frame.minY), animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)
        self.centerView.change(pos: NSMakePoint(floorToScreenPixels(scaleFactor: backingScaleFactor, pCenter_to), self.centerView.frame.minY), animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)
        self.rightView.change(pos: NSMakePoint(floorToScreenPixels(scaleFactor: backingScaleFactor, pRight_to), self.rightView.frame.minY), animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)

        
        
        left.change(opacity: percent, animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)
        center.change(opacity: percent, animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)
        right.change(opacity: percent, animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)

        self.leftView.change(opacity: 1.0 - percent, animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function  ?? .linear)
        self.centerView.change(opacity: 1.0 - percent, animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)
        self.rightView.change(opacity: 1.0 - percent, animated: animationStyle != nil, duration: animationStyle?.duration ?? 0, timingFunction: animationStyle?.function ?? .linear)
        
    }
    
    public func switchViews(left:BarView, center:BarView, right:BarView, controller:ViewController, style:ViewControllerStyle, animationStyle:AnimationStyle, liveSwiping: Bool) {
        
      //  var animationStyle = AnimationStyle.init(duration: 3.0, function: animationStyle.function)
        

        
        if !liveSwiping {
            layout(left: left, center: center, right: right)
        }
        
        
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: leftView)
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: centerView)
        NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: rightView)
        
        self.bottomBorder.isHidden = !controller.bar.enableBorder
        if style != .none {
            
            
            
            CATransaction.begin()
            
            if !liveSwiping {
                self.addSubview(left)
                self.addSubview(center)
                self.addSubview(right)
            }
            self.addSubview(bottomBorder)

            
            left.setNeedsDisplay()
            center.setNeedsDisplay()
            right.setNeedsDisplay()
            
            let pLeft = self.leftView
            let pCenter = self.centerView
            let pRight = self.rightView
            
            if !liveSwiping {
                left.layer?.opacity = 0
                center.layer?.opacity = 0
                right.layer?.opacity = 0
            }
            
            pLeft.updateLocalizationAndTheme()
            pCenter.updateLocalizationAndTheme()
            pRight.updateLocalizationAndTheme()
            
            self.leftView = left
            self.centerView = center
            self.rightView = right
            
            var pLeft_from:CGFloat = 0,pRight_from:CGFloat = 0, pCenter_from:CGFloat = 0, pLeft_to:CGFloat = 0, pRight_to:CGFloat = 0, pCenter_to:CGFloat = 0
            var nLeft_from:CGFloat = 0, nRight_from:CGFloat = 0, nCenter_from:CGFloat = 0, nLeft_to:CGFloat = 0, nRight_to:CGFloat = 0, nCenter_to:CGFloat = 0
            
            switch style {
            case .push:
                
                //left
                pLeft_from = liveSwiping ? pLeft.frame.minX : 0
                pLeft_to = 0
                nLeft_from = liveSwiping ? left.frame.minX : round(frame.width - left.frame.width)/2.0
                nLeft_to = 0
                
                //center
                pCenter_from = liveSwiping ? pCenter.frame.minX : pLeft.frame.width
                pCenter_to = 0
                
                nCenter_from = liveSwiping ? center.frame.minX : left.frame.width + center.frame.width
                nCenter_to = left.frame.width
                
                //right
                pRight_from = right.frame.minX
                pRight_to = right.frame.minX
                nRight_from = right.frame.minX
                nRight_to = right.frame.minX
                
                break
            case .pop:
                
                //left
                pLeft_from = liveSwiping ? pLeft.frame.minX : 0
                pLeft_to = 0
                nLeft_from = liveSwiping ? left.frame.minX : 0
                nLeft_to = 0
                
                //center
                pCenter_from = liveSwiping ? pCenter.frame.minX : center.frame.minX
                pCenter_to = left.frame.width + center.frame.width
                nCenter_from = liveSwiping ? center.frame.minX : 0
                nCenter_to = left.frame.maxX
                
                //right
                pRight_from = liveSwiping ? pRight.frame.minX : right.frame.minX
                pRight_to = right.frame.minX
                nRight_from = right.frame.minX
                nRight_to = right.frame.minX

                
                break
            case .none:
                break
            }
            
            
            
            left.setFrameOrigin(nLeft_from, left.frame.minY)
            center.setFrameOrigin(nCenter_from, center.frame.minY)
            right.setFrameOrigin(nRight_from, right.frame.minY)
            
            pLeft.setFrameOrigin(pLeft_from, left.frame.minY)
            pCenter.setFrameOrigin(pCenter_from, pCenter.frame.minY)
            pRight.setFrameOrigin(pRight_from, pRight.frame.minY)
            
                        
//
            // old
            pLeft.change(opacity: 0.0, duration: animationStyle.duration, timingFunction: animationStyle.function, completion:{ [weak pLeft] completed in
                if completed {
                    pLeft?.removeFromSuperview()
                }
            })
            pLeft.change(pos: NSMakePoint(pLeft_to, pLeft.frame.minY), animated: true, duration: animationStyle.duration, timingFunction: animationStyle.function)

            pCenter.change(opacity: 0.0, duration: animationStyle.duration, timingFunction: animationStyle.function, completion:{ [weak pCenter] completed in
                if completed {
                    pCenter?.removeFromSuperview()
                }
            })
            pCenter.change(pos: NSMakePoint(pCenter_to, pCenter.frame.minY), animated: true, duration: animationStyle.duration, timingFunction: animationStyle.function)

            
            pRight.change(opacity: 0.0, duration: animationStyle.duration, timingFunction: animationStyle.function, completion:{ [weak pRight] completed in
                if completed {
                    pRight?.removeFromSuperview()
                }
            })
            pRight.change(pos: NSMakePoint(pRight_to, pRight.frame.minY), animated: true, duration: animationStyle.duration, timingFunction: animationStyle.function)

            // new
            if !left.isHidden {
                left.change(opacity: 1.0, duration: animationStyle.duration, timingFunction: animationStyle.function)
            }
            left.change(pos: NSMakePoint(nLeft_to, left.frame.minY), animated: true, duration: animationStyle.duration, timingFunction: animationStyle.function)
           
            
            if !center.isHidden {
                center.change(opacity: 1.0, duration: animationStyle.duration, timingFunction: animationStyle.function)
            }
            
            center.change(pos: NSMakePoint(nCenter_to, center.frame.minY), animated: true, duration: animationStyle.duration, timingFunction: animationStyle.function)

            
            if !right.isHidden {
                right.change(opacity: 1.0, duration: animationStyle.duration, timingFunction: animationStyle.function)
            }
            right.change(pos: NSMakePoint(nRight_to, right.frame.minY), animated: true, duration: animationStyle.duration, timingFunction: animationStyle.function)

            
            
            CATransaction.commit()

        } else {
            self.removeAllSubviews()
            self.addSubview(left)
            self.addSubview(center)
            self.addSubview(right)
            
            self.leftView = left
            self.centerView = center
            self.rightView = right
            
            self.addSubview(bottomBorder)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewFrameChanged(_:)), name: NSView.frameDidChangeNotification, object: left)
        NotificationCenter.default.addObserver(self, selector: #selector(viewFrameChanged(_:)), name: NSView.frameDidChangeNotification, object: center)
        NotificationCenter.default.addObserver(self, selector: #selector(viewFrameChanged(_:)), name: NSView.frameDidChangeNotification, object: right)
        
    }
    
}
