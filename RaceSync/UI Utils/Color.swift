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
    public static let white =                   dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), dark: #colorLiteral(red: 0.09803921569, green: 0.1137254902, blue: 0.1333333333, alpha: 0.98))
    public static let gray20 =                  dynamic(light: #colorLiteral(red: 0.9607843137, green: 0.9647058824, blue: 0.988627451, alpha: 1), dark: #colorLiteral(red: 0.1294117647, green: 0.1529411765, blue: 0.1843137255, alpha: 1))                  // lite-backgrounds
    public static let gray50 =                  dynamic(light: #colorLiteral(red: 0.9294117647, green: 0.9254901961, blue: 0.9533333333, alpha: 1), dark: #colorLiteral(red: 0.168627451, green: 0.2, blue: 0.2352941176, alpha: 1))                  // backgrounds
    public static let gray100 =                 dynamic(light: #colorLiteral(red: 0.7921568627, green: 0.7921568627, blue: 0.8121568627, alpha: 1), dark: #colorLiteral(red: 0.2823529412, green: 0.3176470588, blue: 0.3647058824, alpha: 1))                  // bar shadow, separator lines
    public static let gray200 =                 dynamic(light: #colorLiteral(red: 0.5568627451, green: 0.5568627451, blue: 0.5964705882, alpha: 1), dark: #colorLiteral(red: 0.5019607843, green: 0.537254902, blue: 0.5921568627, alpha: 1))
    public static let gray300 =                 dynamic(light: #colorLiteral(red: 0.4274509804, green: 0.4274509804, blue: 0.4670588235, alpha: 1), dark: #colorLiteral(red: 0.6156862745, green: 0.6470588235, blue: 0.6980392157, alpha: 1))                  // sub-titles
    public static let gray400 =                 dynamic(light: #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.282745098, alpha: 1), dark: #colorLiteral(red: 0.7098039216, green: 0.7450980392, blue: 0.7960784314, alpha: 1))                  // caption
    public static let gray500 =                 dynamic(light: #colorLiteral(red: 0.1921568627, green: 0.1921568627, blue: 0.2200000000, alpha: 1), dark: #colorLiteral(red: 0.8235294118, green: 0.8470588235, blue: 0.8862745098, alpha: 1))
    public static let black =                   dynamic(light: #colorLiteral(red: 0.05458580635, green: 0.05458580635, blue: 0.05627402716, alpha: 1), dark: #colorLiteral(red: 0.9333333333, green: 0.9490196078, blue: 0.9725490196, alpha: 1))                  // titles / text
    public static let clear: UIColor =          #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0) // #000000
    
    // UI specific
    public static let cellColor =               dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), dark: #colorLiteral(red: 0.09803921569, green: 0.1137254902, blue: 0.1333333333, alpha: 1))
    public static let cellColor2 =              dynamic(light: #colorLiteral(red: 0.9702, green: 0.9702, blue: 0.98, alpha: 1), dark: #colorLiteral(red: 0.1215686275, green: 0.1450980392, blue: 0.1725490196, alpha: 1))
    public static let cellGrouped =             dynamic(light: UIColor.secondarySystemGroupedBackground, dark: #colorLiteral(red: 0.1294117647, green: 0.1529411765, blue: 0.1843137255, alpha: 1))

    public static let buttonTint =              dynamic(light: Self.blue, dark: Self.light)
    public static let viewTint =                dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.98), dark: #colorLiteral(red: 0.0862745098, green: 0.1019607843, blue: 0.1215686275, alpha: 0.98))
    public static let barBackground =           dynamic(light: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.98), dark: #colorLiteral(red: 0.09803921569, green: 0.1137254902, blue: 0.1333333333, alpha: 0.98))
    public static let tabBarForeground =        dynamic(light: Color.blue, dark: Self.light)
    public static let tableBackground =         dynamic(light: UIColor.systemBackground, dark: #colorLiteral(red: 0.09803921569, green: 0.1137254902, blue: 0.1333333333, alpha: 1))
    public static let tableGroupedBackground =  dynamic(light: UIColor.systemGroupedBackground, dark: #colorLiteral(red: 0.08235294118, green: 0.09803921569, blue: 0.1176470588, alpha: 1))

    public static let link =                    dynamic(light: Self.red, dark: Self.blue)

//    public static let pinned =                  dynamic(light: #colorLiteral(red: 0.3921568627, green: 0.4196078431, blue: 0.5490196078, alpha: 1), dark: #colorLiteral(red: 0.2475, green: 0.28125, blue: 0.45, alpha: 1))                   // standings pinned cell background
//    public static let pinnedSelected =          dynamic(light: #colorLiteral(red: 0.1843137255, green: 0.2196078431, blue: 0.3960784314, alpha: 1), dark: #colorLiteral(red: 0.1843137255, green: 0.2196078431, blue: 0.3960784314, alpha: 1))                   // standings pinned cell selected background
//    
    public static let pinned =                  #colorLiteral(red: 0.3921568627, green: 0.4196078431, blue: 0.5490196078, alpha: 1)                   // standings pinned cell background
    public static let pinnedSelected =          #colorLiteral(red: 0.1843137255, green: 0.2196078431, blue: 0.3960784314, alpha: 1)                   // standings pinned cell selected background
}

public extension Color {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}
