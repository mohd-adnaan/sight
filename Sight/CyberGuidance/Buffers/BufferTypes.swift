//
//  BufferTypes.swift
//  CybGuidance
//
//  Created by Nicolas Albert on 08.05.2024.
//

import Foundation
import UIKit

class ObjectBuffer {
    private var buffer: [CGPoint] = []
    var maxSize: Int
    
    init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    func addToBuffer(object: CGPoint) {
        buffer.append(object)
        if buffer.count > maxSize {
            buffer.removeFirst(buffer.count - maxSize)
        }
    }
    
    func clearBuffer() {
        buffer.removeAll()
    }
    
    var count: Int {
        return buffer.count
    }
}

struct Position {
    let x: Float
    let y: Float
    // Add any additional properties you need
}

class PositionBuffer {
    let maxSize: Int
    private var positions: [Position] = []
    private var index = 0
    
    init(maxSize: Int) {
        self.maxSize = maxSize
        self.positions.reserveCapacity(maxSize)
    }
    
    func addPosition(_ position: Position) {
        if positions.count < maxSize {
            positions.append(position)
        } else {
            positions[index] = position
            index = (index + 1) % maxSize // Circular buffer logic
        }
    }
    
    func getAllPositions() -> [Position] {
        return positions
    }
    
    func getLastPosition() -> Position? {
        return positions.last
    }
    
    func clear() {
        positions.removeAll()
    }
    
    func estimateStandardDeviation() -> (x: Float, y: Float)? {
        guard !positions.isEmpty else { return nil }
        
        // Calculate the mean of x and y coordinates
        let meanX = positions.reduce(0.0) { $0 + $1.x } / Float(positions.count)
        let meanY = positions.reduce(0.0) { $0 + $1.y } / Float(positions.count)
        
        // Calculate the sum of squares of differences from the mean
        let sumX = positions.reduce(0.0) { $0 + pow($1.x - meanX, 2) }
        let sumY = positions.reduce(0.0) { $0 + pow($1.y - meanY, 2) }
        
        // Calculate the standard deviation
        let stdDevX = sqrt(sumX / Float(positions.count))
        let stdDevY = sqrt(sumY / Float(positions.count))
        
        return (stdDevX, stdDevY)
    }
}



