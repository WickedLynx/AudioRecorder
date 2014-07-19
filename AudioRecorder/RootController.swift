//
//  RootController.swift
//  AudioRecorder
//
//  Created by Harshad Dange on 19/07/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

import Cocoa
import AVFoundation

// MARK: Extensions
extension Array {
    func firstObject() -> T? {
        var firstObject: T?
        if self.count > 0 {
            firstObject = self[0]
        }
        return firstObject
    }
    
    func lastObject() -> T? {
        var lastObject: T?
        if self.count > 0 {
            lastObject = self[self.endIndex - 1]
        }
        return lastObject
    }
}

extension NSTimeInterval {
    func hourComponent() -> Int {
        return Int(self / 3600)
    }
    
    func minuteComponent() -> Int {
        let remainderByRemovingHours = self % NSTimeInterval(3600)
        return Int(remainderByRemovingHours / 60)
    }
    
    func secondComponent() -> Int {
        let remainderByRemovingHours = self % NSTimeInterval(3600)
        return Int(remainderByRemovingHours % NSTimeInterval(60))
    }
    
    func hhmmss() -> String {
        return String(format: "%02d : %02d : %02d", self.hourComponent(), self.minuteComponent(), self.secondComponent())
    }
}

// MARK: RootController
class RootController: NSObject {
    // MARK: Defined types
    enum ButtonState: Int {
        case NotYetStarted = 0
        case Recording
        
        func buttonTitle() -> String {
            switch self {
            case .NotYetStarted:
                return "Record"
                
            case .Recording:
                return "Stop"
                
            default:
                return String(self.toRaw())
            }
        }
    }

    // MARK: Outlets
    @IBOutlet var recordButton : NSButton
    @IBOutlet var timeField : NSTextField
    
    // MARK: Actions
    @IBAction func clickRecord(sender : NSButton) {

        var nextState = ButtonState.NotYetStarted
        switch recorderState {
        case .NotYetStarted:
            nextState = .Recording
            
            // Create and start recording
            createRecorder()
            recorder?.record()
            
            // Create a timer
            let timerCallback:Selector = Selector("timerChanged:")
            timer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: timerCallback, userInfo: nil, repeats: true)
            timer!.fire()
            
        case .Recording:
            nextState = .NotYetStarted
            
            // Stop recording
            recorder?.stop()
            recorder = nil
            
            // Invalidate the timer
            timer?.invalidate()
            timer = nil
            
            editor = EditorController(windowNibName: "EditorController")
            editor!.powerTrace = powerTrace
            NSApplication.sharedApplication().runModalForWindow(editor!.window)
            
            // Clear the power trace
            powerTrace.removeAll(keepCapacity: false)
        }
        
        recorderState = nextState
        recordButton.title = recorderState.buttonTitle()
    }
    
    // MARK: Instance variables
    var recorder: AVAudioRecorder?
    var recorderState = ButtonState.NotYetStarted
    var timer: NSTimer?
    var powerTrace: Float[] = []
    var editor: EditorController?
    
    // MARK: Overrides
    override func awakeFromNib()  {
        super.awakeFromNib()
        
        updateTimeLabel(0)
    }
    
    // MARK: Instance methods
    func createRecorder() -> () {
        var initialisedRecorder: AVAudioRecorder?
        let fileName = String(NSDate().timeIntervalSince1970) + ".caf"
        var filePaths = NSSearchPathForDirectoriesInDomains(.MusicDirectory, .UserDomainMask, true)
        if let firstPath = filePaths.firstObject() as? String {
            let recordingPath = firstPath.stringByAppendingPathComponent(fileName)
            let url = NSURL(fileURLWithPath: recordingPath)
            initialisedRecorder = AVAudioRecorder(URL: url, settings: nil, error: nil)
            initialisedRecorder!.meteringEnabled = true
            initialisedRecorder!.prepareToRecord()
        }
        recorder = initialisedRecorder
    }
    
    func updateTimeLabel(currentTime: NSTimeInterval?) {
        timeField.stringValue = currentTime?.hhmmss()
    }
    
    func timerChanged(aTimer:NSTimer) {
        if let theRecorder = recorder {
            theRecorder.updateMeters()
            powerTrace.append(theRecorder.peakPowerForChannel(0))
            updateTimeLabel(theRecorder.currentTime)
        } else {
            aTimer.invalidate()
            timer = nil
        }
    }
}
