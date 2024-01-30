//
//  SampleHandler.swift
//  broadcast
//
//  Created by Nikola Shabanov on 30.01.24.
//

import ReplayKit
import CoreImage

class SampleHandler: RPBroadcastSampleHandler {
    var mySocketServer: SocketServer?
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        super.broadcastStarted(withSetupInfo: setupInfo)
        // Create and start a socket server
        mySocketServer = SocketServer()
        mySocketServer?.startServer(onPort: 9500)
    }
    
    override func broadcastPaused() {
        NSLog("Koleo: paused")
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        NSLog("Koleo: resumed")
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        NSLog("Koleo: finished")
        // User has requested to finish the broadcast.
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Get the image buffer from the sample buffer
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                NSLog("Koleo: Failed to guard let imageBuffer")
                return
            }
            
            // Set default image orientation
            var imgOrientation: CGImagePropertyOrientation = .up
            // Try to determine the actual image orientation
            if let orientationAttachment = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber {
                if let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) {
                    switch orientation {
                    case .up,    .upMirrored:    imgOrientation = .up
                    case .down,  .downMirrored:  imgOrientation = .down
                    case .left,  .leftMirrored:  imgOrientation = .right
                    case .right, .rightMirrored: imgOrientation = .left
                    default:   break
                    }
                }
            }
            
            // Create a CIImage from the image buffer
            var ciImage = CIImage(cvImageBuffer: imageBuffer)
            // Orient the CIImage according to the current sampleBuffer image orientation
            ciImage = ciImage.oriented(imgOrientation)
            
            // Create the scale factor and transform objects
            let scaleFactor = CGFloat(0.7)
            let scaleTransform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            
            // Check if the filter exists and set the image and transform
            if let scaleFilter = CIFilter(name: "CIAffineTransform") {
                scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
                scaleFilter.setValue(scaleTransform, forKey: kCIInputTransformKey)
                
                // Scale the image into a new object
                if let scaledImage = scaleFilter.outputImage {
                    // Create a CIContext - it can be reused for performance
                    let context = CIContext(options: nil)
                    
                    // Create a CGImage from the CIImage
                    guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
                        NSLog("Koleo: Failed to guard let cgImage")
                        return }
                    
                    // Create a UIImage from the CGImage
                    let uiImage = UIImage(cgImage: cgImage)
                    
                    // Convert the UIImage to a jpeg data represantation with particular quality
                    guard let jpegData = uiImage.jpegData(compressionQuality: 0.9) else {
                        NSLog("Koleo: failed to guard let jpeg data")
                        return
                    }
                    mySocketServer?.sendDataToAllClients(jpegData)
                }
            }
            
            
            // Handle video sample buffer
            break
        case .audioApp:
            // We do not process audio from apps
            break
        case .audioMic:
            // We do not process audio from mic
            break
        @unknown default:
            // Handle other sample buffer types
            // Shouldn't happen
            fatalError("Koleo: Unknown type of sample buffer")
        }
    }
}
