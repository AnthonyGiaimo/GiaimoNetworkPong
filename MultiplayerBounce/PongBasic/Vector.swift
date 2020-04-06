//
//  Vector.swift
//  PongBasic
//
//  Created by Chad on 3/12/20.
//  Copyright © 2020 Chad. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import CoreMotion

// Some operator overloads to deal with GCPoint vector math
//Go here for more info on simple vector math: https://www.mathsisfun.com/algebra/vectors.html
public func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

public func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

public func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

// No need to worry about this -
// This is a precompiler directive to tweak the
// sqrt function according to the processor/platform.
// Some older 32-bit devices (like anything older than 5S) cannot
// handle 64-bit Float types.
#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif



// add some vector functionality to the CGPoint class...
public extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
    
    func directionOf()->CGPoint
    {
        return normalized()
    }
    
    // Returns angle between self and another point
    func angleBetween(point: CGPoint)->CGFloat
    {
        return  atan2(self.y - point.y, self.x - point.x)
    }
    
    // Returns angle between points p1 and p2
    static func angleBetween (p1: CGPoint, p2: CGPoint)->CGFloat
    {
        return  atan2(p1.y - p2.y, p1.x - p2.x)
    }
}
