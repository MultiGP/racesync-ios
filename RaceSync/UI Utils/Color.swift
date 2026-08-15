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
    public static let light =                   #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) // Always white regardless of color mode
    public static let dark =                    #colorLiteral(red: 0.057, green: 0.057, blue: 0.06, alpha: 1) // Always black regardless of color mode
    public static let green: UIColor =          #colorLiteral(red: 0.2196078431, green: 0.4941176471, blue: 0.1607843137, alpha: 1) // #387e29
    public static let red =                     dynamic(light: #colorLiteral(red: 0.5529411765, green: 0.09411764706, blue: 0.1058823529, alpha: 1), dark: #colorLiteral(red: 0.768627451, green: 0.1254901961, blue: 0.2, alpha: 1)) // #8d181b       // Links and text action items
    public static let blue =                    dynamic(light: #colorLiteral(red: 0.1333333333, green: 0.168627451, blue: 0.3568627451, alpha: 1), dark: #colorLiteral(red: 0.3256023209, green: 0.6782188073, blue: 0.8992619779, alpha: 1)) // #222b5b       // UI buttons and interactive elements

    // Secondary Colors
    public static let lightRed: UIColor =       #colorLiteral(red: 0.9764705882, green: 0.2705882353, blue: 0.231372549, alpha: 1) // #F9453B          // badges
    public static let lightBlue: UIColor =      #colorLiteral(red: 0.4588235294, green: 0.7450980392, blue: 0.8588235294, alpha: 1) // #75bedb
    public static let orange: UIColor =         #colorLiteral(red: 1, green: 0.5843137255, blue: 0.1960784314, alpha: 1) // #FF9532
    public static let yellow: UIColor =         #colorLiteral(red: 0.9764705882, green: 0.8431372549, blue: 0.2862745098, alpha: 1) // #F9D749          // Special elements (GQ Trophee)

    // Grayscales
    public static let white =                   dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), dark: #colorLiteral(red: 0.057, green: 0.057, blue: 0.06, alpha: 1))
    public static let gray20 =                  dynamic(light: #colorLiteral(red: 0.9607843137, green: 0.9647058824, blue: 0.988627451, alpha: 1), dark: #colorLiteral(red: 0.1746, green: 0.1746, blue: 0.18, alpha: 1))                  // lite-backgrounds
    public static let gray50 =                  dynamic(light: #colorLiteral(red: 0.9294117647, green: 0.9254901961, blue: 0.9533333333, alpha: 1), dark: #colorLiteral(red: 0.2362159737, green: 0.2362159737, blue: 0.2486483934, alpha: 1))                  // backgrounds
    public static let gray100 =                 dynamic(light: #colorLiteral(red: 0.7921568627, green: 0.7921568627, blue: 0.8121568627, alpha: 1), dark: #colorLiteral(red: 0.3270185178, green: 0.3270185178, blue: 0.3442300187, alpha: 1))                  // bar shadow, separator lines
    public static let gray200 =                 dynamic(light: #colorLiteral(red: 0.5568627451, green: 0.5568627451, blue: 0.5964705882, alpha: 1), dark: #colorLiteral(red: 0.5666470588, green: 0.5666470588, blue: 0.5964705882, alpha: 1))
    public static let gray300 =                 dynamic(light: #colorLiteral(red: 0.4274509804, green: 0.4274509804, blue: 0.4670588235, alpha: 1), dark: #colorLiteral(red: 0.6780392157, green: 0.6780392157, blue: 0.7137254902, alpha: 1))                  // sub-titles
    public static let gray400 =                 dynamic(light: #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.282745098, alpha: 1), dark: #colorLiteral(red: 0.76, green: 0.76, blue: 0.8, alpha: 1))                  // caption
    public static let gray500 =                 dynamic(light: #colorLiteral(red: 0.1921568627, green: 0.1921568627, blue: 0.2200000000, alpha: 1), dark: #colorLiteral(red: 0.8717647059, green: 0.8717647059, blue: 0.9176470588, alpha: 1))
    public static let black =                   dynamic(light: #colorLiteral(red: 0.05458580635, green: 0.05458580635, blue: 0.05627402716, alpha: 1), dark: #colorLiteral(red: 0.97, green: 0.97, blue: 1, alpha: 1))                  // titles / text
    public static let clear: UIColor =          #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0) // #000000
    
    // UI specific
    public static let cellColor =               dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), dark: #colorLiteral(red: 0.048, green: 0.048, blue: 0.06, alpha: 1))
    public static let cellColor2 =              dynamic(light: #colorLiteral(red: 0.9702, green: 0.9702, blue: 0.98, alpha: 1), dark: #colorLiteral(red: 0.072, green: 0.072, blue: 0.09, alpha: 1))
    
    public static let buttonTint =              dynamic(light: Color.blue, dark: Color.light)
    public static let viewTint =                dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.98), dark: #colorLiteral(red: 0.048, green: 0.048, blue: 0.06, alpha: 0.98))
    public static let barBackground =           dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.98), dark: #colorLiteral(red: 0.048, green: 0.048, blue: 0.06, alpha: 0.98))
    public static let tabBarForeground =        dynamic(light: Color.blue, dark: Color.light)
    public static let tableBackground =         dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.98), dark: #colorLiteral(red: 0.054, green: 0.054, blue: 0.06, alpha: 0.98))

    public static let link =                    dynamic(light: Color.red, dark: Color.blue)

    public static let pinned =                  dynamic(light: #colorLiteral(red: 0.3921568627, green: 0.4196078431, blue: 0.5490196078, alpha: 1), dark: #colorLiteral(red: 0.2475, green: 0.28125, blue: 0.45, alpha: 1))                   // standings pinned cell background
    public static let pinnedSelected =          dynamic(light: #colorLiteral(red: 0.1843137255, green: 0.2196078431, blue: 0.3960784314, alpha: 1), dark: #colorLiteral(red: 0.2142857143, green: 0.2292857143, blue: 0.3, alpha: 1))                   // standings pinned cell selected background
}

public extension Color {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}
