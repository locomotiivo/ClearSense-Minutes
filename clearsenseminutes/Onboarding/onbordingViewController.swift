//
//  onbordingViewController.swift
//  clearsenseminutes
//
//  Created by HYUNJUN SHIN on 8/28/24.
//

import UIKit


class OnboardingViewController: UIPageViewController {
    
    private var skipButton: UIButton!
    
    private var pages = [UIViewController]()
    private var initialPage = 0
    
    private var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPage()
        setupUI()
        setupLayout()
    }
    
    private func setupPage() {
        
        let page1 = PageContentsViewController(imageName: "ONBOARDING_LANGUAGE1".localized())
        let page2 = PageContentsViewController(imageName: "ONBOARDING_LANGUAGE2".localized())
        let page3 = PageContentsViewController(imageName: "ONBOARDING_LANGUAGE3".localized())
        let page4 = PageContentsViewController(imageName: "ONBOARDING_LANGUAGE4".localized())
        
        pages.append(page1)
        pages.append(page2)
        pages.append(page3)
        pages.append(page4)
    }
    
    private func setupUI() {
        
        // 버튼 UI 설정
        skipButton = UIButton()
        skipButton.setTitle("SKIP".localized(), for: .normal)
        skipButton.setTitleColor(.systemBlue, for: .normal)
        skipButton.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
        
        self.dataSource = self
        // UIPageViewController에서 처음 보여질 뷰컨트롤러 설정 (첫 번째 page)
        self.setViewControllers([pages[initialPage]], direction: .forward, animated: true)
    }
    
    
    @objc func buttonHandler(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "onBoarding")
        dismiss(animated: true)
    }
    
    private func setupLayout() {
        view.addSubview(skipButton)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        
        // skipButton 제약 조건 설정
        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
}

// MARK: - DataSource

extension OnboardingViewController: UIPageViewControllerDataSource {
    // 이전 뷰컨트롤러를 리턴
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // 현재 VC의 인덱스를 구합니다.
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        guard currentIndex > 0 else { return nil }
        return pages[currentIndex - 1]
    }
    
    // 다음 보여질 뷰컨트롤러를 리턴
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        guard currentIndex < (pages.count - 1) else { return nil}
        
        return pages[currentIndex + 1]
    }
    
    
    // 인디케이터(pageControl)의 총 개수
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    // 인디케이터(pageControl)에 반영할 값 (pageControl.currentPage라고 생각하면 된다)
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let viewController = pageViewController.viewControllers?.first,
              let currentIndex = pages.firstIndex(of: viewController) else { return 0 }
        
        return currentIndex
    }
}
