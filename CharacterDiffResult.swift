//
//  CharacterDiffResult.swift
//  https://github.com/mthud/MorphingLabel
//

import Foundation

public enum CharacterDiffResult: CustomDebugStringConvertible, Equatable {
    
    case same
    case add
    case delete
    case move(offset: Int)
    case moveAndAdd(offset: Int)
    case replace
    
    public var debugDescription: String {
        switch self {
        case .same:
            return "The character is unchanged."
        case .add:
            return "A new character is ADDED."
        case .delete:
            return "The character is DELETED."
        case .move(let offset):
            return "The character is MOVED to \(offset)."
        case .moveAndAdd(let offset):
            return "The character is MOVED to \(offset) and a new character is ADDED."
        case .replace:
            return "The character is REPLACED with a new character."
        }
    }
}

public func == (lhs: CharacterDiffResult, rhs: CharacterDiffResult) -> Bool 
{
    switch (lhs, rhs) {
      case (.move(let offset0), .move(let offset1)):
        return offset0 == offset1
    
      case (.moveAndAdd(let offset0), .moveAndAdd(let offset1)):
        return offset0 == offset1
    
      case (.add, .add):
        return true
        
      case (.delete, .delete):
        return true
    
      case (.replace, .replace):
        return true
    
      case (.same, .same):
        return true
    
      default: return false
    }
}
