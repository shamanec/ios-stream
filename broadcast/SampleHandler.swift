//
//  SampleHandler.swift
//  broadcast
//
//  Created by Nikola Shabanov on 30.01.24.
//

import ReplayKit
import UIKit
import Photos

class SampleHandler: RPBroadcastSampleHandler {
    var mySocketServer: SocketServer?

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        super.broadcastStarted(withSetupInfo: setupInfo)
        mySocketServer = SocketServer()
        mySocketServer?.startServer(onPort: 9500)
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Get the image buffer from the sample buffer
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                NSLog("Failed to guard let imageBuffer")
                return
            }

                // Create a CIImage from the image buffer
                let ciImage = CIImage(cvImageBuffer: imageBuffer)

                // Create a CIContext - it can be reused for performance
                let context = CIContext(options: nil)

                // Create a CGImage from the CIImage
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                    NSLog("Failed to guard let cgImage")
                    return }

                // Create a UIImage from the CGImage
                let uiImage = UIImage(cgImage: cgImage)
            
            guard let jpegData = uiImage.jpegData(compressionQuality: 0.5) else {
                NSLog("failed to guard let jpeg data")
                return
            }
            mySocketServer?.sendDataToAllClients(jpegData)
            // Handle video sample buffer
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}
