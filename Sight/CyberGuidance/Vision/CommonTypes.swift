//
//  CommonTypes.swift
//  CybGuidance
//
//  Created by Nicolas Albert on 08.05.2024.
//

import Foundation
import UIKit
import Vision

struct GroceryItem {
    let name: String
    
    // Computed property to calculate height based on item name
    var height: Float {
        switch name {
        case "cell phone":
            return 0.16
        case "bottle":
            return 0.30
        case "cup":
            return 0.10
        case "deo":
            return 0.14
        case "tv":
            return 0.33
        case "banana":
            return 0.21
        case "orange":
            return 0.095
        case "QR_CODE":
            return 0.12
        default:
            return 0.0 // Default height if item name is not recognized
        }
    }
}
