//
//  FeatureSelectionViewController.swift
//  CybGuidance
//
//  Created by Nicolas Albert on 10.05.2024.
//

import UIKit
import AVFoundation
import Vision

class FeatureSelectionViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    
    //Create an instance of all the objects present of the View
    @IBOutlet weak var QRCode: UIButton!
    var QRCodeEnabled: Bool = false
    @IBOutlet weak var Groceries: UIButton!
    var GroceriesEnabled: Bool = true
    
    @IBOutlet weak var item1: UIButton!
    var item1Enabled = true
    @IBOutlet weak var item2: UIButton!
    var item2Enabled = false
    @IBOutlet weak var item3: UIButton!
    var item3Enabled = false
    
    @IBOutlet weak var Sonification: UIButton!
    var SonificationEnabled: Bool = true
    @IBOutlet weak var Bracelet: UIButton!
    var BraceletEnabled: Bool = false
    
    @IBOutlet weak var LeftHand: UIButton!
    var LeftHandEnabled: Bool = true
    @IBOutlet weak var RightHand: UIButton!
    var RightHandEnabled: Bool = false
    
    @IBOutlet weak var VerticalSteps: UIButton!
    var VerticalStepsEnabled: Bool = true
    @IBOutlet weak var VerticalParabol: UIButton!
    var VerticalParabolEnabled: Bool = false
    @IBOutlet weak var VerticalCubic: UIButton!
    var VerticalCubicEnabled: Bool = false
    
    
    @IBOutlet weak var VerticalSlider: UISlider!
    @IBOutlet weak var VerticalMinValue: UILabel!
    @IBOutlet weak var VerticalMaxValue: UILabel!
    @IBOutlet weak var VerticalFunction: UITextField!
    
    @IBOutlet weak var DepthSlider: UISlider!
    @IBOutlet weak var DepthMinValue: UILabel!
    @IBOutlet weak var DepthMaxValue: UILabel!
    @IBOutlet weak var DepthFunction: UITextField!
    
    @IBOutlet weak var OralFeedback: UISwitch!
    
    @IBOutlet weak var ValidateButton: UIButton!
    
    //Function
    
    @IBAction func QRCodeTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (QRCodeEnabled, GroceriesEnabled) = changeSelection(buttonPressed: button, otherButton: Groceries)
    }
    @IBAction func GroceriesTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (GroceriesEnabled, QRCodeEnabled) = changeSelection(buttonPressed: button, otherButton: QRCode)
    }
    
    @IBAction func item1Tap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (item1Enabled, item2Enabled, item3Enabled) =  changeSelection3(buttonPressed: button, otherButton1: item2, otherButton2: item3)
    }
    @IBAction func item2Tap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (item2Enabled, item1Enabled, item3Enabled) =  changeSelection3(buttonPressed: button, otherButton1: item1, otherButton2: item3)
    }
    @IBAction func item3Tap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (item3Enabled, item1Enabled, item2Enabled) =  changeSelection3(buttonPressed: button, otherButton1: item1, otherButton2: item2)
    }
    
    
    @IBAction func SonificationTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (SonificationEnabled, BraceletEnabled) = changeSelection(buttonPressed: button, otherButton: Bracelet)
    }
    @IBAction func BraceletTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (BraceletEnabled, SonificationEnabled) = changeSelection(buttonPressed: button, otherButton: Sonification)
    }
    
    @IBAction func LeftHandTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (LeftHandEnabled, RightHandEnabled) = changeSelection(buttonPressed: button, otherButton: RightHand)
    }
    
    @IBAction func RightHandTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (RightHandEnabled, LeftHandEnabled) = changeSelection(buttonPressed: button, otherButton: LeftHand)
    }
    
    @IBAction func VerticalStepsTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (VerticalStepsEnabled, VerticalParabolEnabled, VerticalCubicEnabled) =  changeSelection3(buttonPressed: button, otherButton1: VerticalParabol, otherButton2: VerticalCubic)
    }
    @IBAction func VerticalParabolTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (VerticalParabolEnabled, VerticalStepsEnabled, VerticalCubicEnabled) =  changeSelection3(buttonPressed: button, otherButton1: VerticalSteps, otherButton2: VerticalCubic)
    }
    @IBAction func VerticalCubicTap(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        (VerticalCubicEnabled, VerticalStepsEnabled, VerticalParabolEnabled) =  changeSelection3(buttonPressed: button, otherButton1: VerticalSteps, otherButton2: VerticalParabol)
    }
    
    @IBAction func ValidateTap(_ sender: Any) {
        print("Selection validated")
        // Initiate the capture session from the camera after the feature selection
        performSegue(withIdentifier: "StartCapturing", sender: self)
    }
    
    private func changeSelection(buttonPressed: UIButton, otherButton: UIButton) -> (Bool, Bool) {
        var buttonEnabled: Bool = false
        var otherButtonEnabled: Bool = false
        if buttonPressed.layer.borderColor == UIColor.red.cgColor {
            buttonPressed.layer.borderColor = UIColor.green.cgColor
            otherButton.layer.borderColor = UIColor.red.cgColor
        }
        
        buttonEnabled = true
        otherButtonEnabled = false
        
        return (buttonEnabled, otherButtonEnabled)
    }
    
    private func changeSelection3(buttonPressed: UIButton, otherButton1: UIButton, otherButton2: UIButton) -> (Bool, Bool, Bool) {
        var buttonEnabled: Bool = false
        var otherButton1Enabled: Bool = false
        var otherButton2Enabled: Bool = false
        if buttonPressed.layer.borderColor == UIColor.red.cgColor {
            buttonPressed.layer.borderColor = UIColor.green.cgColor
            otherButton1.layer.borderColor = UIColor.red.cgColor
            otherButton2.layer.borderColor = UIColor.red.cgColor
        }
        
        buttonEnabled = true
        otherButton1Enabled = false
        otherButton2Enabled = false
        
        return (buttonEnabled, otherButton1Enabled, otherButton2Enabled)
    }
    
    private func setupUI() {
        // Set border color and width for QRCode button
        QRCode.layer.borderColor = UIColor.red.cgColor
        QRCode.layer.borderWidth = 2
        
        // Set border color and width for Groceries button
        Groceries.layer.borderColor = UIColor.green.cgColor
        Groceries.layer.borderWidth = 2
        
        // Set border color and width for item1 button
        item1.layer.borderColor = UIColor.green.cgColor
        item1.layer.borderWidth = 2
        // Set border color and width for item2 button
        item2.layer.borderColor = UIColor.red.cgColor
        item2.layer.borderWidth = 2
        // Set border color and width for item3 button
        item3.layer.borderColor = UIColor.red.cgColor
        item3.layer.borderWidth = 2
        
        // Set border color and width for Sonification button
        Sonification.layer.borderColor = UIColor.green.cgColor
        Sonification.layer.borderWidth = 2
        
        // Set border color and width for Bracelet button
        Bracelet.layer.borderColor = UIColor.red.cgColor
        Bracelet.layer.borderWidth = 2
        
        // Set border color and width for VerticalSteps button
        VerticalSteps.layer.borderColor = UIColor.green.cgColor
        VerticalSteps.layer.borderWidth = 2
        
        // Set border color and width for VerticalAffine button
        VerticalParabol.layer.borderColor = UIColor.red.cgColor
        VerticalParabol.layer.borderWidth = 2
        
        // Set border color and width for VerticalAffine button
        VerticalCubic.layer.borderColor = UIColor.red.cgColor
        VerticalCubic.layer.borderWidth = 2
        
        // Set border color and width for VerticalPitch button
        LeftHand.layer.borderColor = UIColor.green.cgColor
        LeftHand.layer.borderWidth = 2
        
        // Set border color and width for VerticalVolume button
        RightHand.layer.borderColor = UIColor.red.cgColor
        RightHand.layer.borderWidth = 2
        
        // Set minimum and maximum values for VerticalSlider
        VerticalSlider.minimumValue = 0.0
        VerticalMinValue.text = "\(0)"
        VerticalSlider.maximumValue = 2.0
        VerticalMaxValue.text = "\(2)"
        VerticalSlider.setValue(1.0, animated: false)
        VerticalFunction.text = "1.0"
        
        // Set minimum and maximum values for DepthSlider
        DepthSlider.minimumValue = 0.0
        DepthMinValue.text = "\(0)"
        DepthSlider.maximumValue = 5.0
        DepthMaxValue.text = "\(5)"
        DepthSlider.setValue(1.0, animated: false)
        DepthFunction.text = "1.0"
        
        // Set up event handling for sliders
        VerticalSlider.addTarget(self, action: #selector(verticalSliderValueChanged(_:)), for: .valueChanged)
        DepthSlider.addTarget(self, action: #selector(depthSliderValueChanged(_:)), for: .valueChanged)
    }
    
    @objc func verticalSliderValueChanged(_ sender: UISlider) {
        // Update the value of VerticalFunction text field
        VerticalFunction.text = "\(sender.value)"
    }

    @objc func depthSliderValueChanged(_ sender: UISlider) {
        // Update the value of HorizontalFunction text field
        DepthFunction.text = "\(sender.value)"
    }
    
    // Override prepare(for:sender:) method to pass variables
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartCapturing" {
            
            // Access the destination view controller
            if let destinationVC = segue.destination as? ViewControllerCybsGuidance {
                // Set the variables of the destination view controller
                if QRCodeEnabled == true && GroceriesEnabled == false {
                    destinationVC.modelUsed = "QRCode"
                    destinationVC.objectToDetect = "QR_CODE"
                } else if QRCodeEnabled == false && GroceriesEnabled == true {
                    destinationVC.modelUsed = "Groceries"
                    
                    if item1Enabled == true && item2Enabled == false && item3Enabled == false {
                        destinationVC.objectToDetect = "bottle"
                    } else if item1Enabled == false && item2Enabled == true && item3Enabled == false {
                        destinationVC.objectToDetect = "banana"
                    } else if item1Enabled == false && item2Enabled == false && item3Enabled == true {
                        destinationVC.objectToDetect = "orange"
                    } else {
                        print("Invalid selection")
                    }
                    
                } else {
                    print("Invalid selection")
                }
                
                if VerticalStepsEnabled == true && VerticalParabolEnabled == false && VerticalCubicEnabled == false {
                    destinationVC.verticalType = "Steps"
                } else if VerticalStepsEnabled == false && VerticalParabolEnabled == true && VerticalCubicEnabled == false {
                    destinationVC.verticalType = "Parabol"
                } else if VerticalStepsEnabled == false && VerticalParabolEnabled == false && VerticalCubicEnabled == true {
                    destinationVC.verticalType = "Cubic"
                } else {
                    print("Invalid selection")
                }
                
                if LeftHandEnabled == true && RightHandEnabled == false {
                    destinationVC.holdingHand = "Left"
                } else if LeftHandEnabled == false && RightHandEnabled == true{
                    destinationVC.holdingHand = "Right"
                } else {
                    print("Invalid selection")
                }
                
                destinationVC.oralFeedbackEnabled = OralFeedback.isOn
                
                if SonificationEnabled == true && BraceletEnabled == false {
                    destinationVC.feedbackUsed = "Sonification"
                } else if SonificationEnabled == false && BraceletEnabled == true{
                    destinationVC.feedbackUsed = "Bracelet"
                } else {
                    print("Invalid selection")
                }
                
                destinationVC.verticalSlope = Double(VerticalSlider.value)
                destinationVC.depthSlope = Double(DepthSlider.value)
            }
        }
    }
}

extension FeatureSelectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard when return key is pressed
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, let value = Float(text) {
            if textField == VerticalFunction {
                // Check if value is within the range of VerticalSlider
                let clampedValue = min(max(value, VerticalSlider.minimumValue), VerticalSlider.maximumValue)
                // Set the value of VerticalSlider
                VerticalSlider.value = clampedValue
                // Update the text field with clamped value
                textField.text = "\(clampedValue)"
            } else if textField == DepthFunction {
                // Check if value is within the range of DepthSlider
                let clampedValue = min(max(value, DepthSlider.minimumValue), DepthSlider.maximumValue)
                // Set the value of DepthSlider
                DepthSlider.value = clampedValue
                // Update the text field with clamped value
                textField.text = "\(clampedValue)"
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Hide the keyboard when user taps outside of the text field
        self.view.endEditing(true)
    }
}
