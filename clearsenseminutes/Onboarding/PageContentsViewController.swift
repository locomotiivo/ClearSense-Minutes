//
//  PageContentsViewController.swift
//  clearsenseminutes
//
//  Created by HYUNJUN SHIN on 8/28/24.
//

import UIKit


class PageContentsViewController: UIViewController {
    
    private var stackView: UIStackView!
    
    private var imageView = UIImageView()


    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupLayout()
    }
    
    init(imageName: String) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = UIImage(named: imageName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        imageView.contentMode = .scaleAspectFill
        
        self.stackView = UIStackView(arrangedSubviews: [imageView])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
    }
    
    private func setupLayout() {
        view.addSubview(stackView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // imageView 제약 조건 설정
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor,  multiplier: 0.9)
        ])
        
        // stackView 제약 조건 설정
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor),
            stackView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }

}
