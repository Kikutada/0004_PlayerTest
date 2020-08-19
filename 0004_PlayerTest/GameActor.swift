//
//  GameActor.swift
//  0004_PlayerTest
//
//  Created by Kikutada on 2020/08/17.
//  Copyright © 2020 Kikutada All rights reserved.
//

import Foundation
import UIKit

//
//  EnDirection列挙型
//      キャラクターが動く方向を列挙
//
enum EnDirection: Int {
    case None = -2
    case Stop   = -1
    case Right  = 0
    case Left   = 1
    case Up     = 2
    case Down   = 3

    func getHorizaontalDelta() -> Int {
        switch self {
        case .None:     return 0
        case .Stop:     return 0
        case .Up:       return 0
        case .Down:     return 0
        case .Left:     return -1
        case .Right:    return +1
        }
    }
    
    func getVerticalDelta() -> Int {
        switch self {
        case .None:     return 0
        case .Stop:     return 0
        case .Up:       return +1
        case .Down:     return -1
        case .Left:     return 0
        case .Right:    return 0
        }
    }
    
    func getReverse() -> EnDirection {
        switch self {
        case .None:     return .None
        case .Stop:     return .Stop
        case .Up:       return .Down
        case .Down:     return .Up
        case .Left:     return .Right
        case .Right:    return .Left
        }
    }
    
    func getRandom() -> EnDirection {
        switch Int.random(in: 1..<5) {
        case 1: return .Up
        case 2: return .Down
        case 3: return .Left
        case 4: return .Right
        default: return .Stop
        }
    }
    
    func getClockwise() -> EnDirection {
        switch self {
        case .None:     return .None
        case .Stop:     return .Stop
        case .Up:       return .Right
        case .Down:     return .Left
        case .Left:     return .Up
        case .Right:    return .Down
        }
    }
    
    func getCounterClockwise() -> EnDirection {
        switch self {
        case .None:     return .None
        case .Stop:     return .Stop
        case .Up:       return .Left
        case .Down:     return .Right
        case .Left:     return .Down
        case .Right:    return .Up
        }
    }
}


class CgDirection {
    var currentDirection: EnDirection = .None
    var nextDirection: EnDirection = .None
    
    func reset() {
        currentDirection = .Stop
        nextDirection = .Stop
    }

    func get() -> EnDirection {
        return currentDirection
    }

    func getNext() -> EnDirection {
        return nextDirection
    }

    func set(to direction: EnDirection) {
        if currentDirection == .Stop {
            currentDirection = direction
            nextDirection = .Stop
        } else {
            nextDirection = direction
        }
    }
    
    func update() {
        if nextDirection != .Stop {
            currentDirection = nextDirection
        }
    }

    func isChanging() -> Bool {
        return ( currentDirection != nextDirection )
    }
}




class CgPosition {

    let CG_X_ORIGIN: Int = -4
    let CG_Y_ORIGIN: Int = -4

    let SPEED_UNIT: Int = 16

    var row: Int = 0, column: Int = 0
    var dx:  Int = 0, dy: Int = 0
    var dxf: Int = 0, dyf: Int = 0
    
    var x: CGFloat {
        get {
            return CGFloat(column * MAZE_UNIT + dx - CG_X_ORIGIN)
        }
        set {
            column = (Int(newValue) + CG_X_ORIGIN) / MAZE_UNIT
            dx     = (Int(newValue) + CG_X_ORIGIN) % MAZE_UNIT
            dxf    = 0
        }
    }

    var y: CGFloat {
        get {
            return CGFloat(row * 8 + dy - CG_Y_ORIGIN)
        }
        set {
            row = (Int(newValue) + CG_Y_ORIGIN) / MAZE_UNIT
            dy  = (Int(newValue) + CG_Y_ORIGIN) % MAZE_UNIT
            dyf = 0
        }
    }

    init() {
        self.set(column: 0, row: 0)
    }

    func set(column: Int, row: Int, dx: Int = 0, dy: Int = 0) {
        self.column = column
        self.row = row
        self.dx = dx
        self.dy = dy
        self.dxf = 0
        self.dyf = 0
    }

    func canMove(to direction: EnDirection)->Bool {
        return ( (direction == .Left || direction == .Right) && (dy == 0) ||
                 (direction ==   .Up || direction ==  .Down) && (dx == 0) )
    }

    func getAbsoluteDelta(to direction: EnDirection) -> Int {
        let delta: Int
        switch direction {
            case .Right: delta = dx > 0 ? dx : 0
            case .Left:  delta = dx < 0 ? -dx : 0
            case .Up:    delta = dy > 0 ? dy : 0
            case .Down:  delta = dy < 0 ? -dy : 0
            default:     delta = 0
        }
        return abs(delta)
    }

    func roundDown(to direction: EnDirection) {
        switch direction {
            case .Right: dxf = 0
            case .Left:  dxf = 0
            case .Up:    dyf = 0
            case .Down:  dyf = 0
            default:     break
        }
    }

    /// Move every 1dot at a time until speed becomes 0.
    /// - Parameters:
    ///   - direction: <#direction description#>
    ///   - speed: <#speed description#>
    /// - Returns: <#description#>
    func move(to direction: EnDirection, speed: Int = 0) -> Int {

        var remainingSpeed: Int = 0
        var amountOfMovement: Int

        if speed >= SPEED_UNIT {
            amountOfMovement = SPEED_UNIT
            remainingSpeed = speed - SPEED_UNIT
        } else {
            amountOfMovement = speed
            remainingSpeed = 0
        }

        switch direction {
            case .Left:
                dxf -= amountOfMovement
                if dxf <= -SPEED_UNIT {
                    dxf += SPEED_UNIT
                    decrementHorizontal()
            }
            case .Right:
                dxf += amountOfMovement
                if dxf >= SPEED_UNIT {
                    dxf -= SPEED_UNIT
                    incrementHorizontal()
                }
            case .Down:
                dyf -= amountOfMovement
                if dyf <= -SPEED_UNIT {
                    dyf += SPEED_UNIT
                    decrementVertical()
                }
            case .Up:
                dyf += amountOfMovement
                if dyf >= SPEED_UNIT {
                    dyf -= SPEED_UNIT
                    incrementVertical()
                }

            case .Stop: fallthrough
            default:
                dxf = 0
                dyf = 0
        }
        
        return remainingSpeed
    }

    private func incrementHorizontal(value: Int = 1) {
        dx += value
        if dx >= MAZE_UNIT {
            column += 1
            dx = 0
            if column >= BG_WIDTH {  // warp tunnel
                column = 0
            }
        }
    }

    private func decrementHorizontal(value: Int = 1) {
        dx -= value
        if dx <= -MAZE_UNIT {
            column -= 1
            dx = 0
            if column < 0 {  // warp tunnel
                column = BG_WIDTH-1
            }
        }
    }

    private func incrementVertical(value: Int = 1) {
        dy += value
        if dy >= MAZE_UNIT {
            row += 1
            dy = 0
            if row >= BG_HEIGHT {  // warp tunnel
                row = 0
            }
        }
    }

    private func decrementVertical(value: Int = 1) {
        dy -= value
        if dy <= -MAZE_UNIT {
            row -= 1
            dy = 0
            if row < 0 {  // warp tunnel
                row = BG_HEIGHT-1
            }
        }
    }

}

//------------------------------------------------------------

class CgActor: CbContainer {

    enum EnActor: Int {
        case None = -2
        case Pacman = -1
        case Blinky = 0
        case Pinky = 1
        case Inky = 2
        case Clyde = 3
        case SpecialTarget = 4

        func getSpriteNumber() -> Int {
            switch self {
                case .None: return 0
                case .Pacman: return 9
                case .Blinky: return 13
                case .Pinky: return 14
                case .Inky: return 15
                case .Clyde: return 16
                case .SpecialTarget: return 7
            }
        }

        func getDepth() -> CGFloat {
            switch self {
                case .None: return 0
                case .Pacman: return 10
                case .Blinky: return 23
                case .Pinky: return 22
                case .Inky: return 21
                case .Clyde: return 20
                case .SpecialTarget: return 1
            }
        }
    }

    var sprite: CgSpriteManager!
    var deligateActor: ActorDeligate!

    var position: CgPosition = CgPosition()
    var direction: CgDirection = CgDirection()
    
    var actor: EnActor = .None
    var sprite_number: Int = 0
    
    let speedUnit: Int = 16
    private var speedTotal: Int = 0
    private var speed: Int = 0
    
    init(object: CgSceneFrame, deligateActor: ActorDeligate) {
        super.init(binding: object)
        self.sprite = object.sprite
        self.deligateActor = deligateActor
    }

    func reset() {
        enabled = false
        speedTotal = 0
        sprite.setDepth(sprite_number, zPosition: actor.getDepth())
    }
    
    func start() {
        enabled = true
    }

    func stop() {
        enabled = false
    }

    func setSpeed(speed: Int) {
        self.speed = speed
    }

    func calculateSpeed() -> Int {
        speedTotal += speed
        let result = speedTotal / speedUnit
        speedTotal = speedTotal % speedUnit
        return result
    }


    func canMove(direction: EnDirection, oneWayProhibition: Bool = true) -> Bool {
        var can = true
        if position.canMove(to: direction) {
            let road = deligateActor.getTileAttribute(to: direction, column: position.column,row: position.row)
            
            if (road == .Wall) {
                can = false
            } else if oneWayProhibition && (road == .Oneway && direction == .Up) {
                can = false
            }
        } else {
            can = false
        }
        return can
    }

}

