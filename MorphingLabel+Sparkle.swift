/
//  MorphingLabel+Sparkle.swift
//  https://github.com/mthud/MorphingLabel
//

import UIKit

extension MorphingLabel {
    
    fileprivate func maskedImageForCharLimbo(_ charLimbo: CharacterLimbo, withProgress progress: CGFloat) -> (UIImage, CGRect) 
    {
        let maskedHeight = charLimbo.rect.size.height * max(0.01, progress)
        let maskedSize = CGSize(width: charLimbo.rect.size.width, height: maskedHeight)
        
        UIGraphicsBeginImageContextWithOptions(maskedSize, false, UIScreen.main.scale)
        let rect = CGRect(x: 0, y: 0, width: charLimbo.rect.size.width, height: maskedHeight)
        
        String(charLimbo.char).draw(in: rect, withAttributes: [
            NSFontAttributeName: self.font,
            NSForegroundColorAttributeName: self.textColor
            ])
        
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return (UIImage(), CGRect.zero)
        }
        
        UIGraphicsEndImageContext()
        
        let newRect = CGRect (
            x: charLimbo.rect.origin.x,
            y: charLimbo.rect.origin.y,
            width: charLimbo.rect.size.width,
            height: maskedHeight
        )
        return (newImage, newRect)
    }
    
    func SparkleLoad() {
        
        startClosures["Sparkle\(MorphingPhases.start)"] = {
            self.emitterView.removeAllEmitters()
        }
        
        progressClosures["Sparkle\(MorphingPhases.progress)"] = {
            (index: Int, progress: Float, isNewChar: Bool) in
            
            if (!isNewChar) {
                return min(1.0, max(0.0, progress))
            }
            
            let j = Float(sin(Float(index))) * 1.5
            return min(1.0, max(0.0001, progress + self.morphingCharacterDelay * j))
        }
        
        effectClosures["Sparkle\(MorphingPhases.disappear)"] = {
            char, index, progress in
            
            return CharacterLimbo (
                char: char,
                rect: self.previousRects[index],
                alpha: CGFloat(1.0 - progress),
                size: self.font.pointSize,
                drawingProgress: 0.0
            )
        }
        
        effectClosures["Sparkle\(MorphingPhases.appear)"] = {
            char, index, progress in
            
            if (char != " ") 
            {
                let rect = self.newRects[index]
                let emitterPosition = CGPoint(
                    x: rect.origin.x + rect.size.width / 2.0,
                    y: CGFloat(progress) * rect.size.height * 0.9 + rect.origin.y
                )

                self.emitterView.createEmitter("c\(index)", particleName: "Sparkle", duration: self.morphingDuration) 
                { (layer, cell) in
                    layer.emitterSize = CGSize(width: rect.size.width, height: 1)
                    layer.renderMode = kCAEmitterLayerOutline
                    cell.emissionLongitude = CGFloat(Double.pi / 2.0)
                    cell.scale = self.font.pointSize / 300.0
                    cell.scaleSpeed = self.font.pointSize / 300.0 * -1.5
                    cell.color = self.textColor.cgColor
                    cell.birthRate = Float(self.font.pointSize) * Float(arc4random_uniform(7) + 3)
                }.update { (layer, _) in
                    layer.emitterPosition = emitterPosition
                }.play()
            }

            return CharacterLimbo (
                char: char,
                rect: self.newRects[index],
                alpha: CGFloat(self.morphingProgress),
                size: self.font.pointSize,
                drawingProgress: CGFloat(progress)
            )
        }
        
        drawingClosures["Sparkle\(MorphingPhases.draw)"] = {
            (charLimbo: CharacterLimbo) in
            
            if (charLimbo.drawingProgress > 0.0)
            {                
                let (charImage, rect) = self.maskedImageForCharLimbo(charLimbo, withProgress: charLimbo.drawingProgress)
                charImage.draw(in: rect)
                return true
            }
            
            return false
        }
        
        skipFramesClosures["Sparkle\(MorphingPhases.skipFrames)"] = {
            return 1
        }
    }
}
