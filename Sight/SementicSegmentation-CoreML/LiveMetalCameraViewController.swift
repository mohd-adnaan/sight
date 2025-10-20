import UIKit
import Vision

class LiveMetalCameraViewController: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var metalVideoPreview: MetalVideoView!
    @IBOutlet weak var drawingView: DrawingSegmentationView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    var cameraTextureGenerater = CameraTextureGenerater()
    var multitargetSegmentationTextureGenerater = MultitargetSegmentationTextureGenerater()
    var overlayingTexturesGenerater = OverlayingTexturesGenerater()
    
    var cameraTexture: Texture?
    var segmentationTexture: Texture?
    
    // MARK: - AV Properties
    var videoCapture: VideoCaptureSegment!
    
    // MARK - Core ML model
    lazy var segmentationModel: DETRResnet50SemanticSegmentationF16P8? = {
        return try? DETRResnet50SemanticSegmentationF16P8()
    }()
    let numberOfLabels = 21
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    var isInferencing = false
    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup ml model
        setUpModel()
        
        // setup camera
        setUpCamera()
        
        // setup delegate for performance measurement
        👨‍🔧.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
                self.videoCapture.start()
            }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop video capture
        DispatchQueue.global(qos: .userInitiated).async {
            self.videoCapture.stop()
        }
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        // Safely unwrap segmentationModel
        if let segmentationModel = segmentationModel,
           let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .centerCrop
        } else {
            fatalError("Failed to load the CoreML model or create VNCoreMLModel.")
        }
    }

    
    // MARK: - Setup camera
    func setUpCamera() {
        videoCapture = VideoCaptureSegment()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
            
            if success {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.videoCapture.start()
                }
            }
        }
    }
}

// MARK: - VideoCaptureDelegate
extension LiveMetalCameraViewController: VideoCaptureSegmentDelegate {
    func videoCaptureSegment(_ capture: VideoCaptureSegment, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        
        // 카메라 프리뷰 텍스쳐
        cameraTexture = cameraTextureGenerater.texture(from: sampleBuffer)
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if !isInferencing {
            isInferencing = true

            // start of measure
            self.👨‍🔧.🎬👏()

            // predict!
            predict(with: pixelBuffer)
        }
    }
}

// MARK: - Inference
extension LiveMetalCameraViewController {
    // prediction
    func predict(with pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    // post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let segmentationmap = observations.first?.featureValue.multiArrayValue {
            guard let row = segmentationmap.shape[0] as? Int,
                let col = segmentationmap.shape[1] as? Int else {
                    return
            }
            
            guard let cameraTexture = cameraTexture,
                  let segmentationTexture = multitargetSegmentationTextureGenerater.texture(segmentationmap, row, col, numberOfLabels) else {
                return
            }
            
            let overlayedTexture = overlayingTexturesGenerater.texture(cameraTexture, segmentationTexture)
            metalVideoPreview.currentTexture = overlayedTexture
            
            DispatchQueue.main.async { [weak self] in
                self?.👨‍🔧.🎬🤚()
                self?.isInferencing = false
            }
        } else {
            // end of measure
            self.👨‍🔧.🎬🤚()
            isInferencing = false
        }
    }
}

// MARK: - 📏(Performance Measurement) Delegate
extension LiveMetalCameraViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        self.maf1.append(element: Int(inferenceTime*1000.0))
        self.maf2.append(element: Int(executionTime*1000.0))
        self.maf3.append(element: fps)
        
        self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
        self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
        self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
    }
}

//import UIKit
//import Vision
//
//class LiveMetalCameraViewController: UIViewController {
//
//    // MARK: - UI Properties
//    @IBOutlet weak var metalVideoPreview: MetalVideoView!
//    @IBOutlet weak var drawingView: DrawingSegmentationView!
//    
//    @IBOutlet weak var inferenceLabel: UILabel!
//    @IBOutlet weak var etimeLabel: UILabel!
//    @IBOutlet weak var fpsLabel: UILabel!
//    
//    var cameraTextureGenerater = CameraTextureGenerater()
//    var multitargetSegmentationTextureGenerater = MultitargetSegmentationTextureGenerater()
//    var overlayingTexturesGenerater = OverlayingTexturesGenerater()
//    
//    var cameraTexture: Texture?
//    var segmentationTexture: Texture?
//    
//    // MARK: - AV Properties
//    var videoCapture: VideoCaptureSegment!
//    
//    // MARK - Core ML model
//    lazy var segmentationModel = { return try! DETRResnet50SemanticSegmentationF16() }()
//    let numberOfLabels = 21
//    
//    // MARK: - Vision Properties
//    var request: VNCoreMLRequest?
//    var visionModel: VNCoreMLModel?
//    
//    var isInferencing = false
//    
//    // MARK: - Performance Measurement Property
//    private let 👨‍🔧 = 📏()
//    
//    let maf1 = MovingAverageFilter()
//    let maf2 = MovingAverageFilter()
//    let maf3 = MovingAverageFilter()
//    
//    // MARK: - View Controller Life Cycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // setup ml model
//        setUpModel()
//        
//        // setup camera
//        setUpCamera()
//        
//        // setup delegate for performance measurement
//        👨‍🔧.delegate = self
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.videoCapture.start()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.videoCapture.stop()
//    }
//    
//    // MARK: - Setup Core ML
//    func setUpModel() {
//        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
//            self.visionModel = visionModel
//            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
//            request?.imageCropAndScaleOption = .centerCrop
//        } else {
//            fatalError()
//        }
//    }
//    
//    // MARK: - Setup camera
//    func setUpCamera() {
//        videoCapture = VideoCaptureSegment()
//        videoCapture.delegate = self
//        videoCapture.fps = 50
//        videoCapture.setUp(sessionPreset: .hd1280x720) { success in
//            
//            if success {
//                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
//                self.videoCapture.start()
//            }
//        }
//    }
//}
//
//// MARK: - VideoCaptureDelegate
//extension LiveMetalCameraViewController: VideoCaptureSegmentDelegate {
//    func videoCaptureSegment(_ capture: VideoCaptureSegment, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
//        
//        // 카메라 프리뷰 텍스쳐
//        cameraTexture = cameraTextureGenerater.texture(from: sampleBuffer)
//        
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        if !isInferencing {
//            isInferencing = true
//
//            // start of measure
//            self.👨‍🔧.🎬👏()
//
//            // predict!
//            predict(with: pixelBuffer)
//        }
//    }
//}
//
//// MARK: - Inference
//extension LiveMetalCameraViewController {
//    // prediction
//    func predict(with pixelBuffer: CVPixelBuffer) {
//        guard let request = request else { fatalError() }
//        
//        // vision framework configures the input size of image following our model's input configuration automatically
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
//        try? handler.perform([request])
//    }
//    
//    // post-processing
//    func visionRequestDidComplete(request: VNRequest, error: Error?) {
//        self.👨‍🔧.🏷(with: "endInference")
//        
//        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
//            let segmentationmap = observations.first?.featureValue.multiArrayValue {
//            guard let row = segmentationmap.shape[0] as? Int,
//                let col = segmentationmap.shape[1] as? Int else {
//                    return
//            }
//            
//            guard let cameraTexture = cameraTexture,
//                  let segmentationTexture = multitargetSegmentationTextureGenerater.texture(segmentationmap, row, col, numberOfLabels) else {
//                return
//            }
//            
//            let overlayedTexture = overlayingTexturesGenerater.texture(cameraTexture, segmentationTexture)
//            metalVideoPreview.currentTexture = overlayedTexture
//            
//            DispatchQueue.main.async { [weak self] in
//                self?.👨‍🔧.🎬🤚()
//                self?.isInferencing = false
//            }
//        } else {
//            // end of measure
//            self.👨‍🔧.🎬🤚()
//            isInferencing = false
//        }
//    }
//}
//
//// MARK: - 📏(Performance Measurement) Delegate
//extension LiveMetalCameraViewController: 📏Delegate {
//    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
//        self.maf1.append(element: Int(inferenceTime*1000.0))
//        self.maf2.append(element: Int(executionTime*1000.0))
//        self.maf3.append(element: fps)
//        
//        self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
//        self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
//        self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
//    }
//}
