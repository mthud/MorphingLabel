//
//  MorphingLabel+Burn.swift
//  https://github.com/mthud/MorphingLabel
//

import UIKit

extension MorphingLabel {
    
    fileprivate func burningImageForCharLimbo(_ charLimbo: CharacterLimbo, withProgress progress: CGFloat) -> (UIImage, CGRect) 
    {
        let maskedHeight = charLimbo.rect.size.height * max(0.01, progress)
        let maskedSize = CGSize(width: charLimbo.rect.size.width, height: maskedHeight)
        
        UIGraphicsBeginImageContextWithOptions(maskedSize, false, UIScreen.main.scale)
        let rect = CGRect(x: 0, y: 0, width: charLimbo.rect.size.width, height: maskedHeight)
        
        String(charLimbo.char).draw(in: rect, withAttributes: [
            NSFontAttributeName: self.font,
            NSForegroundColorAttributeName: self.textColor
            ])
            
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let newRect = CGRect(
            x: charLimbo.rect.origin.x,
            y: charLimbo.rect.origin.y,
            width: charLimbo.rect.size.width,
            height: maskedHeight
        )
        return (newImage!, newRect)
    }
    
    func BurnLoad() {
        
        startClosures["Burn\(MorphingPhases.start)"] = {
            self.emitterView.removeAllEmitters()
        }
        
        progressClosures["Burn\(MorphingPhases.progress)"] = {
            index, progress, isNewChar in
            
            if (!isNewChar) {
                return min(1.0, max(0.0, progress))
            }
            
            let j = Float(sin(Float(index))) * 1.5
            return min(1.0, max(0.0001, progress + self.morphingCharacterDelay * j))
            
        }
        
        effectClosures["Burn\(MorphingPhases.disappear)"] = {
            char, index, progress in
            
            return CharacterLimbo (
                char: char,
                rect: self.previousRects[index],
                alpha: CGFloat(1.0 - progress),
                size: self.font.pointSize,
                drawingProgress: 0.0
            )
        }
        
        effectClosures["Burn\(MorphingPhases.appear)"] = {
            char, index, progress in
            
            if (char != " ") {
                let rect = self.newRects[index]
                let emitterPosition = CGPoint(
                    x: rect.origin.x + rect.size.width / 2.0,
                    y: CGFloat(progress) * rect.size.height / 1.2 + rect.origin.y
                )
                
                self.emitterView.createEmitter ("c\(index)", particleName: "Fire", duration: self.morphingDuration) 
                { (layer, cell) in
                    layer.emitterSize = CGSize(width: rect.size.width, height: 1)
                    layer.renderMode = kCAEmitterLayerAdditive
                    layer.emitterMode = kCAEmitterLayerOutline
                    cell.emissionLongitude = CGFloat(Double.pi / 2)
                    cell.scale = self.font.pointSize / 160.0
                    cell.scaleSpeed = self.font.pointSize / 100.0
                    cell.birthRate = Float(self.font.pointSize)
                    cell.emissionLongitude = CGFloat(arc4random_uniform(30))
                    cell.emissionRange = CGFloat(Double.pi / 4)
                    cell.alphaSpeed = self.morphingDuration * -3.0
                    cell.yAcceleration = 10
                    cell.velocity = CGFloat(10 + Int(arc4random_uniform(3)))
                    cell.velocityRange = 10
                    cell.spin = 0
                    cell.spinRange = 0
                    cell.lifetime = self.morphingDuration / 3.0
                }.update { (layer, _) in
                    layer.emitterPosition = emitterPosition
                }.play()
                
                self.emitterView.createEmitter("s\(index)", particleName: "Smoke", duration: self.morphingDuration) 
                { (layer, cell) in
                    layer.emitterSize = CGSize(width: rect.size.width, height: 10)
                    layer.renderMode = kCAEmitterLayerAdditive
                    layer.emitterMode = kCAEmitterLayerVolume
                    cell.emissionLongitude = CGFloat(Double.pi / 2)
                    cell.scale = self.font.pointSize / 40.0
                    cell.scaleSpeed = self.font.pointSize / 100.0
                    cell.birthRate = Float(self.font.pointSize) / Float(arc4random_uniform(10) + 10)
                    cell.emissionLongitude = 0
                    cell.emissionRange = CGFloat(Double.pi / 4)
                    cell.alphaSpeed = self.morphingDuration * -3
                    cell.yAcceleration = -5
                    cell.velocity = CGFloat(20 + Int(arc4random_uniform(15)))
                    cell.velocityRange = 20
                    cell.spin = CGFloat(Float(arc4random_uniform(30)) / 10.0)
                    cell.spinRange = 3
                    cell.lifetime = self.morphingDuration
                }.update { (layer, _) in
                    layer.emitterPosition = emitterPosition
                }.play()
            }
            
            return CharacterLimbo (
                char: char,
                rect: self.newRects[index],
                alpha: 1.0,
                size: self.font.pointSize,
                drawingProgress: CGFloat(progress)
            )
        }
        
        drawingClosures["Burn\(MorphingPhases.draw)"] = {
            (charLimbo: CharacterLimbo) in
            
            if (charLimbo.drawingProgress > 0.0) 
            {                
                let (charImage, rect) = self.burningImageForCharLimbo(charLimbo, withProgress: charLimbo.drawingProgress)
                charImage.draw(in: rect)                
                return true
            }
            
            return false
        }
        
        skipFramesClosures["Burn\(MorphingPhases.skipFrames)"] = {
            return 1
        }
    }
}
