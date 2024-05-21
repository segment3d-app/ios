//
//  DotOverlay.swift
//  MetalSplatter SampleApp
//
//  Created by I Made Indra Mahaarta on 22/05/24.
//

import UIKit

class DotOverlay: UIView {
    private var dotCenter: CGPoint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDot(at point: CGPoint) {
        self.dotCenter = point
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let dotCenter = dotCenter else { return }
        context.setFillColor(UIColor.red.cgColor)
        let dotRadius: CGFloat = 100.0
        let dotRect = CGRect(x: dotCenter.x - dotRadius, y: dotCenter.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
        context.fillEllipse(in: dotRect)
    }
}
