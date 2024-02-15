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
    private var context: CIContext?
    private var scaleFilter: CIFilter?
    private var scaleTransform: CGAffineTransform?
    // Create the scale factor and transform objects
    let scaleFactor = CGFloat(0.9)
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        super.broadcastStarted(withSetupInfo: setupInfo)
        // Create a CIContext - it can be reused for performance
        // Creating a new one on each sample buffer is too expensive and reduces performance a lot
        context = CIContext(options: nil)
        // Create and start a socket server
        mySocketServer = SocketServer()
        mySocketServer?.startServer(onPort: 9500)
        scaleFilter = CIFilter(name: "CIAffineTransform")
        scaleTransform = CGAffineTransform(scaleX: self.scaleFactor, y: self.scaleFactor)
        scaleFilter!.setValue(scaleTransform, forKey: kCIInputTransformKey)
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
            // Do not spend device resources to handle frames
            // If no clients are connected
            if mySocketServer?.connectedSockets.count == 0 {
                NSLog("Koleo: No clients")
                return
            }
            
            autoreleasepool {
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
                
                scaleFilter!.setValue(ciImage, forKey: kCIInputImageKey)
                // Scale the image into a new object
                if let scaledImage = scaleFilter!.outputImage {
                    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
                    guard let jpegData = context!.jpegRepresentation(of: scaledImage, colorSpace: colorSpace, options: [kCGImageDestinationLossyCompressionQuality
                                                                                                                        as CIImageRepresentationOption : 0.9]) else {
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
