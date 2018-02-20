//
//  FakeNavBar.swift
//  ConArtist
//
//  Created by Cameron Eldridge on 2018-02-16.
//  Copyright © 2018 Cameron Eldridge. All rights reserved.
//

import UIKit

@IBDesignable
class FakeNavBar: UIView {
    private var titleLabel: UILabel!
    var leftButton: UIButton!
    var rightButton: UIButton!

    @IBInspectable var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    @IBInspectable var leftButtonTitle: String? {
        didSet {
            leftButton.titleLabel?.text = leftButtonTitle?.lowercased()
            leftButton.isHidden = leftButtonTitle == nil
        }
    }
    @IBInspectable var rightButtonTitle: String? {
        didSet {
            rightButton.titleLabel?.text = rightButtonTitle?.lowercased()
            rightButton.isHidden = rightButtonTitle == nil
        }
    }

    private func onInit() {
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.25

        let navView = UIView()
        addSubview(navView)
        leftButton = UIButton()
        navView.addSubview(leftButton)
        rightButton = UIButton()
        navView.addSubview(rightButton)
        titleLabel = UILabel()
        navView.addSubview(titleLabel)
        addConstraints([
            NSLayoutConstraint(item: navView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 44),
            NSLayoutConstraint(item: navView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: navView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: navView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        navView.addConstraints([
            NSLayoutConstraint(item: leftButton, attribute: .leading, relatedBy: .equal, toItem: navView, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: leftButton, attribute: .centerY, relatedBy: .equal, toItem: navView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: rightButton, attribute: .trailing, relatedBy: .equal, toItem: navView, attribute: .trailing, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: rightButton, attribute: .centerY, relatedBy: .equal, toItem: navView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: navView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: titleLabel, attribute: .centerX, relatedBy: .equal, toItem: navView, attribute: .centerX, multiplier: 1, constant: 0)
        ])

        let buttonFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold).usingFeatures([.smallCaps])
        leftButton.titleLabel?.font = buttonFont
        leftButton.titleLabel?.textColor = ConArtist.Color.Brand
        rightButton.titleLabel?.font = buttonFont
        rightButton.titleLabel?.textColor = ConArtist.Color.Brand
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFontWeightSemibold)
        titleLabel.textColor = ConArtist.Color.Text
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        onInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        onInit()
    }

}
