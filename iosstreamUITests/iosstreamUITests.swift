//
//  iosstreamUITests.swift
//  iosstreamUITests
//
//  Created by Nikola Shabanov on 11.02.24.
//

import XCTest

final class iosstreamUITests: XCTestCase {
    static var isReflectionIdleEnabled = false
    let app = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    override func setUpWithError() throws {
        continueAfterFailure = false

    }

    override func tearDownWithError() throws {
        
    }

    func testStartBroadcast() throws {
        // Go to Springboard(Home)
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        
        openControlCenter()
        sleep(1)
        let recordingBtn = app.buttons["Screen Recording"]
        if recordingBtn.isSelected {
            print("Recording is already in progress, stopping it")
            recordingBtn.tap()
        }
        openRecording()
        sleep(1)
        selectBroadcastApp()
        sleep(1)
        startBroadcast()
        sleep(5)
        print(app.debugDescription)
        // Go to Springboard(Home)
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(1)
        print(app.debugDescription)
    }
    
    func openRecording() {
        self.executeUnderReflectionIdleHack {
            let recordingBtn = app.buttons["Screen Recording"]
            recordingBtn.press(forDuration: 2, thenDragTo: recordingBtn, withVelocity: 1, thenHoldForDuration: 2)
        }
    }
    
    func selectBroadcastApp() {
        self.executeUnderReflectionIdleHack {
            print(app.debugDescription)
            let scrollView = app.scrollViews.element(boundBy: 2)
            let broadCastSelectBtn = scrollView.buttons["broadcast"]
            if broadCastSelectBtn.isSelected {
                NSLog("Broadcast app already selected")
                return
            }
            broadCastSelectBtn.tap()
        }
    }
    
    func startBroadcast() {
        self.executeUnderReflectionIdleHack {
            let startBroadcastBtn = app.buttons["Start Broadcast"]
            startBroadcastBtn.tap()
        }
    }
    
    func openControlCenter() {
        self.executeUnderReflectionIdleHack {
            let coord1 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99))
            let coord2 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            coord1.press(forDuration: 0.1, thenDragTo: coord2)
        }
    }
    
    /// Function to turn on/off the hack that disables waitForQuiescenceIncludingAnimationsIdle - the method that forces the test to wait until the app is idle - by replacing it with the [replace()](x-source-tag://replace) method
        /// - Parameter state: Bool parameter to activate/deactivate the app idle wait logic
        private func setReflectionIdleHack(_ state: Bool) {
            let selector = Selector(("waitForQuiescenceIncludingAnimationsIdle:"))
            guard let clazz = objc_getClass("XCUIApplicationProcess") as? AnyClass,
                let current = class_getInstanceMethod(clazz, selector),
                let replaced = class_getInstanceMethod(type(of: self), #selector(self.replace)) else {
                    print("[UITest] failed to set up idle-wait reflection hack")
                    return
            }
            
            if state != iosstreamUITests.isReflectionIdleEnabled {
                method_exchangeImplementations(current, replaced)
                print("[UITest] reflection idle hack " + (state ? "set" : "unset"))
                iosstreamUITests.isReflectionIdleEnabled = state
            }
        }
        
        /// - Tag: replace
        @objc func replace() {
            print("[UITest] calling reflection idle replaced method")
            return
        }
        
        // Disable idle wait logic until code inside is executed and then reenable it
        private func executeUnderReflectionIdleHack(_ block: () -> Void) {
            self.setReflectionIdleHack(true)
            block()
            self.setReflectionIdleHack(false)
        }
}
