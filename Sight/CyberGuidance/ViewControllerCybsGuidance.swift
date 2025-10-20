import UIKit
import SceneKit
import ARKit
import Photos
import CoreImage
import CoreVideo
import CoreGraphics
import AVFoundation
import CoreBluetooth
import AudioToolbox

class ViewControllerCybsGuidance: UIViewController, ARSCNViewDelegate, ARSessionDelegate, BluetoothManagerDelegate {
    
    enum TrackingState {
        case detection
        case tracking
        case stopped
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var trackingView: TrackingImageView!
    var foundBracelet: Bool = false
    
    // Load current image
    private var currentPixelBuffer: CVPixelBuffer?
    var focalLength: Float = 0.0
    
    // Retrieve selection from the FeatureSelection View
    var modelUsed: String = ""
    var verticalType: String = ""
    var holdingHand: String = ""
    var oralFeedbackEnabled: Bool = false
    var objectToDetect: String = ""
    var feedbackUsed: String = ""
    
    // Object detection parameters
    var callHandInterval: TimeInterval = 1.0
    var callHandIntervalIfDetected: TimeInterval = 0.2
    
    // Hand detection parameters
    var callObjectInterval: TimeInterval = 0.25
    
    // Retrieve the relation function's slopes values
    var verticalSlope = 1.0
    var depthSlope = 1.0
    
    // Distances computed
    var distanceTargetFromDimensions: Float = 0
    var distanceTargetFromAnchor: Float = 0
    var previousDistance: Float = 0
    var maxHeight: CGFloat = 0
    var maxWidth: CGFloat = 0
    
    // Audio Processor
    private var feedbackProcessor: FeedbackProcessor!
    var oralFeedbackTimer: Timer?
    
    // State tracking
    private var trackingState: TrackingState = .detection
    
    //Bluetooth manager
    var bluetoothManager: BluetoothManager!
    @IBOutlet weak var connectBracelet: UIButton!
    
    // Vision Processor
    private var workQueue = DispatchQueue(label: "com.frodes.app", qos: .userInitiated)
    private var objectDetectionQueue = DispatchQueue(label: "com.frodes.app.objdetection", qos: .userInitiated)
    private var handDetectionQueue = DispatchQueue(label: "com.frodes.app.handdetection", qos: .userInitiated)
    private var checkPositionQueue = DispatchQueue(label: "com.frodes.app.handdetection", qos: .userInitiated)
    private var updateBraceletStateQueue = DispatchQueue(label: "com.frodes.app.handdetection", qos: .userInitiated)
    
    private var visionProcessor: VisionTrackerProcessor!
    
    private var handPostion: CGPoint?
    private var isHandDetected: Bool = false
    private var detectedObject: VNDetectedObjectObservation?
    private var isObjectdetected: Bool = false
    private var targetClass: GroceryItem!
    private var handSize: CGFloat = 0
    private var objectToTrack: CGRect!
    private var objectBuffer = ObjectBuffer(maxSize: 10)
    private var targetLost: Bool = false
    private var playTargetLost: Bool = true
    
    private var targetPositionModel: CGPoint = CGPoint.zero
    private var targetPositionProjection: CGPoint = CGPoint.zero
    
    private var referencePoint: CGPoint = CGPoint.zero
    private var currentTargetHeight: CGFloat = 0
    private var currentTargetWidth: CGFloat = 0
    private var isDistanceShared: Bool = false
    
    var targetNode: SCNNode?
    var objectPosition: CGPoint = .zero
    var objectInView: Bool = false
    
    // Bluetooth connection
    var centralManager: CBCentralManager!
    var targetPeripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    var scanTimeoutTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        trackingView.addGestureRecognizer(tapGesture)
        
        // Add the double tap gesture recognizer
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        trackingView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        // Ensure single tap is recognized only if double tap fails
        tapGesture.require(toFail: doubleTapGestureRecognizer)
        
        sceneView.delegate = self
        sceneView.session.delegate = self // Set ARSessionDelegate
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Initialize the central manager for Bluetooth connection
        bluetoothManager = BluetoothManager()
        bluetoothManager.delegate = self
        
        connectBracelet.layer.borderWidth = 2.0
        connectBracelet.layer.borderColor = UIColor.red.cgColor
        connectBracelet.layer.cornerRadius = 10.0
        
        // Create and add the long press gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 1.0 // 1 second press
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Perform feedbackProcessor initialization
        initializeModules {
            // Once feedbackProcessor is initialized, start the ARSession
            DispatchQueue.main.async {
                self.startARSession()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Announce the instructions to the user
        // self.feedbackProcessor.playIndication(sentence: "When you feel vibrations or haptics, double tap on the screen to enable Navigation. LongPress to Restart")
        // Start object detection
        self.ObjectTracking()
        // Start hand detection
        self.HandTracking()
        // Start checking virtual object position
        self.checkPosition()
        // Start auditory feedback
        if feedbackUsed == "Sonification" {
            self.feedbackProcessor.startBips()
        } else if feedbackUsed == "Bracelet" {
            self.updateBraceletState()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func initializeModules(completion: @escaping () -> Void) {
        // Perform audioProcessor initialization here
        // This could involve synchronous or asynchronous tasks
        
        // FeedbackProcessor
        self.feedbackProcessor = FeedbackProcessor()
        feedbackProcessor.feedbackUsed = feedbackUsed
        feedbackProcessor.verticalType = verticalType
        feedbackProcessor.verticalSlope = verticalSlope
        feedbackProcessor.depthSlope = depthSlope
        feedbackProcessor.oralFeedbackEnabled = oralFeedbackEnabled
        
        // Vision tracker
        self.visionProcessor = VisionTrackerProcessor(modelType: modelUsed)
        self.visionProcessor.objectToDetect = self.objectToDetect
        
        // Call the completion handler when initialization is complete
        completion()
    }
    
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        
        // Share the distance from the object (existing functionality)
        if self.trackingState == .tracking {
            self.feedbackProcessor.indicateDistanceFromTarget(depth: self.distanceTargetFromDimensions)
        } else {
            if self.trackingView.targetPoint != CGPoint.zero {
                self.feedbackProcessor.indicateDirectionOrally()
            } else {
                self.feedbackProcessor.playIndication(sentence: "Keep searching")
            }
        }
        
    }
    
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        
        // Create the 3D virtual object
        let scaledTargetPoint: CGPoint = self.trackingView.targetPoint
        let numberOfNodes = self.sceneView.scene.rootNode.childNodes.count
        
        // Verify that scaledTargetPoint is different from CGPoint.zero
        if scaledTargetPoint != CGPoint.zero && numberOfNodes != 3 {
            if let spherePosition = calculate3DPosition(targetPoint: scaledTargetPoint, depth: self.distanceTargetFromDimensions) {
                
                // Assuming imageNode is your SCNNode
                let estimatedPosition = self.sceneView.projectPoint(spherePosition)
                let estimatedPostionPoint = CGPoint(x: CGFloat(estimatedPosition.x), y: CGFloat(estimatedPosition.y))
                
                 //Check the 2D projection accuracy
                 if abs(estimatedPostionPoint.x - scaledTargetPoint.x) < 10 && abs(estimatedPostionPoint.y - scaledTargetPoint.y) < 10 {
                     self.createSphereAtProjectedPoint(position3D: spherePosition)
                 } else {
                     self.feedbackProcessor.playIndication(sentence: "Try again - \(self.trackingView.indicationMessage)")
                 }
            }
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            print("Long press detected")
            
            self.feedbackProcessor.playIndication(sentence: "Resetting")
            //Reset the whole application
            self.reset()
        }
    }
    
    @IBAction func connectBraceletTap(_ sender: Any) {
        if self.feedbackUsed == "Bracelet" {
            print("Start connection to Bluetooth item")
            guard let button = sender as? UIButton else { return }
            // Change the border of the button when pressed
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.orange.cgColor
            button.setTitle("Searching...", for: .normal)
            
            bluetoothManager.startScanning()
        }
    }
    
    // MARK: - Bluetooth functions
    
    func bluetoothManager(_ manager: BluetoothManager, didUpdateValue value: Data) {
        // Handle received value from peripheral
    }
    
    func bluetoothManager(_ manager: BluetoothManager, didUpdateConnectionStatus isConnected: Bool) {
        DispatchQueue.main.async {
            if isConnected {
                self.connectBracelet.setTitle("Connected", for: .normal)
                self.connectBracelet.setTitleColor(.green, for: .normal)
                self.connectBracelet.layer.borderColor = UIColor.green.cgColor
            } else {
                self.connectBracelet.setTitle("Disconnected", for: .normal)
                self.connectBracelet.setTitleColor(.red, for: .normal)
                self.connectBracelet.layer.borderColor = UIColor.red.cgColor
            }
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, didDisconnectPeripheral peripheral: CBPeripheral) {
        // Handle disconnect, possibly attempt to reconnect
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        bluetoothManager.startScanning() // Attempt to reconnect
        
    }

    func bluetoothManager(_ manager: BluetoothManager, didEncounterError error: Error) {
        // Handle errors encountered during Bluetooth operations
        print("Bluetooth error: \(error.localizedDescription)")
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //Retrieve the current frame as a CVPixelBuffer variable
        let capturedImage = frame.capturedImage
        
        //Extract the current focal length of the camera for depth estimation
        self.focalLength = frame.camera.intrinsics[0,0]
        
        // Save the captured frame
        self.currentPixelBuffer = capturedImage
        
        self.visionProcessor.orientation = getCurrentDeviceOrientation()
        
        //Retrieve the frame dimensions
        let frameWidth = CVPixelBufferGetWidth(capturedImage)
        let frameHeight = CVPixelBufferGetHeight(capturedImage)
        
        //Take into account the rotation of the image
        self.trackingView.CVpixelSize = CGSize(width: frameHeight, height: frameWidth)
        
        self.feedbackProcessor.frameWidth = CGFloat(frameWidth)
        self.feedbackProcessor.frameHeight = CGFloat(frameHeight)
        
        if !self.feedbackProcessor.handDetected {
            self.referencePoint = CGPoint(x: self.trackingView.trackingRect.width / 2, y: self.trackingView.trackingRect.height / 2)
        }
        
        //If detected change the time interval between two requests
        if (trackingState == .tracking) {
            if isDistanceShared == false {
                self.feedbackProcessor.indicateDistanceFromTarget(depth: self.distanceTargetFromDimensions)
                isDistanceShared = true
            }
            
            workQueue.async {
                
                // Check if the image node exists
                guard let targetNode = self.targetNode else {
                    return
                }
                
                // Assuming imageNode is your SCNNode
                let estimatedPosition = self.sceneView.projectPoint(targetNode.worldPosition)
                self.targetPositionProjection = CGPoint(x: CGFloat(estimatedPosition.x), y: CGFloat(estimatedPosition.y))
                
                let previousState = self.objectInView
                
                self.objectInView = self.isPositionInsideBoundaries(position: self.targetPositionProjection, boundaries: self.trackingView.trackingRect)
                
                if self.objectInView == false && previousState == true {
                    //self.feedbackProcessor.playSound(audioPlayer: self.audioProcessor.targetLostAudioPlayer)
                    self.feedbackProcessor.indicateDirectionAfterLost()
                } else {
                    if let targetNode = self.targetNode {
                        //Get the 3D world position of the targetNode
                        let objectPosition = targetNode.worldPosition
                        
                        //Compute the distance from the object
                        if let distanceProjection = self.computeDistance(objectPosition: objectPosition, targetPoint: self.targetPositionProjection, previousDistance: self.distanceTargetFromAnchor) {
                            // The value is not nil, assign it to self.currentTargetHeight
                            self.distanceTargetFromAnchor = distanceProjection
                            
                        } else {
                            // The value is nil and not saved
                            print("Distance wasn't computed correctly")
                        }

                    } else {
                        print("Target node is nil")
                    }
                }
                
                self.trackingView.targetPoint = self.targetPositionProjection
                
                
                Thread.sleep(forTimeInterval: 0.2)
            }
            
        } else if (trackingState == .detection) {
            
            if self.targetPositionModel != CGPoint.zero {
                
                let scaledTargetPoint = self.trackingView.scale(cornerPoint: self.targetPositionModel)
                self.trackingView.targetPoint = scaledTargetPoint
                
                let numberOfNodes = self.sceneView.scene.rootNode.childNodes.count
                if numberOfNodes == 3 {
                    self.feedbackProcessor.foundTarget = true
                    self.objectInView = true
                    self.trackingState = .tracking
                    
                    //Prepare other modules to tracking session
                    self.feedbackProcessor.targetHeight = self.currentTargetHeight
                    self.feedbackProcessor.updateParameters(referencePoint: self.referencePoint, objectLocation: self.trackingView.targetPoint, depth: self.distanceTargetFromAnchor)
                }
            }
        }
        
        self.displayFrame(self.trackingView.targetPoint)
    }
    
    func getCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .up
        }
        
        let interfaceOrientation = windowScene.interfaceOrientation
        
        switch interfaceOrientation {
        case .portrait:
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .upMirrored
        case .landscapeRight:
            return .downMirrored
        default:
            return .up
        }
    }
    
    func HandTracking(){
        //Run a hand detection every 1 second to detect if the user want to change mode
        handDetectionQueue.async {
            while true {
                if let frame = self.currentPixelBuffer {
                    do {
                        
                        (self.handPostion, self.feedbackProcessor.handDetected, self.handSize) = try self.visionProcessor.detectHand(image: frame, imageWidth: CGFloat(CVPixelBufferGetWidth(frame)), imageHeight: CGFloat(CVPixelBufferGetHeight(frame)))
                        
                        //If the algorithm detected an object, proceed:
                        if let handPostion = self.handPostion {
                            
                            self.isHandDetected = self.feedbackProcessor.handDetected
                            
                            //Indicate that the hand is detect, and the reference point is the index tip
                            if self.callHandInterval == 1.0 {
                                self.feedbackProcessor.playIndication(sentence: "Hand")
                            }
                            self.callHandInterval = self.callHandIntervalIfDetected
                            
                            let handX = handPostion.x
                            let handY = handPostion.y
                            
                            self.trackingView.handPoint = CGPoint(x: handX, y: handY)
                            self.referencePoint = self.trackingView.scale(cornerPoint: self.trackingView.handPoint)
                            if self.handSize > self.feedbackProcessor.maxHandSize {
                                self.feedbackProcessor.maxHandSize = self.handSize
                            }
                            self.feedbackProcessor.handSize = self.handSize
                        } else {
                            //Indicate that the reference point become the frame's center
                            if self.callHandInterval == self.callHandIntervalIfDetected {
                                self.feedbackProcessor.playIndication(sentence: "Frame")
                            }
                            
                            self.callHandInterval = 1.0
                            self.trackingView.handPoint = CGPoint.zero
                            self.isHandDetected = false
                        }
                        
                    } catch {
                        print("Wrong hand detection")
                    }
                } else {
                    print("Frame couldn't be retrieved")
                }
                
                Thread.sleep(forTimeInterval: self.callHandInterval)
            }
        }
    }
    
    func ObjectTracking(){
        //Run an object detection every 1 second to detect if the user want to change mode
        objectDetectionQueue.async {
            while true {
                if let frame = self.currentPixelBuffer {
                    do {
                        
                        self.detectedObject = try self.visionProcessor.detectObject(image: frame, minimumConfidence: 0.3)
                                                
                        //If the algorithm detected an object, proceed:
                        if let detectedObject = self.detectedObject {
                            
                            if self.trackingState == .detection {
                                self.feedbackProcessor.triggerHapticFeedback()
                            }
                            
                            self.isObjectdetected = true
                                
                            // Calculate the center of the bounding box
                            let centerX = 1 - (detectedObject.boundingBox.origin.x + detectedObject.boundingBox.size.width / 2)
                            let centerY = 1 - (detectedObject.boundingBox.origin.y + detectedObject.boundingBox.size.height / 2)
                            
                            self.currentTargetHeight = detectedObject.boundingBox.size.height
                            self.currentTargetWidth = detectedObject.boundingBox.size.width
                            
                            (self.trackingView.targetWidth, self.trackingView.targetHeight) = self.trackingView.scaleRect(width: self.currentTargetWidth, height: self.currentTargetHeight)
                            
                            self.feedbackProcessor.targetHeight = self.trackingView.targetHeight
                            self.feedbackProcessor.targetWidth = self.trackingView.targetWidth
                            
                            self.extractClass(observationDescription: detectedObject.description)
                            
                            // Set the center point on your tracking view`
                            self.targetPositionModel = CGPoint(x: centerX, y: centerY)
                            
                            //Create a 3D object in the Wolrd coordinate at the location of physical detected object
                            if self.currentTargetHeight > self.currentTargetWidth {
                                self.distanceTargetFromDimensions = (Float(self.focalLength + 100) * self.targetClass.height) / (Float(self.currentTargetHeight) * Float(CVPixelBufferGetWidth(frame)))
                            } else {
                                self.distanceTargetFromDimensions = (Float(self.focalLength + 100) * self.targetClass.height) / (Float(self.currentTargetWidth) * Float(CVPixelBufferGetHeight(frame)))
                            }
                        } else {
                            self.targetPositionModel = CGPoint.zero
                            self.trackingView.targetPoint = CGPoint.zero
                            self.isObjectdetected = false
                        }
                        
                    } catch {
                        // Handle error
                    }
                } else {
                    print("Frame couldn't be retrieved")
                }
                
                Thread.sleep(forTimeInterval: self.callObjectInterval)
            }
        }
    }
    
    func checkPosition(){
        //Run a position verification of the virtual object
        checkPositionQueue.async {
            while true {
                if let frame = self.currentPixelBuffer, let current3DPosition = self.targetNode?.position {
                    
                    if self.targetPositionModel != CGPoint.zero && self.trackingState == .tracking {
                        
                        //Compute current distance
                        var newDistanceFromDimensions: Float = 0
                        let targetHeightInPixels = Float(self.currentTargetHeight) * Float(CVPixelBufferGetWidth(frame))
                        let targetWidthInPixels = Float(self.currentTargetWidth) * Float(CVPixelBufferGetHeight(frame))
                        
                        if  targetHeightInPixels > targetWidthInPixels {
                            newDistanceFromDimensions = (Float(self.focalLength + 100) * self.targetClass.height) / targetHeightInPixels
                        } else {
                            newDistanceFromDimensions = (Float(self.focalLength + 100) * self.targetClass.height) / targetWidthInPixels
                        }
                        
                        let currentHeight = self.currentTargetHeight
                        let currentWidth = self.currentTargetWidth
                        let heightChange = self.maxHeight - currentHeight
                        let widthChange = self.maxWidth - currentWidth
                        
                        // If the current 3D virtual object is not centered or not at the right depth, we move it at the right position
                        let scaledTargetPositionModel = self.trackingView.scale(cornerPoint: self.targetPositionModel)
                        
                        let distX = abs(self.targetPositionProjection.x - scaledTargetPositionModel.x)
                        let distY = abs(self.targetPositionProjection.y - scaledTargetPositionModel.y)
                        let depthDiff = abs(newDistanceFromDimensions - self.previousDistance)
                        
                        let dist = self.computeL2Distance(horizontalDist: distX, verticalDist: distY)
                        let maxDist = self.computeL2Distance(horizontalDist: self.trackingView.targetWidth/2, verticalDist: self.trackingView.targetHeight/2)
                        
                        let correctionRange: ClosedRange<CGFloat> = 10.0...maxDist
                        
                        // Declare newPosition outside of the if-else block
                        var newPosition: SCNVector3?
                        
                        //Check if the detected position is in the correction range and if the distance needs to be updated
                        
                        if (correctionRange.contains(dist) && (widthChange < 0 && heightChange < 0)) {
                            
                            if let distanceAnchor = self.computeDistance(objectPosition: current3DPosition, targetPoint: self.targetPositionProjection, previousDistance: self.previousDistance) {
                                newPosition = self.calculate3DPosition(targetPoint: scaledTargetPositionModel, depth: distanceAnchor)
                                print("Change position - position, distance Anchor: \(distanceAnchor), with previous distance: \(self.previousDistance)")
                            } else {
                                newPosition = nil
                            }
                            
                        } else if (depthDiff > 0.01 && correctionRange.contains(dist) && (widthChange < 0 && heightChange < 0)) {
                            print("Change position - distance")
                            newPosition = self.calculate3DPosition(targetPoint: scaledTargetPositionModel, depth: newDistanceFromDimensions)
                        }
                        
                        // Assuming imageNode is your SCNNode
                        if let estimatedPosition = newPosition {
                            let projectedPosition = self.sceneView.projectPoint(estimatedPosition)
                            let projectedPositionPoint = CGPoint(x: CGFloat(projectedPosition.x), y: CGFloat(projectedPosition.y))
                            // Use projectedPosition as needed
                            
                            //Check if the 2D projection of the object is the same as the object detection coordinates
                            if abs(projectedPositionPoint.x - scaledTargetPositionModel.x) < 10 || abs(projectedPositionPoint.y - scaledTargetPositionModel.y) < 10 {

                                let distanceUpdate = self.computeDistanceBetween3DPoints(point1: current3DPosition, point2: estimatedPosition)
                                
                                print("3D position updated, distance between updated points: \(distanceUpdate)")
                                print("Update at \(newDistanceFromDimensions) meters from the user")
                                self.targetNode?.position = estimatedPosition
                            }
                        }
                        
                        self.previousDistance = newDistanceFromDimensions
                        if widthChange < 0 {
                            self.maxWidth = currentWidth
                        }
                        if heightChange < 0 {
                            self.maxHeight = currentHeight
                        }
                    }
                }
                
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    func updateBraceletState(){
        //Update the state of the bracelet to stimulate depending on the object position
        updateBraceletStateQueue.async {
            while true {
                let state = self.feedbackProcessor.braceletState
                var final_state: String = ""
                
                if state != "" && self.trackingState == .tracking {
                    let interBipTime = self.feedbackProcessor.interBipTime
                    
                    // Convert seconds to milliseconds and round to the nearest integer
                    let interBipTimeInMilliseconds = Int(interBipTime * 1000)
                    
                    //If the hand is not detected and the hand holding the phone is left, perform a 90 degrees rotation
                    if !self.isHandDetected && self.holdingHand == "Left" {
                        final_state = self.updateState(state: state, holdingHand: "Left")
                    } else if !self.isHandDetected && self.holdingHand == "Right" {
                        final_state = self.updateState(state: state, holdingHand: "Right")
                    } else {
                        final_state = state
                    }

                    // Create a formatted string with state and interBipTime separated by a dash
                    let formattedString = "\(final_state)-\(interBipTimeInMilliseconds)"

                    print("Formatted String: \(formattedString)")
                    self.bluetoothManager.writeValue(value: formattedString)
                }
            
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    func updateState(state: String, holdingHand: String) -> String {
        // Convert the state to an integer
        guard let stateInt = Int(state), stateInt >= 1, stateInt <= 8 else {
            return state // Return the original state if it's invalid
        }
        
        var newStateInt: Int
        
        if holdingHand == "Left" {
            // Apply the transformation for the "Left" direction
            switch stateInt {
            case 1: newStateInt = 3
            case 2: newStateInt = 4
            case 3: newStateInt = 5
            case 4: newStateInt = 6
            case 5: newStateInt = 7
            case 6: newStateInt = 8
            case 7: newStateInt = 1
            case 8: newStateInt = 2
            default: return state // This should not be reached
            }
        } else if holdingHand == "Right" {
            // Apply the transformation for the "Right" direction
            switch stateInt {
            case 1: newStateInt = 7
            case 2: newStateInt = 8
            case 3: newStateInt = 1
            case 4: newStateInt = 2
            case 5: newStateInt = 3
            case 6: newStateInt = 4
            case 7: newStateInt = 5
            case 8: newStateInt = 6
            default: return state // This should not be reached
            }
        } else {
            return state // Return the original state if the direction is invalid
        }
        
        // Convert the new state back to a string and return it
        return String(newStateInt)
    }
    
    func computeL2Distance(horizontalDist: CGFloat, verticalDist: CGFloat) -> CGFloat {
        let verticalDistSquared = verticalDist * verticalDist
        let horizontalDistSquared = horizontalDist * horizontalDist
        let sumOfSquares = verticalDistSquared + horizontalDistSquared
        return sqrt(sumOfSquares)
    }
    
    func createSphereAtProjectedPoint(position3D: SCNVector3?) {
        
        if let spherePosition = position3D {
            
            //Create a sphere geometry
            let sphereGeometry = SCNSphere(radius: 0.01) // Adjust the radius as needed

            // Create a material for the sphere
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor.red // Adjust the color as needed

            // Apply the material to the sphere
            sphereGeometry.materials = [sphereMaterial]

            // Create a node for the sphere
            let sphereNode = SCNNode(geometry: sphereGeometry)
            
            // Position the sphere node
            sphereNode.position = spherePosition
            
            //Name the virtual object to be trackable
            sphereNode.name = "targetSphere"
            
            self.targetNode = sphereNode
            
            if let targetNode = self.targetNode {
                self.sceneView.scene.rootNode.addChildNode(targetNode)
            }
            
        } else {
            print("Failed to calculate 3D position")
        }
    }
    
    func calculate3DPosition(targetPoint: CGPoint, depth: Float) -> SCNVector3? {
        // Convert the 2D point to a 3D point on a plane
        let planePoint = SCNVector3(Float(targetPoint.x), Float(targetPoint.y), 0.0)
        let projectedPoint = sceneView.unprojectPoint(planePoint)
        
        guard let currentFrame = sceneView.session.currentFrame else {
            return nil
        }
        
        let cameraTransform = currentFrame.camera.transform
        let cameraPosition = SCNVector3(cameraTransform.columns.3.x,
                                        cameraTransform.columns.3.y,
                                        cameraTransform.columns.3.z)
        
        // Calculate the direction vector
        let direction = SCNVector3(projectedPoint.x - cameraPosition.x,
                                   projectedPoint.y - cameraPosition.y,
                                   projectedPoint.z - cameraPosition.z)
        let normalizedDirection = normalizeDirection(direction)
        
        // Calculate the position for the sphere along the direction with the given depth
        let spherePosition = SCNVector3(cameraPosition.x + normalizedDirection.x * depth,
                                        cameraPosition.y + normalizedDirection.y * depth,
                                        cameraPosition.z + normalizedDirection.z * depth)
        
        return spherePosition
    }
    
    func computeDistance(objectPosition: SCNVector3, targetPoint: CGPoint, previousDistance: Float) -> Float? {
        // Convert the 2D point to a 3D point on a plane
        let planePoint = SCNVector3(Float(targetPoint.x), Float(targetPoint.y), 0.0)
        let projectedPoint = sceneView.unprojectPoint(planePoint)
        
        guard let currentFrame = sceneView.session.currentFrame else {
            return nil
        }
        
        let cameraTransform = currentFrame.camera.transform
        let cameraPosition = SCNVector3(cameraTransform.columns.3.x,
                                        cameraTransform.columns.3.y,
                                        cameraTransform.columns.3.z)
        
        // Calculate the direction vector
        let direction = SCNVector3(projectedPoint.x - cameraPosition.x,
                                   projectedPoint.y - cameraPosition.y,
                                   projectedPoint.z - cameraPosition.z)
        let normalizedDirection = normalizeDirection(direction)
        
        // Calculate the position for the object along the direction
        let objectToCamera = SCNVector3(objectPosition.x - cameraPosition.x,
                                         objectPosition.y - cameraPosition.y,
                                         objectPosition.z - cameraPosition.z)
        
        // Calculate the dot product between the direction vector and the vector from camera to object
        let dotProduct = objectToCamera.x * normalizedDirection.x +
                         objectToCamera.y * normalizedDirection.y +
                         objectToCamera.z * normalizedDirection.z
        
        // Calculate the distance from camera to the object along the direction
        var distance = dotProduct / (normalizedDirection.x * normalizedDirection.x +
                                     normalizedDirection.y * normalizedDirection.y +
                                     normalizedDirection.z * normalizedDirection.z)
        
        //Check if the computed distance make sense
        //Filter negative values and one with a difference greater than 10 centimers with the previous computed distance
        
        if previousDistance != 0.0 && (distance < 0 || (distance - previousDistance) > 0.2) {
            distance = previousDistance
        }
        
        return distance
    }
    
    // Function to compute the L2 distance between two SCNVector3 points
    func computeDistanceBetween3DPoints(point1: SCNVector3, point2: SCNVector3) -> Float {
        // Calculate the differences
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        let dz = point1.z - point2.z
        
        // Compute and return the L2 distance
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    func normalizeDirection(_ vector: SCNVector3) -> SCNVector3 {
        // Calculate the magnitude of the vector
        let magnitude = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        // Normalize each component of the vector
        let normalizedX = vector.x / magnitude
        let normalizedY = vector.y / magnitude
        let normalizedZ = vector.z / magnitude
        
        // Return the normalized vector
        return SCNVector3(x: normalizedX, y: normalizedY, z: normalizedZ)
    }
    
    func isPositionInsideBoundaries(position: CGPoint, boundaries: CGRect) -> Bool {
        return boundaries.contains(position)
    }
    
    func extractClass(observationDescription: String) {
        
        // Search for the line containing the labels
        if let labelsRange = observationDescription.range(of: "labels=") {
            // Extract the substring starting from the labels
            let labelsSubstring = observationDescription[labelsRange.upperBound...]
            
            // Search for the end of the labels section
            if let endIndex = labelsSubstring.firstIndex(of: "]") {
                // Extract the labels substring until the end of the labels section
                let labelsString = labelsSubstring[..<endIndex]
                
                // Split the labelsString by comma to get individual labels
                let labels = labelsString.components(separatedBy: ",")
                
                // Trim whitespace and brackets from each label
                let trimmedLabels = labels.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "") }
                
                // Take the first label from the list if available
                if let firstLabel = trimmedLabels.first {
                    self.targetClass = GroceryItem(name: firstLabel)
                    return // Return early after printing the first label
                }
            }
        }
        
        // Print an error message if labels couldn't be extracted or no labels were found
        print("Error: Unable to extract the first label from the object or no labels found.")
    }
    
    // MARK: - Reset the application
    func reset() {
        
        // State tracking
        self.trackingState = .detection
        
        self.feedbackProcessor.resetAudio()
        self.trackingView.resetTracking()
        
        //Global reset
        self.distanceTargetFromDimensions = 0
        self.distanceTargetFromAnchor = 0
        
        self.isHandDetected = false
        self.handSize = 0
        self.objectBuffer.clearBuffer()
        self.targetLost = false
        self.playTargetLost = true
        
        self.targetPositionModel = CGPoint.zero
        self.targetPositionProjection = CGPoint.zero
        self.detectedObject = nil
        
        self.referencePoint = CGPoint.zero
        self.currentTargetHeight = 0
        self.currentTargetWidth = 0
        self.isDistanceShared = false
        
        self.objectPosition = .zero
        self.objectInView = false
        
        if let sphereNode = self.sceneView.scene.rootNode.childNode(withName: "targetSphere", recursively: true) {
            sphereNode.removeFromParentNode()
            print("Suppress the sphere")
        }
    }
    
}
    
extension ViewControllerCybsGuidance: VisionTrackerProcessorDelegate {
    func displayFrame(_ targetPoint: CGPoint?) {
        DispatchQueue.main.async {
            guard let frame = self.currentPixelBuffer, let targetPoint = targetPoint else {
                return
            }
            
            // Send current frame to TrackingView
            let ciImage = CIImage(cvPixelBuffer: frame)
            let uiImage = UIImage(ciImage: ciImage)
            self.trackingView.image = uiImage
            
            //Scale the point to
            self.trackingView.targetPoint = targetPoint
                        
            // Calculate frame center and update the audio parameters
            self.feedbackProcessor.updateParameters(referencePoint: self.referencePoint, objectLocation: targetPoint, depth: self.distanceTargetFromAnchor)
            if self.targetLost == false {
                self.trackingView.indicationMessage = self.feedbackProcessor.assistUser(referencePoint: self.referencePoint, objectLocation: CGPoint(x: targetPoint.x, y: targetPoint.y))
            }

            self.trackingView.rubberbandingStart = CGPoint.zero
            self.trackingView.rubberbandingVector = CGPoint.zero
    
            self.trackingView.setNeedsDisplay()
        }
    }
}

