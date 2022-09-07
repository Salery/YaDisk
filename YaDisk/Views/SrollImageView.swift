//
//  SrollImageView.swift
//  YaDisk
//
//  Created by Devel on 06.08.2022.
//

import UIKit

final class SrollImageView: UIScrollView {
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private lazy var dTapRecogniser: UITapGestureRecognizer = {
        let dTapRecogniser = UITapGestureRecognizer(target: self, action: #selector(imageViewDoubleClicked))
        dTapRecogniser.numberOfTapsRequired = 2
        return dTapRecogniser
    }()
    
    private var zoomed = false
    
    func setImage (_ image: UIImage?) {
        imageView.image = image
    }
    
    func setupImageView (gestureRecognizer: UIGestureRecognizer? = nil) {
        if let gestureRecognizer = gestureRecognizer {
            addGestureRecognizer(gestureRecognizer: gestureRecognizer)
        }
        zoomed = false
        setZoomScale(1, animated: true)
        setImageViewSize()
        setContentOffset()
    }
    
    convenience init () {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        config()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        config()
    }
    
    private func config () {
        showsVerticalScrollIndicator   = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        bounces     = false
        minimumZoomScale = 0.5
        maximumZoomScale = 100
        delegate = self
        addSubview(imageView)
        addGestureRecognizer(dTapRecogniser)
    }
    
    private func setImageViewSize () {
        guard let imSize = imageView.image?.size
        else { return }
        if frame.width > imSize.width
            && frame.height > imSize.height {
            imageView.frame.size = imSize
            return
        }
        let scale = imageScale(type: .min) ?? 0
        let imVWidth  = frame.width > imSize.width   * scale + 0.5 ?
                                imSize.width * scale  : frame.width
        let imVHeight = frame.height > imSize.height * scale + 0.5 ?
                                imSize.height * scale : frame.height
        imageView.frame.size = CGSize(width: imVWidth, height: imVHeight)
    }
    
    private func setContentOffset (manual: CGPoint? = nil) {
        if let manual = manual { contentOffset = manual; return }
        let imVSize = imageView.frame.size
        let x = frame.width  > imVSize.width ?
        (imVSize.width  - frame.width )/2 : zoomed ? contentOffset.x : 0
        let y = frame.height > imVSize.height ?
        (imVSize.height - frame.height)/2 : zoomed ? contentOffset.y : 0
        contentOffset = .init(x: x, y: y)
    }
    
    private func addGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        gestureRecognizer.require(toFail: dTapRecogniser)
        addGestureRecognizer(gestureRecognizer)
    }
    
    private enum scaleType {
        case max, min
    }
    private func imageScale (type: scaleType, ImView: Bool = false) -> CGFloat? {
        guard let iWidth    = ImView ? imageView.frame.width :
                                        imageView.image?.size.width,
              let iHeight   = ImView ? imageView.frame.height :
                                        imageView.image?.size.height
        else { return nil}
        let wScale = frame.width  / iWidth
        let hScale = frame.height / iHeight
        switch type {
        case .max: return max(wScale, hScale)
        case .min: return min(wScale, hScale)
        }
    }
    
    @objc private func imageViewDoubleClicked (_ gestureRecognizer: UIGestureRecognizer) {
        if zoomScale != 1 {
            setZoomScale(1, animated: true)
        } else {
            guard let minScale = imageScale(type: .max, ImView: true) else { return }
            setZoomScale(minScale, animated: true)
        }
        setContentOffset()
    }
}

extension SrollImageView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        zoomed = true
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setContentOffset()
    }
}
