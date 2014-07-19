//
//  EditorController.swift
//  AudioRecorder
//
//  Created by Harshad Dange on 20/07/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

import Cocoa

class EditorController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        refreshView()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    var powerTrace: Float[]? {
    didSet {
        refreshView()
    }
    }
    
    func refreshView() -> () {
        if let editorView = self.window.contentView as? EditorView {
            if let trace = powerTrace {
                editorView.audioLevels = trace
            }
        }
    }
    
}
