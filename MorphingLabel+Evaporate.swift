//
//  MorphingLabel+Evaporate.swift
//  https://github.com/mthud/MorphingLabel
//

import UIKit

extension MorphingLabel {
    
    func EvaporateLoad() {
        
        progressClosures["Evaporate\(MorphingPhases.progress)"] = {
            (index: Int, progress: Float, isNewChar: Bool) in
            let j: Int = Int(round(cos(Double(index)) * 1.2))
            let delay = isNewChar ? self.morphingCharacterDelay * -1.0 : self.morphingCharacterDelay
            return min(1.0, max(0.0, self.morphingProgress + delay * Float(j)))
        }
        
        effectClosures["Evaporate\(MorphingPhases.disappear)"] = {
            char, index, progress in
            
            let newProgress = Easing.easeOutQuint(progress, 0.0, 1.0, 1.0)
            let yOffset: CGFloat = -0.8 * CGFloat(self.font.pointSize) * CGFloat(newProgress)
            let currentRect = self.previousRects[index].offsetBy(dx: 0, dy: yOffset)
            let currentAlpha = CGFloat(1.0 - newProgress)
            
            return CharacterLimbo (
                char: char,
                rect: currentRect,
                alpha: currentAlpha,
                size: self.font.pointSize,
                drawingProgress: 0.0
            )
        }
        
        effectClosures["Evaporate\(MorphingPhases.appear)"] = {
            char, index, progress in
            
            let newProgress = 1.0 - Easing.easeOutQuint(progress, 0.0, 1.0)
            let yOffset = CGFloat(self.font.pointSize) * CGFloat(newProgress) * 1.2
            
            return CharacterLimbo (
                char: char,
                rect: self.newRects[index].offsetBy(dx: 0, dy: yOffset),
                alpha: CGFloat(self.morphingProgress),
                size: self.font.pointSize,
                drawingProgress: 0.0
            )
        }
    }
}
