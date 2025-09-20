//
//  UITableViewCell+Reuse.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-24.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

protocol Reusable: AnyObject {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: Reusable { }

extension UITableView {

    func register<T: UITableViewCell>(cellType: T.Type, identifier: String? = nil) {
            let reuseIdentifier = identifier ?? cellType.reuseIdentifier
            register(cellType.self, forCellReuseIdentifier: reuseIdentifier)
        }

    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath,
                                                 identifier: String? = nil) -> T {
        let reuseIdentifier = identifier ?? T.reuseIdentifier
        guard let cell = dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(reuseIdentifier)")
        }
        return cell
    }
}
