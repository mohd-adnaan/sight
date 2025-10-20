import UIKit
import Vision
import CoreMedia
import AVFoundation
import ARKit
import SceneKit

class ViewControllerRoom: UIViewController, AVSpeechSynthesizerDelegate {
    
    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var boxesView: DrawingBoundingBoxView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var freqLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    // Blue Bar to guide the user
    var blueBarView: UIView!
    
    // MARK - Core ML model
    lazy var objectDetectionModel = { return try? best() }()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var isInferencing = false
    
    // MARK: - AV Property
    var videoCapture: VideoCapture!
    let semaphore = DispatchSemaphore(value: 1)
    var lastExecution = Date()
    
    // MARK: - TableView Data
    var predictions: [VNRecognizedObjectObservation] = []
    
    // MARK - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    var prevXPos: CGFloat = 0.0
    var prevDistance: CGFloat = 0.0
    let distanceThreshold: CGFloat = 5.0 // Announce only when distance changes by 5 meters or more
    let xPosThreshold: CGFloat = 0.05    // Announce only when xPos changes more than this

    let speechSynthesizer = AVSpeechSynthesizer()
    var xCoordinateQueue: [CGFloat] = []
    var prevX = 0.0
    var sayDistance = 1
    var timeL = 0
    var numBoundingBox = 0
    var numNotFound = 0
    var speechQueue: [String] = []
    var isSpeechSynthesizing = false
    var shelterDetected = false
    var shelterDetectedFirst = false
    var speechString: String = ""
    var freq = 1.0
    var confidenceThreshold: Float = 0.65
    let maf1 = MovingAverageFilter()
    let maf2 = MovingAverageFilter()
    let maf3 = MovingAverageFilter()
    
    var audioPlayer: AVAudioPlayer?
    var hasBeeped: Bool = false

    var boundingBoxBuffer: [CGRect] = []
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the model
        setUpModel()
        
        // setup camera
        setUpCamera()
        
        // setup delegate for performance measurement
        👨‍🔧.delegate = self
        
        // Initialize the blue bar
        setUpBlueBar()
        
        // Setup the audio session
        setUpAudioSession()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        
        // Deactivate the audio session safely
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.isOtherAudioPlaying == false {
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
        
        // Stop any ongoing speech synthesis safely
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    
    @IBAction func sliderDidSlide(_ sender: UISlider) {
        let value = sender.value

        if value < 1 {
            freqLabel.text = "Less"
            self.freq = 0 // No announcements
        } else if value < 2 {
            freqLabel.text = "Norm"
            self.freq = 1 // Announce every time
        } else {
            freqLabel.text = "More"
            self.freq = 2 // Announce every two iterations
        }
    }

    
    @IBAction func thresholdsliderDidSlide(_ sender: UISlider) {
        let value = sender.value
        self.confidenceThreshold = value

        let formattedString = String(format: "%.f%%", value * 100)
        confidenceLabel.text = formattedString
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        guard let objectDetectionModel = objectDetectionModel else { fatalError("fail to load the model") }
        if let visionModel = try? VNCoreMLModel(for: objectDetectionModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("fail to create vision model")
        }
    }
    
    // MARK: - SetUp Video
//    func setUpCamera() {
//        videoCapture = VideoCapture()
//        videoCapture.delegate = self
//        videoCapture.fps = 20
//        videoCapture.setUp(sessionPreset: .vga640x480) { success in
//
//            if success {
//                // add preview view on the layer
//                if let previewLayer = self.videoCapture.previewLayer {
//                    self.videoPreview.layer.addSublayer(previewLayer)
//                    self.resizePreviewLayer()
//                }
//
//                // start video preview when setup is done
//                self.videoCapture.start()
//            }
//        }
//    }
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 20
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            if success {
                DispatchQueue.main.async {
                    if let previewLayer = self.videoCapture.previewLayer {
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
    
    // MARK: - Setup Audio Session
    func setUpAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SetUp Blue Bar
    func setUpBlueBar() {
        let barWidth: CGFloat = 50
        blueBarView = UIView(frame: CGRect(x: 0, y: 0, width: barWidth, height: videoPreview.bounds.height))
        blueBarView.backgroundColor = UIColor.blue.withAlphaComponent(0.5)
        blueBarView.layer.zPosition = 1 // Ensure it appears above other views
        videoPreview.addSubview(blueBarView)
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure the preview layer and blue bar are properly resized
        resizePreviewLayer()

        // Adjust the blue bar's height to match the videoPreview's height, but don't reset its center.
        if blueBarView != nil {
            blueBarView.frame.size.height = videoPreview.bounds.height
        } else {
            setUpBlueBar()
        }
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    func updateBlueBar(with position: CGFloat) {
        let maxWidth = videoPreview.bounds.width
        let targetX = position * maxWidth
        let currentX = blueBarView.center.x

        // Only update the blue bar's position if the change is significant to avoid jitter.
        if abs(currentX - targetX) > 5 { // You can adjust this threshold for smoothness
            DispatchQueue.main.async {
                self.blueBarView.center.x = targetX
            }
        }
    }
}

// MARK: - VideoCaptureDelegate
extension ViewControllerRoom: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // the captured image from camera is contained on pixelBuffer
        if !self.isInferencing, let pixelBuffer = pixelBuffer {
            self.isInferencing = true
            
            // start of measure
            self.👨‍🔧.🎬👏()
            
            // predict!
            DispatchQueue.global(qos: .userInitiated).async {
                self.predictUsingVision(pixelBuffer: pixelBuffer)
            }
        }
    }
}

extension ViewControllerRoom{
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        // vision framework configures the input size of image following our model's input configuration automatically
        self.semaphore.wait()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }

    // Method for speaking and providing haptic feedback concurrently
    func speakAndVibrateConcurrently() {
        let dispatchGroup = DispatchGroup()

        // Speech Task
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            self.speakString {
                dispatchGroup.leave()
            }
        }

        // Vibration Task
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            self.provideHapticFeedback()
            dispatchGroup.leave()
        }

      
    }

    func speakString(completion: @escaping () -> Void) {
        guard !speechSynthesizer.isSpeaking else {
            completion()
            return
        }

        let voice = AVSpeechSynthesisVoice(language: "en-GB")
        let speechUtterance = AVSpeechUtterance(string: self.speechString)
        speechUtterance.voice = voice
        speechUtterance.rate = 0.5 // Adjust rate for clarity
        
        // Use delegate to know when speech finishes
        self.speechSynthesizer.delegate = self
        self.speechSynthesizer.speak(speechUtterance)
        
        completion() // Call the completion handler immediately if you don't need to wait for speech to finish
    }

    func provideHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")

        if let predictions = request.results as? [VNRecognizedObjectObservation] {
            let filteredPredictions = predictions.filter { $0.labels.first?.identifier == "door" && $0.confidence >= self.confidenceThreshold }

            DispatchQueue.main.async {
                self.shelterDetected = !filteredPredictions.isEmpty
                self.boxesView.predictedObjects = filteredPredictions

                // Adjust the blue bar based on the first detected object
                if let firstPrediction = predictions.first {
                    let centerX = firstPrediction.boundingBox.midX
                    self.updateBlueBar(with: centerX)
                }
                
                // end of measure
                self.👨‍🔧.🎬🤚()
                self.isInferencing = false

                if self.shelterDetected {
                    self.numBoundingBox += 1
                    
                    // Reset `numNotFound` as object is detected
                    self.numNotFound = 0
                    
                    // If the shelter is detected for the first time
                    if !self.shelterDetectedFirst {
                        self.shelterDetectedFirst = true
                        self.numNotFound = 0 // Reset the 'not found' counter
                    }
                    
                    // Play beep sound only once when the shelter is first detected
                    if !self.hasBeeped {
                        self.playBeepSound()
                        self.hasBeeped = true
                    }
                    
                    if self.numBoundingBox == 1 || self.numBoundingBox % 15 == 0 {
                        let box = filteredPredictions[0].boundingBox
                        let xPos = (box.minX + box.maxX) / 2.0
                        let height = box.height
                        let distance = round(1 / height)
                        
                        self.updateBoundingBoxBuffer(with: box)
                        let average = self.calculateAverageBoundingBox()
                        
                        // Check if the change in xPos or distance is significant enough to make an announcement
                        let xPosChange = abs(xPos - self.prevXPos)
                        let distanceChange = abs(distance - self.prevDistance)

                        // Only announce if the distance has changed by 5 meters or more OR xPos has changed significantly
                        if xPosChange > self.xPosThreshold || distanceChange >= self.distanceThreshold {
                            self.prevXPos = xPos
                            self.prevDistance = distance
                            
                            // Determine clock direction based on xPos
                            switch xPos {
                            case 0..<0.2:
                                self.speechString = "10 o'clock, \(round(1/height)) meters"
                            case 0.2..<0.4:
                                self.speechString = "11 o'clock, \(round(1/height)) meters"
                            case 0.4..<0.6:
                                self.speechString = "12 o'clock, \(round(1/height)) meters"
                            case 0.6..<0.8:
                                self.speechString = "1 o'clock, \(round(1/height)) meters"
                            case 0.8...1.0:
                                self.speechString = "2 o'clock, \(round(1/height)) meters"
                            default:
                                self.speechString = ""
                            }
                            
                            // Log the xPos, direction, and distance for debugging
                            print("xPos: \(xPos), Direction: \(self.speechString), Distance: \(round(1/height)) meters")
                            
                            // Play success sound if distance is within 1 meters
                            if height >= 0.666 && height <= 1.0 {
                                self.playSuccess()
                            }
                            
                            if !self.speechString.isEmpty && self.shelterDetected {
                                self.speakAndVibrateConcurrently()
                            }
                            
                            if Int(self.freq) > 0 {
                                // Continue providing distance and direction information
                                if self.sayDistance >= Int(self.freq) {
                                    // Determine clock direction based on xPos
                                    switch xPos {
                                    case 0..<0.2:
                                        self.speechString = "10 o'clock, \(round(1/height)) meters"
                                    case 0.2..<0.4:
                                        self.speechString = "11 o'clock, \(round(1/height)) meters"
                                    case 0.4..<0.6:
                                        self.speechString = "12 o'clock, \(round(1/height)) meters"
                                    case 0.6..<0.8:
                                        self.speechString = "1 o'clock, \(round(1/height)) meters"
                                    case 0.8...1.0:
                                        self.speechString = "2 o'clock, \(round(1/height)) meters"
                                    default:
                                        self.speechString = ""
                                    }
                                    
                                    // Speak and vibrate
                                    if !self.speechString.isEmpty {
                                        self.speakAndVibrateConcurrently()
                                    }
                                    
                                    // Reset the counter after the announcement
                                    self.sayDistance = 0
                                } else {
                                    // Increment the counter
                                    self.sayDistance += 1
                                }
                            }
                        }
                    }
                }
                
                // If Room is no longer detected
                   if self.shelterDetectedFirst {
                       self.numNotFound += 1
                       if self.numNotFound >= 40 {
                           self.speechString = "Lost"
                           self.shelterDetectedFirst = false
                           self.numNotFound = 0
                           self.hasBeeped = false // Reset beep sound flag
                           self.speakAndVibrateConcurrently() // Ensure this method is called
                       }
                   }
                else {
                    self.numBoundingBox = 0
                }
            }
        }
    else {
            self.isInferencing = false
        }
        self.semaphore.signal()
    }


    func updateBoundingBoxBuffer(with newBox: CGRect) {
        boundingBoxBuffer.append(newBox)
        if boundingBoxBuffer.count > 4 {
            boundingBoxBuffer.removeFirst()
            boundingBoxBuffer.removeFirst()
            boundingBoxBuffer.removeFirst()
            boundingBoxBuffer.removeFirst()
        }
    }
    
    func playBeepSound() {
        guard let soundURL = Bundle.main.url(forResource: "beep-23", withExtension: "mp3") else {
            print("Beep sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch let error {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    func playTrackLostSound() {
        guard let soundURL = Bundle.main.url(forResource: "targetLost", withExtension: "wav") else {
            print("Target Lost sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch let error {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    func playSuccess() {
        guard let soundURL = Bundle.main.url(forResource: "success", withExtension: "mp3") else {
            print("Beep sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch let error {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    // Function to calculate average bounding box
    func calculateAverageBoundingBox() -> (avgX: CGFloat, avgHeight: CGFloat) {
            guard !boundingBoxBuffer.isEmpty else {
                return (0, 0)
            }

            let sum = boundingBoxBuffer.reduce((totalMiddleX: CGFloat(0), totalHeight: CGFloat(0))) { (currentSum, box) in
                let middleX = (box.minX + box.maxX) / 2.0 // Calculate middle X for each box
                let height = box.maxY - box.minY // Calculate height for each box
                return (currentSum.totalMiddleX + middleX, currentSum.totalHeight + height)
            }

            let count = CGFloat(boundingBoxBuffer.count)
            let avgMiddleX = sum.totalMiddleX / count // Average middle X
            let avgHeight = sum.totalHeight / count // Average height

            return (avgMiddleX, avgHeight)
    }
}

extension ViewControllerRoom: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell") else {
            return UITableViewCell()
        }
        
        let rectString = predictions[indexPath.row].boundingBox.toString(digit: 2)
        let confidence = predictions[indexPath.row].labels.first?.confidence ?? -1
        let confidenceString = String(format: "%.3f", confidence/*Math.sigmoid(confidence)*/)
        
        cell.textLabel?.text = predictions[indexPath.row].label ?? "N/A"
        cell.detailTextLabel?.text = "\(rectString), \(confidenceString)"
        return cell
    }
}

// MARK: - 📏(Performance Measurement) Delegate
extension ViewControllerRoom: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        DispatchQueue.main.async {
            self.maf1.append(element: Int(inferenceTime*1000.0))
            self.maf2.append(element: Int(executionTime*1000.0))
            self.maf3.append(element: fps)
            
            self.inferenceLabel.text = "inference: \(self.maf1.averageValue) ms"
            self.etimeLabel.text = "execution: \(self.maf2.averageValue) ms"
            self.fpsLabel.text = "fps: \(self.maf3.averageValue)"
        }
    }
}

class MovingAverageFilterRoom {
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
