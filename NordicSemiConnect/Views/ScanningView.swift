//
//  ScanningView.swift
//  NordicSemiConnect
//
//  Created by Ivan Brazhnikov on 11/06/16.
//  Copyright © 2016 Ivan Brazhnikov. All rights reserved.
//

import UIKit

@IBDesignable
public class ScanningView: UIView {
  
  private var scanningRings: [CAShapeLayer]!
  private var displayLink: CADisplayLink!
  
  
  @IBInspectable
  public var minRingRadius: CGFloat = 0 {
    didSet {
      updateState()
    }
  }
  
  
  @IBInspectable
  public var interval: NSTimeInterval = 1 {
    didSet {
      current = current * interval / oldValue
      //updateState()
    }
  }
  
  
  @IBInspectable
  public var ringsColor: UIColor? {
    didSet {
      invalidateAppearance()
    }
  }
  
  
  
  @IBInspectable
  public var ringsStrokeWidth: CGFloat = 1.0 {
    didSet {
      invalidateAppearance()
    }
  }
  
  
  
  @IBInspectable
  public var numberOfRings: Int = 5 {
    didSet {
      invalidateNumberOfRounds()
    }
  }
  
  
  private var lastTimestamp: CFTimeInterval = 0
  
  private var current: NSTimeInterval = 0 {
    didSet {
      if current > interval {
        current -= interval
      }
    }
  }
  
  
  
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    _init()
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    _init()
  }
  
  private func invalidateNumberOfRounds() {
    
    if scanningRings != nil {
      scanningRings.forEach { $0.removeFromSuperlayer() }
    }
    
    let newRings = (0..<numberOfRings).map {[unowned self] _ -> CAShapeLayer in
      let layer = CAShapeLayer()
      layer.fillColor = nil
      layer.anchorPoint = CGPointMake(0.5, 0.5)
      self.layer.addSublayer(layer)
      return layer
      }.reverse()
    scanningRings = Array(newRings)
    invalidateAppearance()
  }
  
  
  private func invalidateAppearance() {
    scanningRings?.forEach {[unowned self] in
      $0.strokeColor = self.ringsColor?.CGColor ?? self.tintColor?.CGColor
      $0.lineWidth = self.ringsStrokeWidth
    }
  }
  
  private func setupRings(@noescape setup: (index: Int, ring: CAShapeLayer) -> Void) {
    scanningRings.enumerate().forEach(setup)
  }
  
  private func _init(){
    invalidateNumberOfRounds()
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    scanningRings?.forEach({[unowned self] (layer: CAShapeLayer) in
      layer.frame = self.bounds
    })
  }
  
  func start() {
    guard displayLink == nil else { return }
    
    displayLink = CADisplayLink(target: self, selector: #selector(tick))
    
    displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
  }
  
  func stop() {
    guard displayLink != nil else { return }
    displayLink.invalidate()
    displayLink = nil
  }
  
  @objc
  private func tick(sender: CADisplayLink) {
    current +=  lastTimestamp != 0 ? sender.timestamp - lastTimestamp : 0
    lastTimestamp = sender.timestamp
    updateState()
  }
  
  private func updateState() {
    let c = scanningRings.count
    let progress = CGFloat(current / interval)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for i in 0..<c {
      let layer = scanningRings[i]
      let scale    = (CGFloat(i)  + progress) / CGFloat(c)
      let width   = minRingRadius + (frame.width - minRingRadius) * scale
      let height  = minRingRadius + (frame.height - minRingRadius) * scale
      let rect = CGRectMake((frame.width - width)/2, (frame.height - height)/2, width, height)
      layer.path = CGPathCreateWithEllipseInRect(rect, nil)
      if i == 0 {
        layer.opacity = Float(progress)
      } else if i == c - 1 {
        layer.opacity = Float(1 - progress)
      }
    }
    CATransaction.commit()
  }
  
}