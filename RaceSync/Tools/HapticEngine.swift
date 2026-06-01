//
//  HapticEngine.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2026-06-01.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import UIKit

class HapticEngine {

    // MARK: - Singleton

    static let shared = HapticEngine()

    // MARK: - Public
    
    func prepare() {
        self.generator.prepare()
    }

    func trigger(_ intensity: CGFloat = 0.7) {
        let value = min(max(intensity, 0), 1)
        
        DispatchQueue.main.async {
            self.generator.impactOccurred(intensity: value)
        }
    }
    
    // MARK: - Private
    
    private let generator = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Init

    private init() { }
}
