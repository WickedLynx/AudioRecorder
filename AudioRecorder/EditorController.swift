//
//  EditorController.swift
//  AudioRecorder
//
//  Created by Harshad Dange on 20/07/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreMedia

protocol EditorControllerDelegate {
    func editorControllerDidFinishExporting(editor: EditorController)
}

class EditorController: NSWindowController, EditorViewDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        refreshView()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        editorView.delegate = self
        startField.stringValue = NSTimeInterval(0).hhmmss()
        endField.stringValue = duration.hhmmss()
    }
    
    @IBOutlet var editorView : EditorView
    
    @IBOutlet var startField : NSTextField
    
    @IBOutlet var endField : NSTextField
    
    
    var recordingURL: NSURL?
    var exportSession: AVAssetExportSession?
    var delegate: EditorControllerDelegate?
    
    var powerTrace: Float[]? {
    didSet {
        refreshView()
    }
    }
    
    var duration: NSTimeInterval = 0.0 {
    didSet {
        refreshView()
    }
    }
    @IBAction func clickSave(sender : NSButton) {
        
        if let assetURL = recordingURL {
            let selectedRange = editorView.selectedRange()
            let asset: AVAsset = AVAsset.assetWithURL(assetURL) as AVAsset
            exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)

            let startTime = CMTimeMakeWithSeconds(selectedRange.start, 600)
            let duration = CMTimeMakeWithSeconds((selectedRange.end - selectedRange.start), 600)
            exportSession!.timeRange = CMTimeRange(start: startTime, duration: duration)
            let exportPath = assetURL.path.stringByDeletingPathExtension + "-edited.m4a"
            exportSession!.outputURL = NSURL(fileURLWithPath: exportPath)
            exportSession!.outputFileType = AVFileTypeAppleM4A
            
            exportSession!.exportAsynchronouslyWithCompletionHandler(){
                dispatch_async(dispatch_get_main_queue()){
                    if let theDelegate = self.delegate {
                        theDelegate.editorControllerDidFinishExporting(self)
                    }
                    NSApp.stopModal()
                    self.window.close()
                }
            }
            
            
        }
    }
    
    func refreshView() -> () {
        if editorView != nil {
            editorView.duration = duration
            if let trace = powerTrace {
                editorView.audioLevels = trace
            }
        }
    }
    
    // MARK: EditorViewDelegate methods
    func timeRangeChanged(editor: EditorView, timeRange: (start: NSTimeInterval, end: NSTimeInterval))  {
        startField.stringValue = timeRange.start.hhmmss()
        endField.stringValue = timeRange.end.hhmmss()
    }
    
}
