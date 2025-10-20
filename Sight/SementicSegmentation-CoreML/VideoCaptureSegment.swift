import UIKit
import AVFoundation
import CoreVideo

public protocol VideoCaptureSegmentDelegate: class {
    func videoCaptureSegment(_ capture: VideoCaptureSegment, didCaptureVideoSampleBuffer: CMSampleBuffer)
}

public class VideoCaptureSegment: NSObject {
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VideoCaptureSegmentDelegate?
    public var fps = 15
    
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "com.tucan9389.camera-queue")
    
    var videoTextureCache: CVMetalTextureCache?
    
    public func setUp(sessionPreset: AVCaptureSession.Preset = .vga640x480,
                      completion: @escaping (Bool) -> Void) {
        self.setUpCamera(sessionPreset: sessionPreset, completion: { success in
            completion(success)
        })
    }
    
    func setUpCamera(sessionPreset: AVCaptureSession.Preset, position: AVCaptureDevice.Position? = .back, completion: @escaping (_ success: Bool) -> Void) {
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset
        
        
        let device: AVCaptureDevice?
        if let position = position {
            device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: position).devices.first
        } else {
            device = AVCaptureDevice.default(for: AVMediaType.video)
        }
        
        guard let captureDevice = device else {
            print("Error: no video devices available")
            return
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Error: could not create AVCaptureDeviceInput")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let settings: [String : Any] = [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
        ]
        
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this _after_ addOutput()!
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait

        captureSession.commitConfiguration()
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)
        
        let success = true
        completion(success)
    }
    
    public func start() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    public func stop() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.stopRunning()
            }
        }
    }

    
    public func makePreview() -> AVCaptureVideoPreviewLayer? {
        guard self.previewLayer == nil else { return self.previewLayer }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // Fill to avoid pillar-boxing on tall screens.
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.backgroundColor = UIColor.systemBackground.cgColor
        previewLayer.connection?.videoOrientation = .portrait
        self.previewLayer = previewLayer
        return previewLayer
    }
}

extension VideoCaptureSegment: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.videoCaptureSegment(self, didCaptureVideoSampleBuffer: sampleBuffer)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("dropped frame")
    }
}
