//
//  MorphingLabel.swift
//  https://github.com/mthud/MorphingLabel
//


import Foundation
import UIKit
import QuartzCore

private func < <T : Comparable> (lhs: T?, rhs: T?) -> Bool {
	switch (lhs, rhs) {
  	case let (l?, r?):
    	return l < r
  	case (nil, _?):
    	return true
  	default:
    	return false
  }
}

private func >= <T : Comparable> (lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  	case let (l?, r?):
    	return l >= r
  	default:
    	return !(lhs < rhs)
  }
}

enum MorphingPhases: Int {
    case start, appear, disappear, draw, progress, skipFrames
}

typealias MorphingStartClosure = () -> Void
typealias MorphingEffectClosure = (Character, _ index: Int, _ progress: Float) -> CharacterLimbo
typealias MorphingDrawingClosure = (CharacterLimbo) -> Bool
typealias MorphingManipulateProgressClosure = (_ index: Int, _ progress: Float, _ isNewChar: Bool) -> Float
typealias MorphingSkipFramesClosure = () -> Int

@objc public protocol MorphingLabelDelegate {
    @objc optional func morphingDidStart(_ label: MorphingLabel)
    @objc optional func morphingDidComplete(_ label: MorphingLabel)
    @objc optional func morphingOnProgress(_ label: MorphingLabel, progress: Float)
}

// MARK: - MorphingLabel
@IBDesignable open class MorphingLabel: UILabel {
    
    @IBInspectable open var morphingProgress: Float = 0.0
    @IBInspectable open var morphingDuration: Float = 0.6
    @IBInspectable open var morphingCharacterDelay: Float = 0.026
    @IBInspectable open var morphingEnabled: Bool = true

    @IBOutlet open weak var delegate: MorphingLabelDelegate?
    open var morphingEffect: MorphingEffect = .scale
    
    var startClosures = [String: MorphingStartClosure]()
    var effectClosures = [String: MorphingEffectClosure]()
    var drawingClosures = [String: MorphingDrawingClosure]()
    var progressClosures = [String: MorphingManipulateProgressClosure]()
    var skipFramesClosures = [String: MorphingSkipFramesClosure]()
    var diffResults: StringDiffResult?
    var previousText = ""
    
    var currentFrame = 0
    var totalFrames = 0
    var totalDelayFrames = 0
    
    var totalWidth: Float = 0.0
    var previousRects = [CGRect]()
    var newRects = [CGRect]()
    var charHeight: CGFloat = 0.0
    var skipFramesCount: Int = 0
    
    #if TARGET_INTERFACE_BUILDER
    let presentingInIB = true
    #else
    let presentingInIB = false
    #endif
    
    override open var font: UIFont! {
        get {
            return super.font ?? UIFont.systemFont(ofSize: 15)
        }
        set {
            super.font = newValue
            setNeedsLayout()
        }
    }
    
    override open var text: String! {
        get {
            return super.text ?? ""
        }
        set {
            guard text != newValue else { return }

            previousText = text ?? ""
            diffResults = previousText.diffWith(newValue)
            super.text = newValue ?? ""
            
            morphingProgress = 0.0
            currentFrame = 0
            totalFrames = 0
            
            setNeedsLayout()
            
            if !morphingEnabled {
                return
            }
            
            if presentingInIB {
                morphingDuration = 0.01
                morphingProgress = 0.5
            } else if previousText != text {
                displayLink.isPaused = false
                let closureKey = "\(morphingEffect.description)\(MorphingPhases.start)"
                if let closure = startClosures[closureKey] {
                    return closure()
                }
                
                delegate?.morphingDidStart?(self)
            }
        }
    }
    
    open override func setNeedsLayout() {
        super.setNeedsLayout()
        previousRects = rectsOfEachCharacter(previousText, withFont: font)
        newRects = rectsOfEachCharacter(text ?? "", withFont: font)
    }
    
    override open var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            setNeedsLayout()
        }
    }
    
    override open var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            setNeedsLayout()
        }
    }
    
    fileprivate lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(MorphingLabel.displayFrameTick))
        displayLink.add(to: .current, forMode: .commonModes)
        return displayLink
    } ()

    deinit {
        displayLink.remove(from: .current, forMode: .commonModes)
        displayLink.invalidate()
    }
    
    lazy var emitterView: EmitterView = {
        let emitterView = EmitterView(frame: self.bounds)
        self.addSubview(emitterView)
        return emitterView
    }()
}

// MARK: - Animation extension
extension MorphingLabel {

    func displayFrameTick() {
        if displayLink.duration > 0.0 && totalFrames == 0 {
            var frameRate = Float(0)
            if #available(iOS 10.0, tvOS 10.0, *) {
                var frameInterval = 1
                if displayLink.preferredFramesPerSecond == 60 {
                    frameInterval = 1
                } else if displayLink.preferredFramesPerSecond == 30 {
                    frameInterval = 2
                } else {
                    frameInterval = 1
                }
                frameRate = Float(displayLink.duration) / Float(frameInterval)
            } else {
                frameRate = Float(displayLink.duration) / Float(displayLink.frameInterval)
            }
            totalFrames = Int(ceil(morphingDuration / frameRate))

            let totalDelay = Float((text!).characters.count) * morphingCharacterDelay
            totalDelayFrames = Int(ceil(totalDelay / frameRate))
        }

        currentFrame += 1

        if previousText != text && currentFrame < totalFrames + totalDelayFrames + 5 {
            morphingProgress += 1.0 / Float(totalFrames)

            let closureKey = "\(morphingEffect.description)\(MorphingPhases.skipFrames)"
            if let closure = skipFramesClosures[closureKey] {
                skipFramesCount += 1
                if skipFramesCount > closure() {
                    skipFramesCount = 0
                    setNeedsDisplay()
                }
            } else {
                setNeedsDisplay()
            }

            if let onProgress = delegate?.morphingOnProgress {
                onProgress(self, morphingProgress)
            }
        } else {
            displayLink.isPaused = true
            delegate?.morphingDidComplete?(self)
        }
    }
    
    // Could be enhanced by kerning text:
    // http://stackoverflow.com/questions/21443625/core-text-calculate-letter-frame-in-ios
    func rectsOfEachCharacter(_ textToDraw: String, withFont font: UIFont) -> [CGRect] 
		{
        var charRects = [CGRect]()
        var leftOffset: CGFloat = 0.0
        
        charHeight = "Leg".size(attributes: [NSFontAttributeName: font]).height
        
        let topOffset = (bounds.size.height - charHeight) / 2.0

        for char in textToDraw.characters {
            let charSize = String(char).size(attributes: [NSFontAttributeName: font])
            charRects.append(
                CGRect(
                    origin: CGPoint(x: leftOffset, y: topOffset),
                    size: charSize
                )
            )
            leftOffset += charSize.width
        }
        
        totalWidth = Float(leftOffset)
        
        var stringLeftOffSet: CGFloat = 0.0
        
        switch textAlignment {
        case .center:
            stringLeftOffSet = CGFloat((Float(bounds.size.width) - totalWidth) / 2.0)
        case .right:
            stringLeftOffSet = CGFloat(Float(bounds.size.width) - totalWidth)
        default:
            ()
        }
        
        var offsetedCharRects = [CGRect]()
        
        for r in charRects {
            offsetedCharRects.append(r.offsetBy(dx: stringLeftOffSet, dy: 0.0))
        }
        
        return offsetedCharRects
    }
    
    func limboOfOriginalCharacter(_ char: Character, index: Int, progress: Float) -> CharacterLimbo 
		{
				var currentRect = previousRects[index]
        let oriX = Float(currentRect.origin.x)
        var newX = Float(currentRect.origin.x)
        let diffResult = diffResults!.0[index]
        var currentFontSize: CGFloat = font.pointSize
        var currentAlpha: CGFloat = 1.0
            
        switch diffResult {
                // Move the character that exists in the new text to current position
            case .same:
                newX = Float(newRects[index].origin.x)
                currentRect.origin.x = CGFloat( Easing.easeOutQuint(progress, oriX, newX - oriX) )
            case .move(let offset):
                newX = Float(newRects[index + offset].origin.x)
                currentRect.origin.x = CGFloat( Easing.easeOutQuint(progress, oriX, newX - oriX) )
            case .moveAndAdd(let offset):
                newX = Float(newRects[index + offset].origin.x)
                currentRect.origin.x = CGFloat( Easing.easeOutQuint(progress, oriX, newX - oriX) )
            default:
                // Otherwise, remove it
                
                // Override morphing effect with closure in extenstions
                if let closure = effectClosures["\(morphingEffect.description)\(MorphingPhases.disappear)"] {
                        return closure(char, index, progress)
                } else {
                    // And scale it by default
                    let fontEase = CGFloat( Easing.easeOutQuint(progress, 0, Float(font.pointSize)) )
                    // For emojis
                    currentFontSize = max(0.0001, font.pointSize - fontEase)
                    currentAlpha = CGFloat(1.0 - progress)
                    currentRect = previousRects[index].offsetBy(dx: 0, dy: CGFloat(font.pointSize - currentFontSize)
                    )
                }
            }
            
            return CharacterLimbo (
                char: char,
                rect: currentRect,
                alpha: currentAlpha,
                size: currentFontSize,
                drawingProgress: 0.0
            )
    }
    
    func limboOfNewCharacter(_ char: Character, index: Int, progress: Float) -> CharacterLimbo 
		{
				let currentRect = newRects[index]
        var currentFontSize = CGFloat( Easing.easeOutQuint(progress, 0, Float(font.pointSize)) )
        
        if let closure = effectClosures["\(morphingEffect.description)\(MorphingPhases.appear)"] 
				{
						return closure(char, index, progress)
        } else {
        		currentFontSize = CGFloat( Easing.easeOutQuint(progress, 0.0, Float(font.pointSize)) )
                // For emojis
                currentFontSize = max(0.0001, currentFontSize)
                
                let yOffset = CGFloat(font.pointSize - currentFontSize)
                
                return CharacterLimbo (
                    char: char,
                    rect: currentRect.offsetBy(dx: 0, dy: yOffset),
                    alpha: CGFloat(morphingProgress),
                    size: currentFontSize,
                    drawingProgress: 0.0
                )
        }
    }
    
    func limboOfCharacters() -> [CharacterLimbo] 
		{
        var limbo = [CharacterLimbo] ()
        
        // Iterate original characters
        for (i, character) in previousText.characters.enumerated() {
            var progress: Float = 0.0
            
            if let closure = progressClosures["\(morphingEffect.description)\(MorphingPhases.progress)"] {
            		progress = closure(i, morphingProgress, false)
            } else {
                progress = min(1.0, max(0.0, morphingProgress + morphingCharacterDelay * Float(i)))
            }
            
            let limboOfCharacter = limboOfOriginalCharacter(character, index: i, progress: progress)
            limbo.append(limboOfCharacter)
        }
        
        // Add new characters
        for (i, character) in (text!).characters.enumerated() {
            if i >= diffResults?.0.count {
                break
            }
            
            var progress: Float = 0.0
            
            if let closure = progressClosures["\(morphingEffect.description)\(MorphingPhases.progress)"] {
                progress = closure(i, morphingProgress, true)
            } else {
                progress = min(1.0, max(0.0, morphingProgress - morphingCharacterDelay * Float(i)))
            }
            
            // Don't draw character that already exists
            if diffResults?.skipDrawingResults[i] == true {
                continue
            }
            
            if let diffResult = diffResults?.0[i] {
                switch diffResult {
                case .moveAndAdd, .replace, .add, .delete:
                    let limboOfCharacter = limboOfNewCharacter(character, index: i, progress: progress)
                    limbo.append(limboOfCharacter)
                default:
                    ()
                }
            }
        }
        
        return limbo
    }

}

// MARK: - Drawing extension
extension MorphingLabel {
    
    override open func didMoveToSuperview() {
        if let s = text {
            text = s
        }
        
        // Load all morphing effects
        for effectName: String in MorphingEffect.allValues {
            let effectFunc = Selector("\(effectName)Load")
            if responds(to: effectFunc) {
                perform(effectFunc)
            }
        }
    }
    
    override open func drawText(in rect: CGRect) {
        if !morphingEnabled || limboOfCharacters().count == 0 {
            super.drawText(in: rect)
            return
        }
        
        for charLimbo in limboOfCharacters() {
            let charRect = charLimbo.rect
            
            let willAvoidDefaultDrawing: Bool = {
                if let closure = drawingClosures["\(morphingEffect.description)\(MorphingPhases.draw)"] {
                		return closure($0)
                }
                return false
            } (charLimbo)

            if !willAvoidDefaultDrawing {
                var attrs: [String: Any] = [NSForegroundColorAttributeName: textColor.withAlphaComponent(charLimbo.alpha)]

                if let font = UIFont(name: font.fontName, size: charLimbo.size) {
                    attrs[NSFontAttributeName] = font
                }
                let s = String(charLimbo.char)
                s.draw(in: charRect, withAttributes: attrs)
            }
        }
    }
}
