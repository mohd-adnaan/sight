

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
    let classificationModel = MobileNetV2Int8LUT()
    
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

//// MARK: - VideoCaptureDelegate
//extension LiveImageViewController: VideoCaptureDelegate {
//    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?/*, timestamp: CMTime*/) {
//        
//        // 카메라에서 캡쳐된 화면은 pixelBuffer에 담김.
//        // Vision 프레임워크에서는 이미지 대신 pixelBuffer를 바로 사용 가능
//        if let pixelBuffer = pixelBuffer {
//            // start of measure
//            self.👨‍🔧.🎬👏()
//            
//            // start predict
//            self.predictUsingVision(pixelBuffer: pixelBuffer)
//        }
//    }
//}

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
        guard let result = results.first else {
            showFailResult()
            return
        }
        
        showResults(objectLabel: result.identifier, confidence: result.confidence)
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
    
//    func showResults(objectLabel: String, confidence: VNConfidence) {
//        DispatchQueue.main.sync {
//            self.labelLabel.text = objectLabel
//            
//            self.confidenceLabel.text = "\(round(confidence * 100)) %"
//        }
//    }
    
    func showResults(objectLabel: String, confidence: VNConfidence) {
        DispatchQueue.main.sync {
            self.labelLabel.text = objectLabel
            self.confidenceLabel.text = "\(round(confidence * 100)) %"
            
            // Check if the object label has changed and if enough time has passed since the last speech
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(lastSpokenTime)
            
            if objectLabel != lastSpokenLabel && timeInterval > 1.0 { // Adjust time interval as needed (e.g., 1 second)
                // Update the last spoken label and time
                lastSpokenLabel = objectLabel
                lastSpokenTime = currentTime
                
                // Stop any ongoing speech synthesis
                if self.synthesizer.isSpeaking {
                    self.synthesizer.stopSpeaking(at: .immediate)
                }
                
                // Text-to-speech for object label
                let utterance = AVSpeechUtterance(string: objectLabel)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // Set the language
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate // Adjust the speech rate if needed
                
                // Speak the object label
                self.synthesizer.speak(utterance)
            }
        }
    }
    
}

// MARK: - 📏(Performance Measurement) Delegate
extension LiveImageViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        //print(executionTime, fps)
        self.inferenceLabel.text = "inference: \(Int(inferenceTime*1000.0)) mm"
        self.etimeLabel.text = "execution: \(Int(executionTime*1000.0)) mm"
        self.fpsLabel.text = "fps: \(fps)"
    }
}
