//
//  AppDelegate.swift
//  AudioRecorder
//
//  Created by Harshad Dange on 19/07/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet var window: NSWindow!


    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }


}

