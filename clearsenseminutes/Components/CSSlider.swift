//
//  CSSlider.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/31/24.
//

import UIKit

@IBDesignable
class CSSlider: UISlider {
    
    @IBInspectable var thumbDiameter: CGFloat = 20
    @IBInspectable var trackHeight: CGFloat = 10
    
    var isChartSlider: Bool = false
    var startTrackingHandler: ((Int?) -> Void)?
    
    // MARK: - 초기화
    override init(frame: CGRect) {
        super.init(frame: frame)
        setDefaultThumbImage()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setDefaultThumbImage()
    }
    
    convenience init(trackHeight: CGFloat, thumbDiameter: CGFloat) {
        self.init(frame: .zero)
        self.trackHeight = trackHeight
        self.thumbDiameter = thumbDiameter
        setDefaultThumbImage()
    }
    
    // MARK: - Override
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.trackRect(forBounds: bounds)
        rect.size.height = trackHeight
        rect.origin.y -= trackHeight / 2
        return rect
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        isHighlighted = true
        if isChartSlider {
            trackHeight = 6
            startTrackingHandler?(self.tag)
            self.minimumTrackTintColor = UIColor(hex: "#5EECFF")
        }
        return super.beginTracking(touch, with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isHighlighted = false
        if isChartSlider {
            trackHeight = 2
            startTrackingHandler?(nil)
            self.minimumTrackTintColor = UIColor(hex: "#BDF5FF")
        }
        super.endTracking(touch, with: event)
    }
    
    // 터치 영역 thumb로 제한
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var thumbRect = thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
        
        if isChartSlider {
            let scale: CGFloat = 2.8
            let expansionWidth = thumbRect.width * (scale - 1) / 2
            let expansionHeight = thumbRect.height * (scale - 1) / 2
            thumbRect = thumbRect.insetBy(dx: -expansionWidth, dy: -expansionHeight)
        }
        
        return thumbRect.contains(point)
    }
    
    // MARK: - Function
    // Thumb 크기 변경
    private func setDefaultThumbImage() {
        let thumbSize = CGSize(width: thumbDiameter, height: thumbDiameter)
        let thumbColor = self.thumbTintColor ?? UIColor.white
        UIGraphicsBeginImageContextWithOptions(thumbSize, false, 0.0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(thumbColor.cgColor)
        context?.setStrokeColor(UIColor.clear.cgColor)
        context?.addEllipse(in: CGRect(origin: .zero, size: thumbSize))
        context?.drawPath(using: .fill)
        
        let thumbImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setThumbImage(thumbImage, for: .normal)
        self.setThumbImage(thumbImage, for: .highlighted)
    }
    
    // 차트에 쓸 슬라이더로 세팅
    func setChartSlider(startTracking: @escaping (Int?) -> Void) {
        isChartSlider = true
        startTrackingHandler = startTracking
        
        setDefaultThumbImage()
        
        // 하이라이트시 Thumb 변경
        let thumbSize = CGSize(width: 28, height: 28)
        let strokeWidth = 5.0
        UIGraphicsBeginImageContextWithOptions(thumbSize, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: thumbSize))
        context.setStrokeColor(UIColor(hex: "#5EECFF").cgColor)
        context.setLineWidth(strokeWidth)
        context.strokeEllipse(in: CGRect(origin: .zero, size: thumbSize).insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2))
        let circleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setThumbImage(circleImage, for: .highlighted)
    }
}
