//
//  UIImage+Extensions.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-20.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit

/// Instance Methods
extension UIImage {

    func image(withColor color: UIColor) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!

        let rect = CGRect(origin: CGPoint.zero, size: size)

        color.setFill()
        self.draw(in: rect)
        context.setBlendMode(.sourceIn)
        context.fill(rect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func blurred(radius: CGFloat) -> UIImage {
        let ciContext = CIContext(options: nil)
        guard let cgImage = cgImage else { return self }
        let inputImage = CIImage(cgImage: cgImage)
        guard let ciFilter = CIFilter(name: "CIGaussianBlur") else { return self }
        ciFilter.setValue(inputImage, forKey: kCIInputImageKey)
        ciFilter.setValue(radius, forKey: "inputRadius")
        guard let resultImage = ciFilter.value(forKey: kCIOutputImageKey) as? CIImage else { return self }
        guard let cgImage2 = ciContext.createCGImage(resultImage, from: inputImage.extent) else { return self }
        return UIImage(cgImage: cgImage2)
    }

    func cropImage(to rect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: rect.size.width / scale, height: rect.size.height / scale), true, self.scale)
        draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y))
        let cropImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return cropImage
    }

    func rounded(with cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.addClip()

        draw(in: rect)

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return roundedImage
    }

    func circular(with backgroundColor: UIColor? = nil) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!

        if let color = backgroundColor {
            color.setFill()
            self.draw(in: rect)
            context.fill(rect)
        }

        let path = UIBezierPath(ovalIn: rect)
        path.addClip()

        UIImage(cgImage: cgImage!, scale: scale, orientation: imageOrientation).draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

/// Static Methods
extension UIImage {

    static func image(withColor color: UIColor? = nil, borderColor: UIColor? = nil, cornerRadius: CGFloat? = nil, imageSize: CGSize) -> UIImage? {
        defer {  UIGraphicsEndImageContext() }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)

        let rect = CGRect(origin: .zero, size: imageSize)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(cornerRadius ?? 0))
        path.addClip()

        if let color = color {
            color.setFill()
            path.fill()
        }

        if let borderColor = borderColor {
            borderColor.setStroke()
            path.lineWidth = 2
            path.stroke()
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    static func image(withImage image: UIImage, _ overlayColor: UIColor?, _ borderColor: UIColor?, _ cornerRadius: CGFloat?, _ size: CGSize) -> UIImage? {
        defer {  UIGraphicsEndImageContext() }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        guard let overlay = UIImage.image(withColor: overlayColor, cornerRadius: cornerRadius, imageSize: size) else { return nil }

        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(cornerRadius ?? 0))
        path.addClip()

        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        overlay.draw(in: CGRect(origin: CGPoint.zero, size: size))

        if let borderColor = borderColor {
            borderColor.setStroke()
            path.lineWidth = 2
            path.stroke()
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

