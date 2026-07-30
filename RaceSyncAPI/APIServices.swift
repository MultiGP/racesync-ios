//
//  RSAPIServices.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-10-27.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation
import AlamofireNetworkActivityIndicator

public class APIServices {

    // MARK: - Public Variables

    public static var shared: APIServices {
        guard let instance = _shared else {
            fatalError("APIServices.configure() must be called before accessing shared")
        }
        return instance
    }

    public static func configure(with credential: APICredential) {
        guard _shared == nil else { return }
        _shared = APIServices(with: credential)
    }

    public let settings: APISettings
    public var credential: APICredential

    public var myUser: User? {
        didSet {
            Clog.log("Did set my User with id: \(String(describing: myUser?.id))")
        }
    }
    
    public func isCurrentUser(_ user: User?) -> Bool {
        let currentUserId = APIServices.shared.myUser?.id
        return currentUserId.map { user?.id == $0 } ?? false
    }

    // My Home Chapter
    public var myChapter: Chapter? {
        didSet {
            Clog.log("Did set my Chapter with id: \(String(describing: myChapter?.id))")
        }
    }

    public var myManagedChapters: [ManagedChapter]? {
        didSet {
            let ids = myManagedChapters?.compactMap { $0.id }
            Clog.log("Did set my Managed Chapters with ids: \(String(describing: ids))")
        }
    }

    public var isLoggedIn: Bool {
        get { return APISessionManager.hasValidSession() }
    }

    // MARK: - Initialization

    private init(with credential: APICredential) {
        NetworkActivityIndicatorManager.shared.isEnabled = true
        self.settings = APISettings()
        self.credential = credential
    }

    // MARK: - Invalidation

    public func invalidate() {
        self.myUser = nil
        self.settings.invalidateSettings()
    }

    // MARK: - Private

    private static var _shared: APIServices?
}
