//
//  ChartSkirtView.swift
//  clearsenseminutes
//
//  Created by HWANJUN YU on 11/1/24.
//

import UIKit

class ChartSkirtView: UIView {
    
    var maxValue: Int = 0
    var data: [LineChartData] = []
    
    override func draw(_ rect: CGRect) {
        drawLine(rect)
        drawGradient(rect)
    }
    
    // 선 그리기
    private func drawLine(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        
        for (index, item) in data.enumerated() {
            let atom = rect.width / CGFloat(data.count)
            let xPoint = (atom * CGFloat(index + 1)) - (atom / 2)
            let yPoint = (Double(maxValue * 2) - (item.value + Double(maxValue))) * rect.height / Double(maxValue * 2)
            path.addLine(to: CGPoint(x: xPoint, y: yPoint))
        }
        
        path.lineWidth = 2.0
        UIColor.white.setStroke()
        path.stroke()
    }
    
    // 그라데이션 그리기
    private func drawGradient(_ rect: CGRect) {
        // 모양 잡기
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height / 2))
        
        for (index, item) in data.enumerated() {
            let atom = rect.width / CGFloat(data.count)
            let xPoint = (atom * CGFloat(index + 1)) - (atom / 2)
            let yPoint = (Double(maxValue * 2) - (item.value + Double(maxValue))) * rect.height / Double(maxValue * 2)
            path.addLine(to: CGPoint(x: xPoint, y: yPoint))
            
            // 마지막 점
            if index == data.count - 1 {
                path.addLine(to: CGPoint(x: xPoint, y: rect.height))
            }
        }
        
        // 그라데이션 채우기
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            path.addClip()  // 패스 내부에만 그라데이션이 적용되도록 클리핑
            
            // 그라데이션 생성
            let colors = [UIColor(hex: "#ADEEF9").cgColor,
                          UIColor(hex: "#B1F8EA", alpha: 0.0).cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colorLocations: [CGFloat] = [0.0, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations) {
                let startPoint = CGPoint(x: rect.midX, y: 0)
                let endPoint = CGPoint(x: rect.midX, y: rect.height)
                context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
            }
            context.restoreGState()
        }
    }
    
    // 그림 그리기 위한 데이터 세팅
    func setData(maxValue: Int = 0, data: [LineChartData]) {
        if maxValue > 0 {
            self.maxValue = maxValue
        }
        self.data = data
        
        self.setNeedsDisplay()
    }
}
