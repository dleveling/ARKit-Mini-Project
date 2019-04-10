import UIKit

extension CALayer {

    func applySketchShadow(color: UIColor = .black,
                           alpha: Float = 1.0,
                           xOffset: CGFloat = 0,
                           yOffset: CGFloat = 0,
                           blur: CGFloat = 4,
                           spread: CGFloat = 0,
                           cornerRadius corner: CGFloat = 0) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: xOffset, height: yOffset)
        shadowRadius = blur / 2.0
        
        if spread == 0 {
            shadowPath = nil
        } else {
            let dxVal = -spread
            let rect = bounds.insetBy(dx: dxVal, dy: dxVal)
            var radius = cornerRadius
            
            if corner > 0 {
                radius = corner
            } else if let mask = mask {
                radius = mask.cornerRadius
            }

            shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        }
    }
    
}
