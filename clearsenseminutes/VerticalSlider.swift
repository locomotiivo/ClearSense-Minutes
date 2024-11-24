
import UIKit

@IBDesignable open class VerticalSlider: UIView {
    
    public let slider = UISlider()
    
    // required for IBDesignable class to properly render
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    // required for IBDesignable class to properly render
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }

    fileprivate func initialize() {
        updateSlider()
        addSubview(slider)
    }
    
    fileprivate func updateSlider() {
        if !ascending {
            slider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi) * -0.5)
        } else {
            slider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi) * 0.5).scaledBy(x: 1, y: -1)
        }
        
        slider.minimumValue = minimumValue
        slider.maximumValue = maximumValue
        slider.value = value
        slider.setThumbImage(thumbImage, for: .normal)
        slider.setMinimumTrackImage(minimumTrackImage, for: .normal)
        slider.setMaximumTrackImage(maximumTrackImage, for: .normal)
        slider.isContinuous = isContinuous
    }
    
    @IBInspectable open var ascending: Bool = false {
        didSet {
            updateSlider()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        slider.bounds.size.width = bounds.height
        slider.center.x = bounds.midX
        slider.center.y = bounds.midY
    }
    
    override open var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: slider.intrinsicContentSize.height, height: slider.intrinsicContentSize.width)
        }
    }
    
    @IBInspectable open var minimumValue: Float = -1 {
        didSet {
            updateSlider()
        }
    }
    
    @IBInspectable open var maximumValue: Float = 1 {
        didSet {
            updateSlider()
        }
    }
    
    @IBInspectable open var value: Float {
        get {
            return slider.value
        }
        set {
            slider.setValue(newValue, animated: true)
        }
    }
    
    @IBInspectable open var thumbImage: UIImage? {
        didSet {
            updateSlider()
        }
    }
    
    @IBInspectable open var minimumTrackImage: UIImage? {
        didSet {
            updateSlider()
        }
    }
    
    @IBInspectable open var maximumTrackImage: UIImage? {
        didSet {
            updateSlider()
        }
    }
    
    @IBInspectable open var isContinuous: Bool = true {
        didSet {
            updateSlider()
        }
    }
}
