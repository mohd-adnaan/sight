import UIKit
import Vision
import AVFoundation

class LiveImageViewController: UIViewController {
    
    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var labelLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    private var lastSpokenLabel: String = ""
    private var lastSpokenTime: Date = Date(timeIntervalSince1970: 0)
    
    // MARK - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    // MARK - Core ML model
    lazy var classificationModel = { return try! FastViTT8F16Headless() }()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    // MARK: - AV Properties
    var videoCapture: VideoCapture!
    
    // MARK: - Text-to-Speech
    let synthesizer = AVSpeechSynthesizer()
    
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
        
        // Stop any ongoing speech synthesis
        self.synthesizer.stopSpeaking(at: .immediate)
    }

    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: classificationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError()
        }
    }
    
    
    // MARK: - 초기 세팅
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // UI에 비디오 미리보기 뷰 넣기
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
                self.videoCapture.start()
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

// MARK: - VideoCaptureDelegate
extension LiveImageViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        if let pixelBuffer = pixelBuffer {
            
            // start of measure
            self.👨‍🔧.🎬👏()
            
            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

// MARK: - Inference
extension LiveImageViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        // middle of measure
        self.👨‍🔧.🏷(with: "endInference")
        
        if let classificationResults = request.results as? [VNClassificationObservation] {
            showClassificationResult(results: classificationResults)
        } else if let mlFeatureValueResults = request.results as? [VNCoreMLFeatureValueObservation] {
            showCustomResult(results: mlFeatureValueResults)
        }
        
        DispatchQueue.main.sync {
            // end of measure
            self.👨‍🔧.🎬🤚()
        }
    }
    
    func showClassificationResult(results: [VNClassificationObservation]) {
        // Filter only the highest confidence result
        guard let topResult = results.max(by: { $0.confidence < $1.confidence }),
              topResult.confidence > 0.3 else { // Minimum confidence threshold
            showFailResult()
            return
        }
        
        showResults(objectLabel: topResult.identifier, confidence: topResult.confidence)
    }
    
    func showResults(objectLabel: String, confidence: VNConfidence) {
        DispatchQueue.main.sync {
            self.labelLabel.text = objectLabel
            self.confidenceLabel.text = "\(round(confidence * 100)) %"
            
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(lastSpokenTime)
            
            // Only speak if label changed AND 3 seconds passed (increased from 1)
            if objectLabel != lastSpokenLabel && timeInterval > 3.0 && confidence > 0.5 {
                lastSpokenLabel = objectLabel
                lastSpokenTime = currentTime
                
                if self.synthesizer.isSpeaking {
                    self.synthesizer.stopSpeaking(at: .immediate)
                }
                
                let utterance = AVSpeechUtterance(string: objectLabel)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                
                self.synthesizer.speak(utterance)
            }
        }
    }
    
    func showCustomResult(results: [VNCoreMLFeatureValueObservation]) {
        guard results.first != nil else {
            showFailResult()
            return
        }
        
        showFailResult() // TODO
    }
    
    func showFailResult() {
        DispatchQueue.main.sync {
            self.labelLabel.text = "n/a result"
            self.confidenceLabel.text = "-- %"
        }
    }
}

// MARK: - 📏(Performance Measurement) Delegate
extension LiveImageViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        DispatchQueue.main.async {
            self.inferenceLabel.text = "inference: \(Int(inferenceTime*1000.0)) ms"
            self.etimeLabel.text = "execution: \(Int(executionTime*1000.0)) ms"
            self.fpsLabel.text = "fps: \(fps)"
        }
    }
}
