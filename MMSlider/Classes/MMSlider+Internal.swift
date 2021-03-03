//
//  MMSlider+Internal.swift
//  MMSlider clone with multiple thumbs and values, and optional snap intervals.
//
//  Created by Champaneri Monang on 03/03/2021
//  Copyright © 2020 Champaneri Monang. All rights reserved.
//
extension MMSlider {
    func setup() {
        leftTrackColor = UIColor(red: 213 / 255, green: 0, blue: 0, alpha: 1)
        rightTrackColor = UIColor(red: 24 / 255, green: 90 / 255, blue: 188 / 255, alpha: 1)
        trackView.backgroundColor = actualTintColor
        updateTrackViewCornerRounding()
        slideView.layoutMargins = .zero
        setupOrientation()
        setupPanGesture()

        isAccessibilityElement = true
        accessibilityIdentifier = "MM_slider"
        accessibilityLabel = "slider"
        accessibilityTraits = [.adjustable]
    }

    private func setupPanGesture() {
        addConstrainedSubview(panGestureView)
        for edge: NSLayoutConstraint.Attribute in [.top, .bottom, .left, .right] {
            constrain(panGestureView, at: edge, diff: -edge.inwardSign * margin)
        }
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didDrag(_:)))
        panGesture.delegate = self
        panGestureView.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.delegate = self
        panGestureView.addGestureRecognizer(tapGesture)
    }

    func setupOrientation() {
//        thumbDefaultView.removeFromSuperview()
//        thumbDefaultView.removeConstraints(thumbDefaultView.constraints)
        trackView.removeFromSuperview()
        trackView.removeConstraints(trackView.constraints)
        slideView.removeFromSuperview()
        minimumView.removeFromSuperview()
        maximumView.removeFromSuperview()
        switch orientation {
        case .vertical:
//            addConstrainedSubview(thumbDefaultView, constrain: .top, .bottom, .centerXWithinMargins)
            addConstrainedSubview(trackView, constrain: .top, .bottom, .centerXWithinMargins)
//            thumbDefaultView.constrain(.width, to: trackWidth)
//            thumbDefaultView.addConstrainedSubview(slideView, constrain: .left, .right, .bottomMargin, .topMargin)
            trackView.constrain(.width, to: trackWidth)
            trackView.addConstrainedSubview(slideView, constrain: .left, .right, .bottomMargin, .topMargin)
            addConstrainedSubview(minimumView, constrain: .bottomMargin, .centerXWithinMargins)
            addConstrainedSubview(maximumView, constrain: .topMargin, .centerXWithinMargins)
        default:
            let centerAttribute: NSLayoutConstraint.Attribute
            if #available(iOS 12, *) {
                centerAttribute = .centerY // iOS 12 doesn't like .leftMargin, .rightMargin
            } else {
                centerAttribute = .centerYWithinMargins
            }
//            addConstrainedSubview(thumbDefaultView, constrain: .left, .right, centerAttribute)
//            thumbDefaultView.constrain(.height, to: trackWidth)
            addConstrainedSubview(trackView, constrain: .left, .right, centerAttribute)
            trackView.constrain(.height, to: trackWidth)
            if #available(iOS 12, *) {
//                thumbDefaultView.addConstrainedSubview(slideView, constrain: .top, .bottom, .left, .right)
                trackView.addConstrainedSubview(slideView, constrain: .top, .bottom, .left, .right) // iOS 12 β doesn't like .leftMargin, .rightMargin
            } else {
//                thumbDefaultView.addConstrainedSubview(slideView, constrain: .top, .bottom, .leftMargin, .rightMargin)
                trackView.addConstrainedSubview(slideView, constrain: .top, .bottom, .leftMargin, .rightMargin)
            }
            addConstrainedSubview(minimumView, constrain: .leftMargin, centerAttribute)
            addConstrainedSubview(maximumView, constrain: .rightMargin, centerAttribute)
        }
        setupTrackLayoutMargins()
    }

    func setupTrackLayoutMargins() {
        let thumbSize = (thumbImage ?? defaultThumbImage)?.size ?? CGSize(width: 2, height: 2)
        let thumbDiameter = orientation == .vertical ? thumbSize.height : thumbSize.width
        let halfThumb = thumbDiameter / 2 - 1 // 1 pixel for semi-transparent boundary
        if orientation == .vertical {
//            thumbDefaultView.layoutMargins = UIEdgeInsets(top: halfThumb, left: 0, bottom: halfThumb, right: 0)
            trackView.layoutMargins = UIEdgeInsets(top: halfThumb, left: 0, bottom: halfThumb, right: 0)
        } else {
//            thumbDefaultView.layoutMargins = UIEdgeInsets(top: 0, left: halfThumb, bottom: 0, right: halfThumb)
            trackView.layoutMargins = UIEdgeInsets(top: 0, left: halfThumb, bottom: 0, right: halfThumb)
        }
    }

    func repositionThumbViews() {
        thumbViews.forEach { $0.removeFromSuperview() }
        thumbViews = []
        valueLabels.forEach { $0.removeFromSuperview() }
        valueLabels = []
//        thumbDefaultView.removeFromSuperview()
        adjustThumbCountToValueCount()
    }

    func adjustThumbCountToValueCount() {
//        addDefaultThumbView()
        if value.count == thumbViews.count {
            return
        } else if value.count < thumbViews.count {
            thumbViews.removeViewsStartingAt(value.count)
            valueLabels.removeViewsStartingAt(value.count)
        } else { // add thumbViews
            for _ in thumbViews.count ..< value.count {
                addThumbView()
            }
        }
        updateOuterTrackViews()
    }

    func updateOuterTrackViews() {
        outerTrackViews.removeViewsStartingAt(0)
        outerTrackViews.removeAll()
        guard nil != outerTrackColor else { return }
        guard let firstThumb = thumbViews.first, let lastThumb = thumbViews.last, firstThumb != lastThumb else { return }

        if orientation == .vertical {
//            if value[1] < value[0] {
//                outerTrackViews = [innerTrackView(constraining: .top(in: orientation), to: lastThumb),
//                                   innerTrackView(constraining: .bottom(in: orientation), to: firstThumb), outerTrackView(constraining: .top(in: orientation), to: firstThumb),
//                                   outerTrackView(constraining: .bottom(in: orientation), to: lastThumb),]
//            } else {
            outerTrackViews = [
                outerTrackView(constraining: .top(in: orientation), to: firstThumb),
                outerTrackView(constraining: .bottom(in: orientation), to: lastThumb),
            ]
//            }
        } else {
            outerTrackViews = [
                outerTrackViewLeft(constraining: .top(in: orientation), to: firstThumb),
                outerTrackViewRight(constraining: .bottom(in: orientation), to: lastThumb),
            ]
        }
    }

    private func outerTrackViewLeft(constraining: NSLayoutConstraint.Attribute, to thumbView: UIView) -> UIView {
        let view = UIView()
        view.backgroundColor = leftTrackColor
//        thumbDefaultView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
//        thumbDefaultView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
//        thumbDefaultView.constrain(view, at: constraining, to: thumbDefaultView, at: .center(in: orientation))
//        thumbDefaultView.sendSubviewToBack(view)

        trackView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
        trackView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
        trackView.constrain(view, at: constraining, to: thumbView, at: .center(in: orientation))
        trackView.sendSubviewToBack(view)

        view.layer.cornerRadius = trackView.layer.cornerRadius
        if #available(iOS 11.0, *) {
            view.layer.maskedCorners = .direction(constraining.opposite)
        }

        return view
    }

    private func outerTrackViewRight(constraining: NSLayoutConstraint.Attribute, to thumbView: UIView) -> UIView {
        let view = UIView()
        view.backgroundColor = rightTrackColor
//        thumbDefaultView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
//        thumbDefaultView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
//        thumbDefaultView.constrain(view, at: constraining, to: thumbDefaultView, at: .center(in: orientation))
//        thumbDefaultView.sendSubviewToBack(view)

        trackView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
        trackView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
        trackView.constrain(view, at: constraining, to: thumbView, at: .center(in: orientation))
        trackView.sendSubviewToBack(view)

        view.layer.cornerRadius = trackView.layer.cornerRadius
        if #available(iOS 11.0, *) {
            view.layer.maskedCorners = .direction(constraining.opposite)
        }

        return view
    }

    private func outerTrackView(constraining: NSLayoutConstraint.Attribute, to thumbView: UIView) -> UIView {
        let view = UIView()
        view.backgroundColor = outerTrackColor
//        thumbDefaultView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
//        thumbDefaultView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
//        thumbDefaultView.constrain(view, at: constraining, to: thumbView, at: .center(in: orientation))
//        thumbDefaultView.sendSubviewToBack(view)

        trackView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
        trackView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
        trackView.constrain(view, at: constraining, to: thumbView, at: .center(in: orientation))
        trackView.sendSubviewToBack(view)

        view.layer.cornerRadius = trackView.layer.cornerRadius
        if #available(iOS 11.0, *) {
            view.layer.maskedCorners = .direction(constraining.opposite)
        }

        return view
    }

    private func innerTrackView(constraining: NSLayoutConstraint.Attribute, to thumbView: UIView) -> UIView {
        let view = UIView()
        view.backgroundColor = tintColor
//        thumbDefaultView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
//        thumbDefaultView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
//        thumbDefaultView.constrain(view, at: constraining, to: thumbDefaultView, at: .center(in: orientation))
//        thumbDefaultView.sendSubviewToBack(view)
//        view.layer.cornerRadius = thumbDefaultView.layer.cornerRadius

        trackView.addConstrainedSubview(view, constrain: .top, .bottom, .leading, .trailing)
        trackView.removeFirstConstraint { $0.firstItem === view && $0.firstAttribute == constraining }
        trackView.constrain(view, at: constraining, to: thumbView, at: .center(in: orientation))
        trackView.sendSubviewToBack(view)

        view.layer.cornerRadius = trackView.layer.cornerRadius
        if #available(iOS 11.0, *) {
            view.layer.maskedCorners = .direction(constraining.opposite)
        }

        return view
    }

    private func addThumbView() {
        let i = thumbViews.count
        let thumbView = UIImageView(image: thumbImage ?? defaultThumbImage)
        thumbView.addShadow()
        thumbViews.append(thumbView)
        slideView.addConstrainedSubview(thumbView, constrain: NSLayoutConstraint.Attribute.center(in: orientation).perpendicularCenter)
        positionThumbView(i)
        thumbView.blur(disabledThumbIndices.contains(i))
        addValueLabel(i)
        updateThumbViewShadowVisibility()
    }

//    private func addDefaultThumbView() {
//        let thumbDefaultView = UIImageView(image: thumbImage ?? defaultThumbImage)
//        thumbDefaultView.addShadow()
//        slideView.addConstrainedSubview(thumbDefaultView, constrain: NSLayoutConstraint.Attribute.center(in: orientation).perpendicularCenter)
    ////        positionDefaultThumbView()
//
    ////        addValueDefaultLabel()
//        updateThumbViewShadowVisibility()
//    }

    func updateThumbViewShadowVisibility() {
        thumbViews.forEach {
            $0.layer.shadowOpacity = showsThumbImageShadow ? 0.25 : 0
        }
    }

    func addValueLabel(_ i: Int) {
        guard valueLabelPosition != .notAnAttribute else { return }
        let valueLabel = UITextField()
        valueLabel.borderStyle = .none
        slideView.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        let thumbView = thumbViews[i]
        slideView.constrain(valueLabel, at: valueLabelPosition.perpendicularCenter, to: thumbView)
        slideView.constrain(
            valueLabel, at: valueLabelPosition.opposite,
            to: thumbView, at: valueLabelPosition,
            diff: -valueLabelPosition.inwardSign * thumbView.diagonalSize / 4
        )
        valueLabels.append(valueLabel)
        updateValueLabel(i)
    }

//    func addValueDefaultLabel() {
//        guard valueLabelPosition != .notAnAttribute else { return }
//        let valueDefautlsLabels = UITextField()
//        valueDefautlsLabels.borderStyle = .none
//        slideView.addSubview(valueDefautlsLabels)
//        valueDefautlsLabels.translatesAutoresizingMaskIntoConstraints = false
    ////        let thumbView = thumbDefaultView
//        slideView.constrain(valueDefautlsLabels, at: valueLabelPosition.perpendicularCenter, to: thumbView)
//        slideView.constrain(
//            valueDefautlsLabels, at: valueLabelPosition.opposite,
//            to: thumbView, at: valueLabelPosition,
//            diff: -valueLabelPosition.inwardSign * thumbView.diagonalSize / 4
//        )
    ////        valueLabels.append(valueLabel)
//        updateValueDefaultLabel()
//    }

//    valueDefautlsLabels
//    func updateValueDefaultLabel() {
//        let labelValue: CGFloat
    ////        if isValueLabelRelative {
    ////            valueDefautlsLabels = i > 0 ? value[i] - value[i - 1] : value[i] - minimumValue
    ////        } else {
    ////            labelValue = value[i]
    ////        }
//        valueDefautlsLabels.text = valueLabelFormatter.string(from: NSNumber(value: Double(defaultValue)))
//    }

    func updateValueLabel(_ i: Int) {
        let labelValue: CGFloat
        if isValueLabelRelative {
            labelValue = i > 0 ? value[i] - value[i - 1] : value[i] - minimumValue
        } else {
            labelValue = value[i]
        }
        valueLabels[i].text = valueLabelFormatter.string(from: NSNumber(value: floor(Double(labelValue))))
    }

    func updateValueCount(_ count: Int) {
        guard count != value.count else { return }
        isSettingValue = true
        if value.count < count {
            let appendCount = count - value.count
            var startValue = value.last ?? minimumValue
            let length = maximumValue - startValue
            let relativeStepSize = snapStepSize / (maximumValue - minimumValue)
            var step: CGFloat = 0
            if 0 == value.count && 1 < appendCount {
                step = (length / CGFloat(appendCount - 1)).truncated(relativeStepSize)
            } else {
                step = (length / CGFloat(appendCount)).truncated(relativeStepSize)
                if 0 < value.count {
                    startValue += step
                }
            }
            if 0 == step { step = relativeStepSize }
            value += stride(from: startValue, through: maximumValue, by: step)
        }
        if value.count > count { // don't add "else", since prev calc may add too many values in some cases
            value.removeLast(value.count - count)
        }

        isSettingValue = false
    }

    func adjustValuesToStepAndLimits() {
        var adjusted = value
        for i in 0 ..< adjusted.count {
            let snapped = adjusted[i].rounded(snapStepSize)
            adjusted[i] = min(maximumValue, max(minimumValue, snapped))
        }

        isSettingValue = true
        value = adjusted
        isSettingValue = false

        for i in 0 ..< value.count {
            positionThumbView(i)
        }
    }

    func positionThumbView(_ i: Int) {
        let thumbView = thumbViews[i]
        let thumbValue = value[i]
        slideView.removeFirstConstraint { $0.firstItem === thumbView && $0.firstAttribute == .center(in: orientation) }
        let thumbRelativeDistanceToMax = (maximumValue - thumbValue) / (maximumValue - minimumValue)
        if orientation == .horizontal {
            if thumbRelativeDistanceToMax < 1 {
                slideView.constrain(thumbView, at: .centerX, to: slideView, at: .right, ratio: CGFloat(1 - thumbRelativeDistanceToMax))
            } else {
                slideView.constrain(thumbView, at: .centerX, to: slideView, at: .left)
            }
        } else { // vertical orientation
            if thumbRelativeDistanceToMax.isNormal {
                slideView.constrain(thumbView, at: .centerY, to: slideView, at: .bottom, ratio: CGFloat(thumbRelativeDistanceToMax))
            } else {
                slideView.constrain(thumbView, at: .centerY, to: slideView, at: .top)
            }
        }
        UIView.animate(withDuration: 0.1) {
            self.slideView.updateConstraintsIfNeeded()
        }
    }

//    func positionDefaultThumbView() {
//        slideView.removeFirstConstraint { $0.firstItem === thumbDefaultView && $0.firstAttribute == .center(in: orientation) }
//        let thumbRelativeDistanceToMax = (maximumValue - defaultValue) / (maximumValue - minimumValue)
//        if orientation == .horizontal {
//            if thumbRelativeDistanceToMax < 1 {
//                slideView.constrain(thumbDefaultView, at: .centerX, to: slideView, at: .right, ratio: CGFloat(1 - thumbRelativeDistanceToMax))
//            } else {
//                slideView.constrain(thumbDefaultView, at: .centerX, to: slideView, at: .left)
//            }
//        } else { // vertical orientation
//            if thumbRelativeDistanceToMax.isNormal {
//                slideView.constrain(thumbDefaultView, at: .centerY, to: slideView, at: .bottom, ratio: CGFloat(thumbRelativeDistanceToMax))
//            } else {
//                slideView.constrain(thumbDefaultView, at: .centerY, to: slideView, at: .top)
//            }
//        }
//        UIView.animate(withDuration: 0.1) {
//            self.slideView.updateConstraintsIfNeeded()
//        }
//    }

    func layoutTrackEdge(toView: UIImageView, edge: NSLayoutConstraint.Attribute, superviewEdge: NSLayoutConstraint.Attribute) {
        removeFirstConstraint { $0.firstItem === self.trackView && ($0.firstAttribute == edge || $0.firstAttribute == superviewEdge) }
        if nil != toView.image {
            constrain(trackView, at: edge, to: toView, at: edge.opposite, diff: edge.inwardSign * 8)
        } else {
            constrain(trackView, at: edge, to: self, at: superviewEdge)
        }
    }

    func updateTrackViewCornerRounding() {
        trackView.layer.cornerRadius = hasRoundTrackEnds ? trackWidth / 2 : 1
        outerTrackViews.forEach { $0.layer.cornerRadius = trackView.layer.cornerRadius }
    }
}
