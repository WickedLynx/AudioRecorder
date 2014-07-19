//
//  EditorView.swift
//  AudioRecorder
//
//  Created by Harshad Dange on 19/07/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

import Cocoa

class EditorView: NSView {
    
    // MARK: Defined types
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
    var optimumWidth: Int = 0
    var levelGroups: LevelGroup[] = []
    var levelOffset: Float = 0
    
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
        if totalLevels < Int(self.bounds.size.width) {
            for audioLevel in audioLevels {
                let group = LevelGroup(levels: [audioLevel])
                groups.append(group)
            }
            optimumWidth = totalLevels
        } else {
            optimumWidth = Int(self.bounds.size.width)
            while (totalLevels % optimumWidth == 0) {
                --optimumWidth
            }
            
            let levelsInAGroup = totalLevels / optimumWidth
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
        
        levelGroups = groups
        
        self.setNeedsDisplayInRect(self.frame)
    }
    }

    // MARK: Overrides
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        func heightForCurrentBand(level: Float) -> Float {
            let powerFSD: Float = Float(maximumPower - minimumPower)
            let heightFSD: Float = Float(CGRectGetHeight(self.bounds))
            let height: Float = (level + levelOffset) * (heightFSD / powerFSD)
            return height
        }
        
        var startPointX = Int(CGRectGetMidX(self.bounds)) - Int(optimumWidth / 2)
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
}
