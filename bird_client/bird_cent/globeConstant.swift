//
//  globeConstant.swift
//  bird_cent
//
//  Created by gray on 2018/8/12.
//  Copyright © 2018年 gray. All rights reserved.
//

import SpriteKit
import GameplayKit

let wide:CGFloat = 512
let high:CGFloat = 909
let halfWide = wide/2
let halfHigh = high/2

let birdC: UInt32 = 1 << 0
let worldC: UInt32 = 1 << 1
let sharpC: UInt32 = 1 << 2
let scoreC: UInt32 = 1 << 3

let skyTexture = SKTexture(imageNamed: "bg_day")
let groundTexture = SKTexture(imageNamed: "land")
let birdATexture1 = SKTexture(imageNamed: "bird0_0")
let birdATexture2 = SKTexture(imageNamed: "bird0_1")
let birdATexture3 = SKTexture(imageNamed: "bird0_2")
let birdBTexture1 = SKTexture(imageNamed: "bird1_0")
let birdBTexture2 = SKTexture(imageNamed: "bird1_1")
let birdBTexture3 = SKTexture(imageNamed: "bird1_2")
let pipeDown = SKTexture(imageNamed: "pipe_down")
let pipeUp = SKTexture(imageNamed: "pipe_up")
let sharpTexture = SKTexture(imageNamed:"backsharp")

let groundHeight = groundTexture.size().height
let force = high/16

class globeConstant {

}
