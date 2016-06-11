//
//  GravityView.swift
//  NordicSemiConnect
//
//  Created by Ivan Brazhnikov on 12/06/16.
//  Copyright © 2016 Ivan Brazhnikov. All rights reserved.
//

import UIKit

@IBDesignable
class GravityView: UIView {

  @IBInspectable
  var progress: CGFloat = 1 {
    didSet {
      invalidateGravityLayerPosition()
    }
  }
  
  
  @IBInspectable
  var startColor: UIColor = .redColor() {
    didSet {
      invalidateGravityLayerAppearance()
    }
  }
  
  @IBInspectable
  var mediumColor: UIColor = .orangeColor() {
    didSet {
      invalidateGravityLayerAppearance()
    }
  }
  
  @IBInspectable
  var endColor: UIColor = .greenColor() {
    didSet {
      invalidateGravityLayerAppearance()
    }
  }
  
  @IBInspectable
  var animationDuration: Double = 0
  
  
  override var tintColor: UIColor! {
    didSet {
      invalidateGravityLayerAppearance()
    }
  }
  
 
  
  
  private var gravityLayer: CAShapeLayer!
  private var gradientLayer: CAGradientLayer!
  
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    _init()
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    _init()
  }
  
  
  
  private func _init() {
    
    
    let gradient = CAGradientLayer()
    gradient.colors = [UIColor.greenColor(), UIColor.blueColor(), UIColor.redColor()].map { $0.CGColor }
    gradient.locations = [0, 0.5, 1.0]
    layer.addSublayer(gradient)
    gradientLayer = gradient
    
    let gl = CAShapeLayer()
    layer.addSublayer(gl)
    gravityLayer = gl
    
    gradient.mask = gl
    
    invalidateGravityLayerAppearance()
    invalidateGravityLayerPosition()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    gravityLayer.frame = bounds
    gradientLayer.frame = bounds
    invalidateGravityLayerPosition()
  }
  
  private func invalidateGravityLayerAppearance() {
    //gravityLayer.fillColor = (normalColor ?? tintColor)?.CGColor
    gradientLayer.colors = [startColor, mediumColor, endColor].map { $0.CGColor }
  }
  
  private func invalidateGravityLayerPosition() {
    CATransaction.begin()
    if animationDuration <= 0 {
      CATransaction.setDisableActions(true)
    } else {
      CATransaction.setAnimationDuration(animationDuration)
    }
    gravityLayer.path = CGPathCreateWithRect(CGRectMake(0, (1 - progress) * frame.height, frame.width, progress * frame.height), nil)
    CATransaction.commit()
  }
  

}

extension CAShapeLayer {
  public override func actionForKey(event: String) -> CAAction? {
    if (event == "path") {
      let a = CABasicAnimation(keyPath: event)
      a.duration = CATransaction.animationDuration()
      a.timingFunction = CATransaction.animationTimingFunction()
      return a
    }
    return super.actionForKey(event)
  }
}
