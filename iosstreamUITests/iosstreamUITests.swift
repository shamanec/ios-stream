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
    
    func getDeviceModelNumber() -> (Double, Bool){
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        print(identifier)
        let trimmedString = identifier.replacingOccurrences(of: "iPhone", with: "")
        let formattedString = trimmedString.replacingOccurrences(of: ",", with: ".")
        if let finalNumber = Double(formattedString) {
            return (finalNumber, true)
        } else {
            return (0.0, false)
        }
    }
    

    func testStartBroadcast() throws {
        // Go to Springboard(Home)
        // Do it twice just in case
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        
        let interfaceIdiom = UIDevice.current.userInterfaceIdiom.rawValue
        if interfaceIdiom == 1 {
            print("Device is an iPad, opening Control Center from the top right")
            openTopControlCenter()
        } else {
            let (model, ok) = getDeviceModelNumber()
            XCTAssertTrue(ok, "Could not get device model number to determine how to open the control center")
            if model >= 10.3 && model != 12.8 && model != 14.6 && model != 10.4 && model != 10.5 {
                print("Device is an iPhone X or above, opening Control Center from the top right")
                openTopControlCenter()
            } else {
                print("Device is an iPhone 8 or below, opening Control center from the bottom")
                openControlCenter()
            }
        }
        
        sleep(1)
        let recordingBtn = app.buttons["Screen Recording"]
        XCTAssertTrue(recordingBtn.exists, "Recording is not added to the device Control Center, please add it from Settings > Control Center!")
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
    
    func openTopControlCenter() {
        self.executeUnderReflectionIdleHack {
            let coord1 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.01))
            let coord2 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
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
