//
//  GameMessage.swift
//  PongBasic
//
//  Created by Chad on 3/12/20.
//  Copyright © 2020 Chad. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

// This struct will hold the data we will
// pass back & forth between players.
struct GameMessage: Codable
{
    let msgType: String
    let data: CGPoint
    // future fields...
    //let angle: CGFloat
    //let velocity: CGVector
    //let angularVelocity: CGFloat
    //let prevPosition: CGPoint
}
