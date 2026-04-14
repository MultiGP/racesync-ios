//
//  UIView+Separator.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-03-03.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit

extension UIView {

    public static func separatorLine() -> UIView {
        let separatorLine = UIView()
        separatorLine.backgroundColor = Color.gray100
        separatorLine.snp.makeConstraints {
            $0.height.equalTo(0.3)
        }
        return separatorLine
    }

    public func addSeparatorLine(_ position: UIBarPosition = .top) {

        let separatorLine = UIView.separatorLine()
        addSubview(separatorLine)
        
        separatorLine.snp.makeConstraints {
            $0.width.equalToSuperview()

            if position == .top || position == .topAttached {
                $0.top.equalTo(snp.top)
            } else if position == .bottom {
                $0.bottom.equalTo(snp.bottom)
            }
        }
    }
}
