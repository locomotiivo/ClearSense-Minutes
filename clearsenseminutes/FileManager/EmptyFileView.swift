//
//  EmptyFileView.swift
//  clearsenseminutes
//
//  Created by HYUNJUN SHIN on 8/30/24.
//

import UIKit

class EmptyFileView: UIView {
    
    private var stackView: UIStackView!
    private var imageView = UIImageView()
    private var messageLabel = UILabel()

    init(imageName: String, message: String) {
        super.init(frame: .zero)
        imageView.image = UIImage(systemName: imageName)
        messageLabel.text = message
        setupUI()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        imageView.contentMode = .scaleAspectFit
        
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .gray
        messageLabel.numberOfLines = 0
        
        stackView = UIStackView(arrangedSubviews: [imageView, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
    }
    
    private func setupLayout() {
        addSubview(stackView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // imageView 제약 조건 설정
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.1),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
        
        // stackView 제약 조건 설정
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8)
        ])
    }
}

