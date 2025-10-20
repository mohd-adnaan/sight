import UIKit
class DrawingSegmentationView: UIView {
    
    static private var colors: [Int32: UIColor] = [:]
    
    func segmentationColor(with index: Int32) -> UIColor {
        if let color = DrawingSegmentationView.colors[index] {
            return color
        } else {
            let color = UIColor(hue: CGFloat(index) / CGFloat(30), saturation: 1, brightness: 1, alpha: 0.5)
            print(index)
            DrawingSegmentationView.colors[index] = color
            return color
        }
    }
    var segmentationmap: SegmentationResultMLMultiArray? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.clear(rect);
            guard let segmentationmap = self.segmentationmap else { return }
            
            let size = self.bounds.size
            let segmentationmapWidthSize = segmentationmap.segmentationmapWidthSize
            let segmentationmapHeightSize = segmentationmap.segmentationmapHeightSize
            let w = size.width / CGFloat(segmentationmapWidthSize)
            let h = size.height / CGFloat(segmentationmapHeightSize)
            
            for j in 0..<segmentationmapHeightSize {
                for i in 0..<segmentationmapWidthSize {
                    let value = segmentationmap[j, i].int32Value

                    let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)

                    let color: UIColor = segmentationColor(with: value)

                    color.setFill()
                    UIRectFill(rect)
                }
            }
        }
    } // end of draw(rect:)

}

//Static Drawing - No use
//import UIKit
//
//class DrawingSegmentationView: UIView {
//
//    static private var colors: [Int32: UIColor] = [:]
//
//    func segmentationColor(with index: Int32) -> UIColor {
//        if let color = DrawingSegmentationView.colors[index] {
//            return color
//        } else {
//            let color = UIColor(hue: CGFloat(index) / CGFloat(30), saturation: 1, brightness: 1, alpha: 0.5)
//            DrawingSegmentationView.colors[index] = color
//            return color
//        }
//    }
//    
//    var segmentationmap: SegmentationResultMLMultiArray? = nil {
//        didSet {
//            self.setNeedsDisplay()
//        }
//    }
//    
//    override func draw(_ rect: CGRect) {
//        if let ctx = UIGraphicsGetCurrentContext() {
//            ctx.clear(rect)
//            guard let segmentationmap = self.segmentationmap else { return }
//            
//            let size = self.bounds.size
//            let segmentationmapWidthSize = segmentationmap.segmentationmapWidthSize
//            let segmentationmapHeightSize = segmentationmap.segmentationmapHeightSize
//            let w = size.width / CGFloat(segmentationmapWidthSize)
//            let h = size.height / CGFloat(segmentationmapHeightSize)
//            
//            // Draw the segmentation map
//            for j in 0..<segmentationmapHeightSize {
//                for i in 0..<segmentationmapWidthSize {
//                    let value = segmentationmap[j, i].int32Value
//                    let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)
//                    let color: UIColor = segmentationColor(with: value)
//                    color.setFill()
//                    UIRectFill(rect)
//                }
//            }
//            
//            // Draw the static navigation lines
//            drawStaticNavigationLines(ctx: ctx, in: size)
//        }
//    }
//    
//    func drawStaticNavigationLines(ctx: CGContext, in size: CGSize) {
//        // Set the line properties
//        ctx.setLineWidth(3.0)
//
//        // Draw green lines
//        ctx.setStrokeColor(UIColor.green.cgColor)
//        
//        ctx.beginPath()
//        ctx.move(to: CGPoint(x: size.width * 0.25, y: size.height))
//        ctx.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.5))
//        ctx.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.5))
//        ctx.addLine(to: CGPoint(x: size.width * 0.75, y: size.height))
//        ctx.strokePath()
//        
//        // Draw yellow lines
//        ctx.setStrokeColor(UIColor.yellow.cgColor)
//        
//        ctx.beginPath()
//        ctx.move(to: CGPoint(x: size.width * 0.15, y: size.height))
//        ctx.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.5))
//        ctx.move(to: CGPoint(x: size.width * 0.85, y: size.height))
//        ctx.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.5))
//        ctx.strokePath()
//    }
//}
