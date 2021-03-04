//
//  MMSlider.swift
//  MMSlider clone with multiple thumbs and values, and optional snap intervals.
//
//  Created by Champaneri Monang on 03/03/2021
//  Copyright © 2020 Champaneri Monang. All rights reserved.
//

import AvailableHapticFeedback
import SweeterSwift
import UIKit

@objc protocol MMSliderCellDelegate {
    func sliderValueChange(_ value: MMSlider)
    func tapOnSlider(_ value: CGFloat)
}

@IBDesignable
open class MMSlider: UIControl {
    weak var delegate: MMSliderCellDelegate?
    @objc open dynamic var value: [CGFloat] = [] {
        didSet {
            if isSettingValue { return }
            adjustThumbCountToValueCount()
            adjustValuesToStepAndLimits()
            for i in 0 ..< valueLabels.count {
                updateValueLabel(i)
            }
            accessibilityValue = value.description
        }
    }

    @objc open var defaultValue: CGFloat = 0 {
        didSet {
            if isSettingValue { return }
        }
    }

    @IBInspectable open dynamic var minimumValue: CGFloat = 0 { didSet { adjustValuesToStepAndLimits() } }
    @IBInspectable open dynamic var maximumValue: CGFloat = 1 { didSet { adjustValuesToStepAndLimits() } }
    @IBInspectable open dynamic var isContinuous: Bool = true

    /// snap thumbs to specific values, evenly spaced. (default = 0: allow any value)
    @IBInspectable open dynamic var snapStepSize: CGFloat = 0 { didSet { adjustValuesToStepAndLimits() } }

    /// generate haptic feedback when hitting snap steps
    @IBInspectable open dynamic var isHapticSnap: Bool = true

    @IBInspectable open dynamic var thumbCount: Int {
        get {
            return thumbViews.count
        }
        set {
            guard newValue > 0 else { return }
            updateValueCount(newValue)
            adjustThumbCountToValueCount()
        }
    }

    /// make specific thumbs fixed (and grayed)
    @objc open var disabledThumbIndices: Set<Int> = [] {
        didSet {
            for i in 0 ..< thumbCount {
                thumbViews[i].blur(disabledThumbIndices.contains(i))
            }
        }
    }

    /// show value labels next to thumbs. (default: show no label)
    @objc open dynamic var valueLabelPosition: NSLayoutConstraint.Attribute = .notAnAttribute {
        didSet {
            valueLabels.removeViewsStartingAt(0)
            if valueLabelPosition != .notAnAttribute {
                for i in 0 ..< thumbViews.count {
                    addValueLabel(i)
                }
            }
        }
    }
    
    @IBInspectable open dynamic var valueLabelColor: UIColor? {
        didSet {
            valueLabels.forEach { $0.textColor = valueLabelColor }
        }
    }

    open dynamic var valueLabelFont: UIFont? {
        didSet {
            valueLabels.forEach { $0.font = valueLabelFont }
        }
    }

    /// value label shows difference from previous thumb value (true) or absolute value (false = default)
    @IBInspectable open dynamic var isValueLabelRelative: Bool = false {
        didSet {
            for i in 0 ..< valueLabels.count {
                updateValueLabel(i)
            }
        }
    }

    // MARK: - Appearance

    @objc open dynamic var orientation: NSLayoutConstraint.Axis = .vertical {
        didSet {
            setupOrientation()
            invalidateIntrinsicContentSize()
            repositionThumbViews()
        }
    }

    @IBInspectable open dynamic var leftTrackColor = UIColor(red: 213 / 255, green: 0, blue: 0, alpha: 1) {
        didSet {
            updateOuterTrackViews()
        }
    }

    @IBInspectable open dynamic var rightTrackColor = UIColor(red: 24 / 255, green: 90 / 255, blue: 188 / 255, alpha: 1) {
        didSet {
            updateOuterTrackViews()
        }
    }

    /// track color before first thumb and after last thumb. `nil` means to use the tintColor, like the rest of the track.
    @IBInspectable open dynamic var outerTrackColor: UIColor? {
        didSet {
            updateOuterTrackViews()
        }
    }

    @IBInspectable open dynamic var thumbImage: UIImage? {
        didSet {
            thumbViews.forEach { $0.image = thumbImage }
            setupTrackLayoutMargins()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable public dynamic var showsThumbImageShadow: Bool = true {
        didSet {
            updateThumbViewShadowVisibility()
        }
    }

    @IBInspectable open dynamic var minimumImage: UIImage? {
        get {
            return minimumView.image
        }
        set {
            minimumView.image = newValue
            layoutTrackEdge(
                toView: minimumView,
                edge: .bottom(in: orientation),
                superviewEdge: orientation == .vertical ? .bottomMargin : .leadingMargin
            )
        }
    }

    @IBInspectable open dynamic var maximumImage: UIImage? {
        get {
            return maximumView.image
        }
        set {
            maximumView.image = newValue
            layoutTrackEdge(
                toView: maximumView,
                edge: .top(in: orientation),
                superviewEdge: orientation == .vertical ? .topMargin : .trailingMargin
            )
        }
    }

    @IBInspectable open dynamic var trackWidth: CGFloat = 2 {
        didSet {
            let widthAttribute: NSLayoutConstraint.Attribute = orientation == .vertical ? .width : .height
            trackView.removeFirstConstraint { $0.firstAttribute == widthAttribute }
            trackView.constrain(widthAttribute, to: trackWidth)
            updateTrackViewCornerRounding()
        }
    }

    @IBInspectable public dynamic var hasRoundTrackEnds: Bool = true {
        didSet {
            updateTrackViewCornerRounding()
        }
    }

    @IBInspectable public dynamic var keepsDistanceBetweenThumbs: Bool = true

    @objc open dynamic var valueLabelFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        formatter.roundingMode = .halfEven
        return formatter
    }()

    // MARK: - Subviews

//    @objc open var valueDefautlsLabels = UITextField()
//    @objc open var thumbDefaultView = UIImageView()
    @objc open var thumbViews: [UIImageView] = []
    @objc open var valueLabels: [UITextField] = [] // UILabels are a pain to layout, text fields look nice as-is.
    @objc open var trackView = UIView()
    @objc open var outerTrackViews: [UIView] = []
    @objc open var minimumView = UIImageView()
    @objc open var maximumView = UIImageView()

    // MARK: - Internals

    let slideView = UIView()
    let panGestureView = UIView()
    let margin: CGFloat = 32
    var isSettingValue = false
    var draggedThumbIndex: Int = -1
    lazy var defaultThumbImage: UIImage? = .circle()
    var selectionFeedbackGenerator = AvailableHapticFeedback()

    // MARK: - Overrides

    open override func tintColorDidChange() {
        let thumbTint = thumbViews.map { $0.tintColor } // different thumbs may have different tints
        super.tintColorDidChange()
        trackView.backgroundColor = actualTintColor
        for (thumbView, tint) in zip(thumbViews, thumbTint) {
            thumbView.tintColor = tint
        }
    }

    open override var intrinsicContentSize: CGSize {
        let thumbSize = (thumbImage ?? defaultThumbImage)?.size ?? CGSize(width: margin, height: margin)
        switch orientation {
        case .vertical:
            return CGSize(width: thumbSize.width + margin, height: UIView.noIntrinsicMetric)
        default:
            return CGSize(width: UIView.noIntrinsicMetric, height: thumbSize.height + margin)
        }
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || alpha == 0 { return nil }
        if clipsToBounds { return super.hitTest(point, with: event) }
        return panGestureView.hitTest(panGestureView.convert(point, from: self), with: event)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        // make visual editing easier
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor

        // evenly distribute thumbs
        let oldThumbCount = thumbCount
        thumbCount = 0
        thumbCount = oldThumbCount
    }
}
