//
//  Color.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-10-30.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

// Color Palette
public struct Color {
    // Main colors
    public static let red: UIColor =            #colorLiteral(red: 0.5529411765, green: 0.09411764706, blue: 0.1058823529, alpha: 1) // #8d181b          // Links and text action items
    public static let blue: UIColor =           #colorLiteral(red: 0.1333333333, green: 0.168627451, blue: 0.3568627451, alpha: 1) // #222b5b          // UI buttons and interactive elements
    public static let green: UIColor =          #colorLiteral(red: 0.2196078431, green: 0.4941176471, blue: 0.1607843137, alpha: 1) // #387e29
    public static let yellow: UIColor =         #colorLiteral(red: 0.9764705882, green: 0.8431372549, blue: 0.2862745098, alpha: 1) // #f9d749          // Special elements (GQ Trophee)

    // Secondary Colors
    public static let lightRed: UIColor =       #colorLiteral(red: 0.9764705882, green: 0.2705882353, blue: 0.231372549, alpha: 1) // #f9453b          // badges
    public static let lightBlue: UIColor =      #colorLiteral(red: 0.4588235294, green: 0.7450980392, blue: 0.8588235294, alpha: 1) // #75bedb

    // Grayscale
    public static let white: UIColor =          #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) // #FFFFFF
    public static let gray20: UIColor =         #colorLiteral(red: 0.9607843137, green: 0.9647058824, blue: 0.988627451, alpha: 1) // #F5F6FC          // lite-backgrounds
    public static let gray50: UIColor =         #colorLiteral(red: 0.9294117647, green: 0.9254901961, blue: 0.9533333333, alpha: 1) // #EDECF3          // backgrounds
    public static let gray100: UIColor =        #colorLiteral(red: 0.7921568627, green: 0.7921568627, blue: 0.8121568627, alpha: 1) // #CACACF          // bar shadow, separator lines
    public static let gray200: UIColor =        #colorLiteral(red: 0.5568627451, green: 0.5568627451, blue: 0.5964705882, alpha: 1) // #8E8E98
    public static let gray300: UIColor =        #colorLiteral(red: 0.4274509804, green: 0.4274509804, blue: 0.4670588235, alpha: 1) // #6D6D77          // sub-titles
    public static let gray400: UIColor =        #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.282745098, alpha: 1) // #434348          // caption
    public static let gray500: UIColor =        #colorLiteral(red: 0.1921568627, green: 0.1921568627, blue: 0.2200000000, alpha: 1) // #313138
    public static let black: UIColor =          #colorLiteral(red: 0.0431372549, green: 0.0431372549, blue: 0.0431372549, alpha: 1) // #0B0B0B          // titles / text
    public static let clear: UIColor =          #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0) // #000000

    // UI specific
    public static let navigationBarColor =      Color.white.withAlphaComponent(0.98)
    public static let link =                    Color.red
    
    public static let pinned =                  #colorLiteral(red: 0.3921568627, green: 0.4196078431, blue: 0.5490196078, alpha: 1) // #646b8c          // standings pinned cell background
    public static let pinnedSelected =          #colorLiteral(red: 0.1843137255, green: 0.2196078431, blue: 0.3960784314, alpha: 1) // #2f3865          // standings pinned cell selected background
}
