//
//  LayerTransformPropertyMap.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 2/4/19.
//

import Foundation
import CoreGraphics
import QuartzCore

final class LayerTransformProperties: NodePropertyMap, KeypathSearchable {
  
  init(transform: Transform) {
    
    self.anchor = NodeProperty(provider: KeyframeInterpolator(keyframes: transform.anchorPoint.keyframes))
    self.scale = NodeProperty(provider: KeyframeInterpolator(keyframes: transform.scale.keyframes))
    self.rotationX = NodeProperty(provider: KeyframeInterpolator(keyframes: transform.rotationX.keyframes))
    self.rotationY = NodeProperty(provider: KeyframeInterpolator(keyframes: transform.rotationY.keyframes))
    self.rotationZ = NodeProperty(provider: KeyframeInterpolator(keyframes: transform.rotationZ.keyframes))
    self.opacity = NodeProperty(provider: KeyframeInterpolator(keyframes: transform.opacity.keyframes))
    self.orientation = NodeProperty(provider: KeyframeInterpolator(keyframes: transform.orientation.keyframes))
    
    var propertyMap: [String: AnyNodeProperty] = [
      "Anchor Point" : anchor,
      "Scale" : scale,
      "RotationX" : rotationX,
      "RotationY" : rotationY,
      "RotationZ" : rotationZ,
      "Opacity" : opacity,
      "Orientation" : orientation
    ]
    
    if let positionKeyframes = transform.position?.keyframes {
      let position: NodeProperty<Vector3D> = NodeProperty(provider: KeyframeInterpolator(keyframes: positionKeyframes))
      propertyMap["Position"] = position
      self.position = position
      self.positionX = nil
      self.positionY = nil
    } else if let positionKeyframesX = transform.positionX?.keyframes,
      let positionKeyframesY = transform.positionY?.keyframes {
      let xPosition: NodeProperty<Vector1D> = NodeProperty(provider: KeyframeInterpolator(keyframes: positionKeyframesX))
      let yPosition: NodeProperty<Vector1D> = NodeProperty(provider: KeyframeInterpolator(keyframes: positionKeyframesY))
      propertyMap["X Position"] = xPosition
      propertyMap["Y Position"] = yPosition
      self.positionX = xPosition
      self.positionY = yPosition
      self.position = nil
    } else {
      self.position = nil
      self.positionY = nil
      self.positionX = nil
    }
    
    self.keypathProperties = propertyMap
    self.properties = Array(propertyMap.values)
  }
  
  let keypathProperties: [String : AnyNodeProperty]
  var keypathName: String = "Transform"
  
  var childKeypaths: [KeypathSearchable] {
    return []
  }
  
  let properties: [AnyNodeProperty]
  
  let anchor: NodeProperty<Vector3D>
  let scale: NodeProperty<Vector3D>
  let rotationX: NodeProperty<Vector1D>
  let rotationY: NodeProperty<Vector1D>
  let rotationZ: NodeProperty<Vector1D>
  let position: NodeProperty<Vector3D>?
  let positionX: NodeProperty<Vector1D>?
  let positionY: NodeProperty<Vector1D>?
  let opacity: NodeProperty<Vector1D>
  let orientation: NodeProperty<Vector3D>
  
}

class LayerTransformNode: AnimatorNode {
  let outputNode: NodeOutput = PassThroughOutputNode(parent: nil)
  
  init(transform: Transform) {
    self.transformProperties = LayerTransformProperties(transform: transform)
  }
  
  let transformProperties: LayerTransformProperties
  
  // MARK: Animator Node Protocol
  
  var propertyMap: NodePropertyMap & KeypathSearchable {
    return transformProperties
  }
  
  var parentNode: AnimatorNode?
  var hasLocalUpdates: Bool = false
  var hasUpstreamUpdates: Bool = false
  var lastUpdateFrame: CGFloat? = nil
  var isEnabled: Bool = true
  
  func shouldRebuildOutputs(frame: CGFloat) -> Bool {
    return hasLocalUpdates || hasUpstreamUpdates
  }
  
  func rebuildOutputs(frame: CGFloat) {
    opacity = Float(transformProperties.opacity.value.cgFloatValue) * 0.01
    
    let position: Point3D
    if let point = transformProperties.position?.value.pointValue {
      position = point
    } else if let xPos = transformProperties.positionX?.value.cgFloatValue,
      let yPos = transformProperties.positionY?.value.cgFloatValue {
      position = Point3D(x: xPos, y: yPos, z: 0)
    } else {
      position = .zero
    }
    
    transformProperties.rotationZ.update(frame: frame)
    transformProperties.rotationX.update(frame: frame)
    transformProperties.rotationY.update(frame: frame)
    
    let orientation = transformProperties.orientation
    orientation.update(frame: frame)
    
    let rotationX = transformProperties.rotationX.value.cgFloatValue + CGFloat(orientation.value.x)
    let rotationY = transformProperties.rotationY.value.cgFloatValue + CGFloat(orientation.value.y)
    let rotationZ = transformProperties.rotationZ.value.cgFloatValue + CGFloat(orientation.value.z)
    
    localTransform = CATransform3D.makeTransform(anchor: transformProperties.anchor.value.pointValue,
                                                 position: position,
                                                 scale: transformProperties.scale.value.pointValue,
                                                 rotation: (rotationX, rotationY,
                                                            rotationZ),
                                                 skew: nil,
                                                 skewAxis: nil)
    
    if let parentNode = parentNode as? LayerTransformNode {
      globalTransform = CATransform3DConcat(localTransform, parentNode.globalTransform)
    } else {
      globalTransform = localTransform
    }
  }
  
  var opacity: Float = 1
  var localTransform: CATransform3D = CATransform3DIdentity
  var globalTransform: CATransform3D = CATransform3DIdentity
  
}
