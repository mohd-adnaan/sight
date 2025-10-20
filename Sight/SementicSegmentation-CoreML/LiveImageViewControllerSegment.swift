import UIKit
import Vision

class LiveImageViewControllerSegment: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var drawingView: DrawingSegmentationView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    // MARK: - AV Properties
    var videoCapture: VideoCaptureSegment!
    
    // MARK - Core ML model
    lazy var segmentationModel: DETRResnet50SemanticSegmentationF16P8? = {
        return try? DETRResnet50SemanticSegmentationF16P8()
    }()

    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    var isInferencing = false
    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    let maf1 = MovingAverageFilterSegment()
    let maf2 = MovingAverageFilterSegment()
    let maf3 = MovingAverageFilterSegment()
    
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
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("Failed to load the CoreML model.")
        }
    }
    
    // MARK: - Setup camera
    func setUpCamera() {
        videoCapture = VideoCaptureSegment()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                DispatchQueue.main.async {
                    if let previewLayer = self.videoCapture.makePreview() {
                        self.videoPreview.layer.addSublayer(previewLayer)
                        self.resizePreviewLayer()
                    }
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    // Start the video capture session in the background
                    self.videoCapture.start()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
}

// MARK: - VideoCaptureSegmentDelegate
extension LiveImageViewControllerSegment : VideoCaptureSegmentDelegate {
    func videoCaptureSegment(_ capture: VideoCaptureSegment, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        // the captured image from camera is contained on pixelBuffer
        if let pixelBuffer = pixelBuffer, !isInferencing {
            isInferencing = true
            
            // start of measure
            self.👨‍🔧.🎬👏()
            
            // predict!
            predict(with: pixelBuffer)
        }
    }
}

// MARK: - Inference
extension LiveImageViewControllerSegment {
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
            
            let segmentationResultMLMultiArray = SegmentationResultMLMultiArray(mlMultiArray: segmentationmap)
            DispatchQueue.main.async { [weak self] in
                // update result
                self?.drawingView.segmentationmap = segmentationResultMLMultiArray
                
                // end of measure
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
extension LiveImageViewControllerSegment: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        self.maf1.append(element: Int(inferenceTime*1000.0))
        self.maf2.append(element: Int(executionTime*1000.0))
        self.maf3.append(element: fps)
        
        self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
        self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
        self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
    }
}

class MovingAverageFilterSegment {
    private var arr: [Int] = []
    private let maxCount = 10
    
    public func append(element: Int) {
        arr.append(element)
        if arr.count > maxCount {
            arr.removeFirst()
        }
    }
    
    public var averageValue: Int {
        guard !arr.isEmpty else { return 0 }
        let sum = arr.reduce(0) { $0 + $1 }
        return Int(Double(sum) / Double(arr.count))
    }
}

//import UIKit
//import Vision
//
//class LiveImageViewControllerSegment: UIViewController {
//
//    // MARK: - UI Properties
//    @IBOutlet weak var videoPreview: UIView!
//    @IBOutlet weak var drawingView: DrawingSegmentationView!
//    
//    @IBOutlet weak var inferenceLabel: UILabel!
//    @IBOutlet weak var etimeLabel: UILabel!
//    @IBOutlet weak var fpsLabel: UILabel!
//    
//    // MARK: - AV Properties
//    var videoCapture: VideoCaptureSegment!
//    
//    // MARK - Core ML model
//    lazy var segmentationModel = {
//        return try! DETRResnet50SemanticSegmentationF16()
//    }()
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
//    let maf1 = MovingAverageFilterSegment()
//    let maf2 = MovingAverageFilterSegment()
//    let maf3 = MovingAverageFilterSegment()
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
//            request?.imageCropAndScaleOption = .scaleFill
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
//        videoCapture.setUp(sessionPreset: .vga640x480) { success in
//            
//            if success {
//                // UI에 비디오 미리보기 뷰 넣기
//                if let previewLayer = self.videoCapture.makePreview() {
//                    self.videoPreview.layer.addSublayer(previewLayer)
//                    self.resizePreviewLayer()
//                }
//                
//                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
//                self.videoCapture.start()
//            }
//        }
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        resizePreviewLayer()
//    }
//    
//    func resizePreviewLayer() {
//        videoCapture.previewLayer?.frame = videoPreview.bounds
//    }
//}
//
//// MARK: - VideoCaptureSegmentDelegate
//extension LiveImageViewControllerSegment : VideoCaptureSegmentDelegate {
//    func videoCaptureSegment(_ capture: VideoCaptureSegment, didCaptureVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
//        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        
//        // the captured image from camera is contained on pixelBuffer
//        if let pixelBuffer = pixelBuffer, !isInferencing {
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
//extension LiveImageViewControllerSegment {
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
//            
//            let segmentationResultMLMultiArray = SegmentationResultMLMultiArray(mlMultiArray: segmentationmap)
//            DispatchQueue.main.async { [weak self] in
//                // update result
//                self?.drawingView.segmentationmap = segmentationResultMLMultiArray
//                
//                // end of measure
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
//extension LiveImageViewControllerSegment: 📏Delegate {
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
//
//class MovingAverageFilterSegment {
//    private var arr: [Int] = []
//    private let maxCount = 10
//    
//    public func append(element: Int) {
//        arr.append(element)
//        if arr.count > maxCount {
//            arr.removeFirst()
//        }
//    }
//    
//    public var averageValue: Int {
//        guard !arr.isEmpty else { return 0 }
//        let sum = arr.reduce(0) { $0 + $1 }
//        return Int(Double(sum) / Double(arr.count))
//    }
//}
