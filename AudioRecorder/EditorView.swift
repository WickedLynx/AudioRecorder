//
//  EditorView.swift
//  AudioRecorder
//
//  Created by Harshad Dange on 19/07/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

import Cocoa
import QuartzCore

class EditorView: NSView {
    
    // MARK: Defined types
    
    enum DragState: Int {
        case Started
        case DraggingFromLeft, DraggingFromRight
        case Ended
    }
    
    struct LevelGroup {
        let levels: Float[]
        var average: Float {
            var total: Float = 0.0
            for level in levels {
                total += level
            }
            return total / Float(levels.count)
        }
        
        init(levels withLevels: Float[]) {
            levels = withLevels
        }
    }
    
    // MARK: instance variables
    var minimumPower: Float = 0
    var maximumPower: Float = 160.0
    var canvasWidth: CGFloat = 0
    var levelGroups: LevelGroup[] = []
    var levelOffset: Float = 0
    var trimView: NSView?
    var dragState = DragState.Ended
    var previousPoint = CGPointZero
    var firstBandX: CGFloat {
    return CGRectGetMidX(bounds) - CGFloat(canvasWidth / 2)
    }
    var canvasRect: CGRect {
    return CGRectMake(firstBandX, 0.0, canvasWidth, bounds.size.height)
    }
    
    // MARK: properties
    var audioLevels: Float[] = [] {
    didSet {
        let totalLevels = audioLevels.count
        let sortedLevels = sort(audioLevels.copy())
        
        if let min = sortedLevels.firstObject() {
            if min < 0 {
                levelOffset = 0 - min
                minimumPower = 0
            } else {
                minimumPower = min
            }
        }
        if let max = sortedLevels.lastObject() {
            maximumPower = max + levelOffset
        }
        var groups: LevelGroup[] = []
        if totalLevels < Int(bounds.size.width) {
            for audioLevel in audioLevels {
                let group = LevelGroup(levels: [audioLevel])
                groups.append(group)
            }
            canvasWidth = CGFloat(totalLevels)
        } else {
            canvasWidth = bounds.size.width
            while (totalLevels % Int(canvasWidth) == 0) {
                --canvasWidth
            }
            
            let levelsInAGroup = totalLevels / Int(canvasWidth)
            var currentGroup: LevelGroup
            var levelsForCurrentGroup: Float[] = []
            
            for level in audioLevels {
                
                levelsForCurrentGroup.append(level)

                if levelsForCurrentGroup.count == levelsInAGroup {
                    currentGroup = LevelGroup(levels: levelsForCurrentGroup)
                    groups.append(currentGroup)
                    levelsForCurrentGroup = []
                }
            }
        }
        
        if let theView = trimView {
            var viewFrame = bounds
            viewFrame.origin.x = CGRectGetMidX(bounds) - CGFloat(canvasWidth / 2)
            viewFrame.size.width = CGFloat(canvasWidth)
            theView.frame = viewFrame
        }
        
        levelGroups = groups
        
        setNeedsDisplayInRect(frame)
    }
    }

    // MARK: Overrides
    
    override func acceptsFirstMouse(theEvent: NSEvent!) -> Bool  {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
    get {
        return true
    }
    }
    
    override func awakeFromNib()  {
        super.awakeFromNib()
        
        trimView = NSView(frame: bounds)
        trimView!.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.OnSetNeedsDisplay
        trimView!.wantsLayer = true
        trimView!.layer = CALayer()
        trimView!.layer.needsDisplayOnBoundsChange = true
        trimView!.layer.autoresizingMask = CAAutoresizingMask.LayerWidthSizable | CAAutoresizingMask.LayerHeightSizable
        
        var trimLayer = CALayer()
        trimLayer.needsDisplayOnBoundsChange = true
        trimLayer.autoresizingMask = CAAutoresizingMask(CAAutoresizingMask.LayerWidthSizable.toRaw() | CAAutoresizingMask.LayerHeightSizable.toRaw())
        trimLayer.backgroundColor = NSColor.blueColor().colorWithAlphaComponent(0.3).CGColor
        trimLayer.borderWidth = 2.0
        trimLayer.cornerRadius = 10.0
        trimLayer.borderColor = NSColor.blueColor().CGColor
        trimLayer.frame = trimView!.layer.bounds
        
        trimView!.layer.addSublayer(trimLayer)
        
        addSubview(trimView)
        
        
        
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        func heightForCurrentBand(level: Float) -> Float {
            let powerFSD: Float = Float(maximumPower - minimumPower)
            let heightFSD: Float = Float(CGRectGetHeight(bounds))
            let height: Float = (level + levelOffset) * (heightFSD / powerFSD)
            return height
        }
        
        var startPointX = firstBandX
        let currentContext: CGContextRef = Unmanaged<CGContext>.fromOpaque(NSGraphicsContext.currentContext().graphicsPort()).takeUnretainedValue()
        
        CGContextSetLineWidth(currentContext, 1.0)
        CGContextSetStrokeColorWithColor(currentContext, NSColor.redColor().CGColor)
        
        for levelGroup in levelGroups {
            let startPoint = CGPointMake(CGFloat(startPointX), 0.0)
            let endPoint = CGPointMake(startPoint.x, CGFloat(heightForCurrentBand(levelGroup.average)))
            let points = [startPoint, endPoint]
            CGContextAddLines(currentContext, points, 2)
            CGContextStrokePath(currentContext)
            ++startPointX
        }
    }
    
    // MARK: Mouse events
    
    override func mouseDown(theEvent: NSEvent!)  {
        if trimView != nil && dragState == .Ended {
            let point = theEvent.locationInWindow
            let cgPoint = NSPointToCGPoint(point)
            let viewFrame = NSRectToCGRect(trimView!.frame)
            if CGRectContainsPoint(viewFrame, cgPoint) {
                let midX = CGRectGetMidX(viewFrame)
                if cgPoint.x > midX {
                    dragState = .DraggingFromRight
                } else {
                    dragState = .DraggingFromLeft
                }
                previousPoint = cgPoint
            }
        }
    }
    
    override func mouseDragged(theEvent: NSEvent!) {
        if (dragState == .DraggingFromRight || dragState == .DraggingFromLeft) && trimView != nil {
            let point = NSPointToCGPoint(theEvent.locationInWindow)
            var targetFrame = NSRectToCGRect(trimView!.frame)
            let deltaX = previousPoint.x - point.x
            if dragState == .DraggingFromLeft {
                targetFrame.origin.x -= deltaX
                targetFrame.size.width += deltaX
            } else {
                targetFrame.size.width -= deltaX
            }
            
            if (targetFrame.size.width > 10.0) && (CGRectContainsRect(canvasRect, targetFrame)) {
                trimView!.frame = targetFrame
            }
            
            previousPoint = point
        }
    }
    
    override func mouseUp(theEvent: NSEvent!)  {
        dragState = .Ended
    }
    
    
}
