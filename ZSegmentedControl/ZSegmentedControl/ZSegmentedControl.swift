//
//  ZSegmentedControl.swift
//  ZSegmentedControl
//
//  Created by mengqingzheng on 2017/12/6.
//  Copyright © 2017年 MQZHot. All rights reserved.
//

import UIKit
enum ResourceType {
    case text
    case image
    case hybrid
}
enum HybridStyle {
    case normalWithSpace(CGFloat)
    case imageRightWithSpace(CGFloat)
    case imageTopWithSpace(CGFloat)
    case imageBottomWithSpace(CGFloat)
}
enum SliderStyle {
    case coverUpDowmSpace(CGFloat)
    case bottomWithHight(CGFloat)
    case topWidthHeight(CGFloat)
    case none
}
/// 点击
protocol ZSegmentedControlSelectedProtocol {
    func segmentedControlSelectedIndex(_ index: Int, animated: Bool, segmentedControl: ZSegmentedControl)
}
class ZSegmentedControl: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContentView()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupContentView()
    }
    func setTitles(_ titles: [String], fixedWidth: CGFloat) {
        resourceType = .text
        titleSources = titles
        totalItemsCount = titles.count
        setupItems(fixedWidth: fixedWidth)
    }
    func setTitles(_ titles: [String], adaptiveLeading: CGFloat) {
        resourceType = .text
        titleSources = titles
        totalItemsCount = titles.count
        setupItems(fixedWidth: 0, leading: adaptiveLeading)
    }
    func setImages(_ images: [UIImage], selectedImages: [UIImage?]? = nil, fixedWidth: CGFloat) {
        resourceType = .image
        imageSources = (images, selectedImages)
        totalItemsCount = images.count
        setupItems(fixedWidth: fixedWidth)
    }
    func setHybridResource(_ titles: [String?], images: [UIImage?], selectedImages: [UIImage?]? = nil, style: HybridStyle = .normalWithSpace(0), fixedWidth: CGFloat) {
        resourceType = .hybrid
        hybridSources = (titles, images, selectedImages)
        totalItemsCount = max(titles.count, images.count)
        setupItems(fixedWidth: fixedWidth)
    }
    
    /// public
    var bounces: Bool = false {
        didSet { subScrollView.bounces = bounces }
    }
    var textColor: UIColor = UIColor.gray {
        didSet {
            itemsArray.forEach { $0.setTitleColor(textColor, for: .normal) }
        }
    }
    var textSelectedColor: UIColor = UIColor.blue {
        didSet {
            selectedItemsArray.forEach { $0.setTitleColor(textSelectedColor, for: .normal) }
        }
    }
    var textFont: UIFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            itemsArray.forEach { $0.titleLabel?.font = textFont }
            selectedItemsArray.forEach { $0.titleLabel?.font = textFont }
        }
    }
    
    /// cover
    func setCover(color: UIColor, upDowmSpace: CGFloat = 0, cornerRadius: CGFloat = 0) {
        coverView.layer.cornerRadius = cornerRadius
        coverView.backgroundColor = color
        coverUpDownSpace = upDowmSpace
        fixCoverFrame(originFrame: coverView.frame, upSpace: upDowmSpace)
    }
    
    
    var tackingScale: CGFloat = 0 {
        didSet { updateTackingOffset() }
    }
    
    var selectedIndex: Int = 0 {
        didSet { updateScrollViewOffset() }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateScrollViewOffset()
    }
    var delegate: ZSegmentedControlSelectedProtocol?
    
    /// private
    fileprivate var scrollView = UIScrollView()
    fileprivate var subScrollView = UIScrollView()
    fileprivate var itemsArray = [UIButton]()
    fileprivate var selectedItemsArray = [UIButton]()
    fileprivate var coverView = UIView()
    fileprivate var coverViewMask = UIView()
    fileprivate var slider = UIView()
    fileprivate var totalItemsCount: Int = 0
    fileprivate var titleSources = [String]()
    fileprivate var imageSources: ([UIImage], [UIImage?]?) = ([], nil)
    fileprivate var hybridSources: ([String?], [UIImage?], [UIImage?]?) = ([], [], nil)
    fileprivate var resourceType: ResourceType = .text
    fileprivate var isTapItem: Bool = false
    fileprivate var coverUpDownSpace: CGFloat = 0
    
    fileprivate func setupContentView() {
        backgroundColor = UIColor.white
        scrollView.frame = bounds
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        addSubview(scrollView)
        
        subScrollView.frame = bounds
        subScrollView.delegate = self
        subScrollView.showsHorizontalScrollIndicator = false
        subScrollView.bounces = false
        addSubview(subScrollView)
        
        subScrollView.addSubview(coverView)
        coverViewMask.backgroundColor = UIColor.white
        subScrollView.layer.mask = coverViewMask.layer
//        subScrollView.isHidden = true
        scrollView.addSubview(slider)
    }
    
    fileprivate func setupItems(fixedWidth: CGFloat, leading: CGFloat? = nil) {
        itemsArray.forEach { $0.removeFromSuperview() }
        itemsArray.removeAll()
        selectedItemsArray.forEach { $0.removeFromSuperview() }
        selectedItemsArray.removeAll()
        var contentSizeWidth: CGFloat = 0
        for i in 0..<totalItemsCount {
            var width = fixedWidth
            if let leading = leading {
                let text = titleSources[i] as NSString
                width = text.size(withAttributes: [.font: textFont]).width + leading*2
            }
            let x = contentSizeWidth
            let height = frame.size.height
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: x, y: 0, width: width, height: height)
            button.clipsToBounds = true
            scrollView.addSubview(button)
            itemsArray.append(button)
            
            let selectedButton = UIButton(type: .custom)
            selectedButton.tag = i
            selectedButton.frame = button.frame
            selectedButton.addTarget(self, action: #selector(selectedButton(sender:)), for: .touchUpInside)
            subScrollView.addSubview(selectedButton)
            selectedItemsArray.append(selectedButton)
            
            switch resourceType {
            case .text:
                button.setTitle(titleSources[i], for: .normal)
                button.setTitleColor(textColor, for: .normal)
                button.titleLabel?.font = textFont
                selectedButton.setTitle(titleSources[i], for: .normal)
                selectedButton.setTitleColor(textSelectedColor, for: .normal)
                selectedButton.titleLabel?.font = textFont
            case .image:
                var selectedImage = imageSources.0[i]
                let selectedImages = imageSources.1 == nil ? imageSources.0 : imageSources.1!
                if i < selectedImages.count && selectedImages[i] != nil {
                    selectedImage = selectedImages[i]!
                }
                button.setImage(imageSources.0[i], for: .normal)
                selectedButton.setImage(selectedImage, for: .normal)
            case .hybrid:
                button.setTitleColor(textColor, for: .normal)
                button.titleLabel?.font = textFont
                selectedButton.setTitleColor(textSelectedColor, for: .normal)
                selectedButton.titleLabel?.font = textFont
                
                let titles = hybridSources.0
                if i < titles.count, let title = titles[i] {
                    button.setTitle(title, for: .normal)
                    selectedButton.setTitle(title, for: .normal)
                }
                
                let images = hybridSources.1
                if i < images.count, let image = images[i] {
                    var selectedImage = image
                    let selectedImages = hybridSources.2 == nil ? images : hybridSources.2!
                    if i < selectedImages.count && selectedImages[i] != nil {
                        selectedImage = selectedImages[i]!
                    }
                    button.setImage(image, for: .normal)
                    selectedButton.setImage(selectedImage, for: .normal)
                }
            }
            contentSizeWidth += width
        }
        scrollView.contentSize = CGSize(width: contentSizeWidth, height: 0)
        subScrollView.contentSize = CGSize(width: contentSizeWidth, height: 0)
        let index = min(max(selectedIndex, 0), selectedItemsArray.count)
        let button = selectedItemsArray[index]
        fixCoverFrame(originFrame: button.frame, upSpace: coverUpDownSpace)
        subScrollView.contentOffset = getScrollViewCorrectOffset(by: button)
    }
    @objc private func selectedButton(sender: UIButton) {
        isTapItem = true
        selectedIndex = sender.tag
    }
}
extension ZSegmentedControl {
    fileprivate func updateScrollViewOffset() {
        if selectedItemsArray.count == 0 { return }
        let index = min(max(selectedIndex, 0), selectedItemsArray.count)
        delegate?.segmentedControlSelectedIndex(index, animated: isTapItem, segmentedControl: self)
        let button = selectedItemsArray[index]
        let offset = getScrollViewCorrectOffset(by: button)
        UIView.animate(withDuration: 0.3, animations: {
            self.fixCoverFrame(originFrame: button.frame, upSpace: self.coverUpDownSpace)
        }) { _ in
            self.subScrollView.setContentOffset(offset, animated: true)
            self.isTapItem = false
        }
    }
    
    fileprivate func getScrollViewCorrectOffset(by item: UIButton) -> CGPoint {
        var offsetx = item.center.x - frame.size.width/2
        let offsetMax = subScrollView.contentSize.width - frame.size.width
        if offsetx < 0 {
            offsetx = 0
        }else if offsetx > offsetMax {
            offsetx = offsetMax
        }
        let offset = CGPoint(x: offsetx, y: 0)
        return offset
    }
    
    fileprivate func updateTackingOffset() {
        if isTapItem { return }
        let percent = tackingScale-CGFloat(selectedIndex)
        var targetIndex = selectedIndex
        if percent < 0 {
            targetIndex = selectedIndex-1
        } else if percent > 0 {
            targetIndex = selectedIndex+1
        }
        if targetIndex < 0 || targetIndex > selectedItemsArray.count-1 { return }
        let button = selectedItemsArray[selectedIndex]
        let targetButton = selectedItemsArray[targetIndex]
        let centerXChange = (targetButton.center.x-button.center.x)*abs(percent)
        let widthChange = (targetButton.frame.size.width-button.frame.size.width)*abs(percent)
        var frame = button.frame
        frame.size.width += widthChange
        var center = button.center
        center.x += centerXChange
        fixCoverFrame(originFrame: frame, upSpace: coverUpDownSpace)
        coverView.center = center
        coverViewMask.frame = coverView.frame
        var sliderCenter = slider.center
        sliderCenter.x = center.x
        slider.center = sliderCenter
    }
    
    fileprivate func fixCoverFrame(originFrame: CGRect, upSpace: CGFloat) {
        var newFrame = originFrame
        newFrame.origin.y = upSpace
        newFrame.size.height -= upSpace*2
        coverView.frame = newFrame
        coverViewMask.frame = coverView.frame
        newFrame.origin.y = originFrame.size.height-2
        newFrame.size.height = 2
        slider.frame = newFrame
        slider.backgroundColor = UIColor.red
    }
}
/// scrollViewDelegate
extension ZSegmentedControl: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollView.contentOffset = scrollView.contentOffset
    }
}

