// Created by Cal Stephens on 12/21/21.
// Copyright © 2021 Airbnb Inc. All rights reserved.

import QuartzCore

extension CAShapeLayer {
  /// Adds animations for the given `Rectangle` to this `CALayer`
  @nonobjc
  func addAnimations(
    for rectangle: Rectangle,
    context: LayerAnimationContext,
    pathMultiplier: PathMultiplier,
    roundedCorners: RoundedCorners?)
    throws
  {
    let combinedKeyframes = try rectangle.combinedKeyframes(
      context: context,
      roundedCorners: roundedCorners)

    try addAnimation(
      for: .path,
      keyframes: combinedKeyframes.keyframes,
      value: { keyframe in
        BezierPath.rectangle(
          position: keyframe.position.pointValue,
          size: keyframe.size.sizeValue,
          cornerRadius: keyframe.cornerRadius.cgFloatValue,
          direction: rectangle.direction)
          .cgPath()
          .duplicated(times: pathMultiplier)
      },
      context: context)
  }
}

extension Rectangle {
  /// Data that represents how to render a rectangle at a specific point in time
  struct Keyframe {
    let size: LottieVector3D
    let position: LottieVector3D
    let cornerRadius: LottieVector1D
  }

  /// Creates a single array of animatable keyframes from the separate arrays of keyframes in this Rectangle
  func combinedKeyframes(
    context: LayerAnimationContext,
    roundedCorners: RoundedCorners?) throws
    -> KeyframeGroup<Rectangle.Keyframe>
  {
    let cornerRadius = roundedCorners?.radius ?? cornerRadius
    let combinedKeyframes = Keyframes.combinedIfPossible(
      size, position, cornerRadius,
      makeCombinedResult: Rectangle.Keyframe.init)

    if let combinedKeyframes = combinedKeyframes {
      return combinedKeyframes
    } else {
      // If we weren't able to combine all of the keyframes, we have to take the timing values
      // from one property and use a fixed value for the other properties.
      return try size.map { sizeValue in
        Keyframe(
          size: sizeValue,
          position: try position.exactlyOneKeyframe(context: context, description: "rectangle position"),
          cornerRadius: try cornerRadius.exactlyOneKeyframe(context: context, description: "rectangle cornerRadius"))
      }
    }
  }
}
