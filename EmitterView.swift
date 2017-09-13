//
//  EmitterView.swift
//  https://github.com/mthud/MorphingLabel
//

import UIKit

private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool 
{
    switch (lhs, rhs) 
    {
        case let (l?, r?):
            return l < r
        case (nil, _?):
            return true
        default:
            return false
    }
}

private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool 
{
    switch (lhs, rhs) 
    {
        case let (l?, r?):
            return l > r
        default:
            return rhs < lhs
    }
}

public struct Emitter {
    
    let layer: CAEmitterLayer = {
        let layer = CAEmitterLayer()
        layer.emitterPosition = CGPoint(x: 10, y: 10)
        layer.emitterSize = CGSize(width: 10, height: 1)
        layer.renderMode = kCAEmitterLayerOutline
        layer.emitterShape = kCAEmitterLayerLine
        return layer
    }()
    
    let cell: CAEmitterCell = {
        let cell = CAEmitterCell()
        cell.name = "sparkle"
        cell.birthRate = 150.0
        cell.velocity = 50.0
        cell.velocityRange = -80.0
        cell.lifetime = 0.16
        cell.lifetimeRange = 0.1
        cell.emissionLongitude = CGFloat(Double.pi / 2 * 2.0)
        cell.emissionRange = CGFloat(Double.pi / 2 * 2.0)
        cell.scale = 0.1
        cell.yAcceleration = 100
        cell.scaleSpeed = -0.06
        cell.scaleRange = 0.1
        return cell
    }()
    
    public var duration: Float = 0.6
    
    init(name: String, particleName: String, duration: Float) 
    {
        cell.name = name
        self.duration = duration
        var image: UIImage?
        defer {
            cell.contents = image?.cgImage
        }

        image = UIImage(named: particleName)

        if (image != nil) {
            return
        }
        // Load from Framework
        image = UIImage(named: particleName, in: Bundle(for: MorphingLabel.self), compatibleWith: nil)
    }
    
    public func play()
    {
        if (layer.emitterCells?.count > 0) {
            return
        }
        
        layer.emitterCells = [cell]
        let d = DispatchTime.now() + Double(Int64(duration * Float(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: d) {
            self.layer.birthRate = 0.0
        }
    }
    
    public func stop() 
    {
        if (nil != layer.superlayer) {
            layer.removeFromSuperlayer()
        }
    }
    
    func update(_ configureClosure: EmitterConfigureClosure? = .none) -> Emitter 
    {
        configureClosure?(layer, cell)
        return self
    }
}

public typealias EmitterConfigureClosure = (CAEmitterLayer, CAEmitterCell) -> Void

open class EmitterView: UIView {
    
    open lazy var emitters: [String: Emitter] = {
        var _emitters = [String: Emitter]()
        return _emitters
    }()
    
    open func createEmitter(_ name: String, particleName: String, duration: Float, configureClosure: EmitterConfigureClosure?) -> Emitter 
    {
        var emitter: Emitter
        if let e = emitterByName(name) {
            emitter = e
        } else {
            emitter = Emitter(name: name, particleName: particleName, duration: duration)
            configureClosure?(emitter.layer, emitter.cell)
            layer.addSublayer(emitter.layer)
            emitters.updateValue(emitter, forKey: name)
        }
        return emitter
    }
    
    open func emitterByName(_ name: String) -> Emitter? 
    {
        if (let e = emitters[name]) {
            return e
        }
        return Optional.none
    }
    
    open func removeAllEmitters() 
    {
        for (_, emitter) in emitters {
            emitter.layer.removeFromSuperlayer()
        }
        emitters.removeAll(keepingCapacity: false)
    }
}
