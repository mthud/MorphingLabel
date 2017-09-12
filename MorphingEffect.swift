//
//  MorphingEffect.swift
//  https://github.com/lexrus/LTMorphingLabel
//
//  The MIT License (MIT)
//

import UIKit

@objc public enum MorphingEffect: Int, CustomStringConvertible {

    case scale = 0
    case evaporate
    case fall
    case pixelate
    case sparkle
    case burn
    case anvil
    
    public static let allValues = [
        "Scale", "Evaporate", "Fall", "Pixelate", "Sparkle", "Burn", "Anvil"
    ]
    
    public var description: String {
        switch self {
        case .evaporate:
            return "Evaporate"
        case .fall:
            return "Fall"
        case .pixelate:
            return "Pixelate"
        case .sparkle:
            return "Sparkle"
        case .burn:
            return "Burn"
        case .anvil:
            return "Anvil"
        default:
            return "Scale"
        }
    }
}
