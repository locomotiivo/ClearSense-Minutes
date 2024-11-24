//
//  CSLineChart.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 10/31/24.
//

import UIKit

struct LineChartData {
    var label: Int = 0
    var value: Double = 0
    
    init(label: Int, value: Double) {
        self.label = label
        self.value = value
    }
}

protocol CSLineChartDelegate {
    func didBeginAdjusting(_ value: LineChartData) // 슬라이더 조절 시작 호출
    func onChangeValue(_ values: [LineChartData]) // 슬라이더 조절 중간에 호출
}

class CSLineChart: UIView {
    
    @IBOutlet weak var bgView: UIView!
    
    @IBOutlet weak var yMaxLabel: UILabel!
    @IBOutlet weak var yMidLabel: UILabel!
    @IBOutlet weak var yMinLabel: UILabel!
    
    @IBOutlet weak var xAxisStackView: UIStackView!
    
    @IBOutlet weak var skirtView: ChartSkirtView!
    @IBOutlet weak var sliderStackView: UIStackView!
    
    @IBInspectable var isMiniMode: Bool = false // 미니모드 여부
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var leftWidth: NSLayoutConstraint!
    
    @IBInspectable var useControl: Bool = true // 슬라이더 조작 가능 여부
    
    let gradientLayer = CAGradientLayer() // 배경 그라데이션 레이어
    
    var delegate: CSLineChartDelegate?
    var data: [LineChartData] = []
    var selectIndex: Int = -1 {
        didSet {
            setSelectUI()
        }
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async { [weak self] in
            self?.gradientLayer.frame = self?.bgView.bounds ?? CGRect.zero
        }
    }
    
    // 초기화
    private func commonInit() {
        if let view = Bundle.main.loadNibNamed("CSLineChart", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
        }
        
        // 백그라운드 그라데이션
        gradientLayer.colors = [
            UIColor(hex: "#299CE8", alpha: 0.5).cgColor,
            UIColor(hex: "#90DEEA", alpha: 0.5).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        for sublayer in bgView.layer.sublayers ?? [] {
            sublayer.removeFromSuperlayer()
        }
        bgView.layer.addSublayer(gradientLayer)
    }
    
    // MARK: - UI
    // 데이터로 UI 세팅
    private func updateUI() {
        // 미니모드 레이아웃 세팅
        if isMiniMode {
            leftWidth.constant = 22
            rightMargin.constant = 0
        }
        
        // Y축 세팅
        var maxValue = data.map({ $0.value }).max()
        maxValue = (maxValue ?? 0 < 30) ? 30 : maxValue
        let ceilValue = Int(ceil((maxValue ?? 0) / 10) * 10)
        yMinLabel.text = isMiniMode ? "\(-ceilValue)" : "\(-ceilValue)dB"
        yMidLabel.text = isMiniMode ? "0" : "0dB"
        yMaxLabel.text = isMiniMode ? "dB\n\(ceilValue)" : "\(ceilValue)dB"
        
        // X축 라벨 세팅
        for subview in xAxisStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for (index, item) in data.enumerated() {
            var isVisible = true
            if isMiniMode, index != 0 && index != (Int(floor(Double(data.count) / 2.0)) - 1) && index != data.count - 1 {
                isVisible = false // 미니모드일 때는 일부만 보여줌
            }
            
            let xLabel = UILabel()
            xLabel.tag = item.label
            xLabel.font = UIFont(name: "PretendardGOVVariable-SemiBold", size: 12)
            xLabel.textColor = .white
            xLabel.textAlignment = .center
            xLabel.text = isVisible ? Utils.convertHz(item.label) : ""
            xLabel.adjustsFontSizeToFitWidth = true // 텍스트 크기 조정
            xLabel.minimumScaleFactor = 0.5 // 최소 크기 설정
            xAxisStackView.addArrangedSubview(xLabel)
        }
        
        skirtView.setData(maxValue: ceilValue, data: data)
        
        // 차트 슬라이더 세팅
        for subview in sliderStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for item in data {
            let slider = CSChartSlider(trackHeight: 2, thumbDiameter: 10)
            slider.tag = item.label
            slider.maximumValue = Float(ceilValue)
            slider.minimumValue = -Float(ceilValue)
            slider.value = Float(item.value)
            slider.minimumTrackTintColor = UIColor(hex: "#BDF5FF")
            slider.maximumTrackTintColor = .clear
            slider.thumbTintColor = .white
            slider.isUserInteractionEnabled = useControl
            slider.addTarget(self, action: #selector(onChangeSlider), for: .valueChanged)
            slider.setChartSlider() { [weak self] tag in
                guard let self = self, let selectData = data.first(where: { $0.label == tag }) else { return }
                
                delegate?.didBeginAdjusting(selectData)
                selectIndex = data.firstIndex(where: { $0.label == selectData.label}) ?? -1
                setSelectUI()
            }
            sliderStackView.addArrangedSubview(slider)
        }
        sliderStackView.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
    }
    
    // 선택된 슬라이더 UI 하이라이트
    private func setSelectUI() {
        guard useControl == true else { return }
        
        // 슬라이더 하이라이트
        for (index, slider) in sliderStackView.arrangedSubviews.enumerated() {
            if let cssSlider = slider as? CSChartSlider {
                cssSlider.isSelect = index == selectIndex
            }
        }
        
        // 선택된 데이터 X축 라벨 색 변경
        for subview in xAxisStackView.arrangedSubviews {
            guard let label = subview as? UILabel else { continue }
            
            if selectIndex >= 0, data.count > selectIndex {
                label.textColor = label.tag == Int(data[selectIndex].label) ? UIColor(hex: "#BDF5FF") : .white
            } else {
                label.textColor = .white
            }
        }
    }
    
    // MARK: - Function
    // 데이터 세팅
    func setData(_ data: [LineChartData], selectIdx: Int? = nil) {
        self.data = data
        updateUI()
        selectIndex = selectIdx ?? Int(floor(Double(data.count) / 2.0))
    }
    
    @objc func onChangeSlider(_ sender: CSChartSlider) {
        // Slider 조정값 Data에 세팅
        if let index = data.firstIndex(where: { $0.label == sender.tag }) {
            data[index].value = Double(sender.value)
        }
        
        skirtView.setData(data: data)
        delegate?.onChangeValue(data) // VC에도 알림
    }
}
