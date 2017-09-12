//
//  CharacterLimbo.swift
//  https://github.com/mthud/MorphingLabel
//

import UIKit

public struct CharacterLimbo: CustomDebugStringConvertible {
    
    public let char: Character
    public var rect: CGRect
    public var alpha: CGFloat
    public var size: CGFloat
    public var drawingProgress: CGFloat = 0.0
    
    public var debugDescription: String {
        return "Character: '\(char)'"
            + "drawIn (\(rect.origin.x), \(rect.origin.y), "
            + "\(rect.size.width)x\(rect.size.height) "
            + "with alpha \(alpha) "
            + "and \(size)pt font."
    }
    
}
