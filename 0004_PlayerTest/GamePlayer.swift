//
//  GamePlayer.swift
//  0004_PlayerTest
//
//  Created by Kikutada on 2020/08/17.
//  Copyright © 2020 Kikutada All rights reserved.
//

import Foundation
import UIKit

// init
// reset
// start
// stop
// update

class CgPlayer : CgActor {

    enum EnPlayerAction: Int {
        case Stopping, Walking, EatingDot, EatingPower, EatingFruit
    }

    var targetDirecition: EnDirection = .Stop
    var turning: Bool = false

    var timer_playerWithPower: CbTimer!
    var timer_playerNotToEat: CbTimer!
 
    override init(object: CgSceneFrame, deligateActor: ActorDeligate) {
        super.init(object: object, deligateActor: deligateActor)
        timer_playerWithPower = CbTimer(binding: self)
        timer_playerNotToEat = CbTimer(binding: self)
        actor = .Pacman
        sprite_number = actor.getSpriteNumber()
        enabled = false
    }

    override func handleEvent(sender: CbObject, message: EnMessage, parameter values: [Int]) {
        switch message {
            case .Swipe:
                if let direction = EnDirection(rawValue: values[0]) {
                    targetDirecition = direction
                }
            default:
                break
        }
    }

    override func reset() {
        super.reset()
        timer_playerWithPower.reset()
        timer_playerNotToEat.reset()
        timer_playerWithPower.set(interval: deligateActor.getTimeOfPlayerWithPower())
        timer_playerNotToEat.set(interval: deligateActor.getTimeOfPlayerNotToEat())

        direction.reset()
        targetDirecition = .Stop
        turning = false

        position.set(column: 13, row: 9, dx: 4)
        direction.set(to: .Stop)
        draw(to: .None)
    }

    override func start() {
        super.start()
        timer_playerNotToEat.start()
    }

    override func stop() {
        super.stop()
        direction.set(to: .Stop)
        draw(to: .Stop)
    }
    
    override func update(interval: Int) {
        if turning {
            turn()
        } else {
            if canMove(to: targetDirecition) {
                direction.set(to: targetDirecition)
            } else {
                direction.update()
                if canTurn() {
                    turning = true
                    direction.set(to: targetDirecition)
                    return
                }
            }
            move()
        }
    }

    ///
    /// Can player turn the corner?
    ///
    func canTurn() -> Bool {
        if direction.get().getClockwise() == targetDirecition || direction.get().getCounterClockwise() == targetDirecition {
            let deltaDistance: Int = position.getAbsoluteDelta(to: direction.get())

            if deltaDistance >= 6 {
                let targetColumn = position.column + direction.get().getHorizaontalDelta() + targetDirecition.getHorizaontalDelta()
                let targetRow    = position.row + direction.get().getVerticalDelta() + targetDirecition.getVerticalDelta()
                let value = deligateActor.getTile(column: targetColumn, row: targetRow)

                if canMove(through: value) {
                    return true
                }
            }
        }
        return false
     }

    ///
    ///　Turn inwards
    ///
    func turn() {
        let power: Bool = timer_playerWithPower.isCounting()
        var speedForCurrentDirection = deligateActor.getPlayerSpeed(action: .Walking, with: power)
        var speedForNextDirection = speedForCurrentDirection

        // Move every 1dot at a time until speed becomes 0.
        while(speedForCurrentDirection > 0) {
            if position.getAbsoluteDelta(to: direction.get()) > 0 {
                // Move diagonally
                speedForCurrentDirection = position.move(to: direction.get(), speed: speedForCurrentDirection)
                speedForNextDirection = position.move(to: direction.getNext(), speed: speedForNextDirection)
            } else {
                turning = false
                position.roundDown(to: direction.get())
                direction.update()
                break
            }
        }
        
        sprite.setPosition(sprite_number, x: position.x, y: position.y)
        draw(to: direction.getNext())
    }
    
    /// Can player move through the tile?
    /// - Parameter tile: <#value description#>
    /// - Returns: <#description#>
    func canMove(through tile: EnMazeTile) -> Bool {
        return tile != .Wall
    }
    
    /// Can player move in the direction?
    /// - Parameter nextDirection: <#nextDirection description#>
    /// - Returns: <#description#>
    func canMove(to nextDirection: EnDirection) -> Bool {
        if position.canMove(to: nextDirection) {
            let targetColumn = position.column + nextDirection.getHorizaontalDelta()
            let targetRow = position.row + nextDirection.getVerticalDelta()
            let value: EnMazeTile = deligateActor.getTile(column: targetColumn, row: targetRow)
            return canMove(through: value)
        }
        return false
    }
    ///

    ///  Move and eat feed or fruit or nothing
    ///
    func move() {
        let power: Bool = timer_playerWithPower.isCounting()
        var speed: Int = 0
        let deltaDistance: Int = position.getAbsoluteDelta(to: direction.getNext())
        let targetColumn = position.column + direction.getNext().getHorizaontalDelta()
        let targetRow = position.row + direction.getNext().getVerticalDelta()
        let value: EnMazeTile = (deltaDistance < 4) ? .Road : deligateActor.getTile(column: targetColumn, row: targetRow)

        switch value {
            case .Feed:
                speed = deligateActor.getPlayerSpeed(action: .EatingDot, with: power)
                deligateActor.playerEatFeed(column: targetColumn, row: targetRow, power: false)
                timer_playerNotToEat.restart()

            case .PowerFeed:
                speed = deligateActor.getPlayerSpeed(action: .EatingPower, with: power)
                deligateActor.playerEatFeed(column: targetColumn, row: targetRow, power: true)
                timer_playerNotToEat.restart()
                timer_playerWithPower.restart()

            case .Fruit:
                speed = deligateActor.getPlayerSpeed(action: .EatingFruit, with: power)
                deligateActor.playerEatFruit(column: targetColumn, row: targetRow)

            default:
                speed = deligateActor.getPlayerSpeed(action: .Walking, with: power)
        }

        //
        // Move every 1dot at a time until speed becomes 0.
        //
        while(speed > 0) {
            // Can player move in the next direction?
            if canMove(to: direction.getNext()) {
                speed = position.move(to: direction.getNext(), speed: speed)
            } else {
                // If player cannot move, stop.
                direction.set(to: .Stop)
                speed = position.move(to: .Stop)
            }
        }

        //
        // Update position and direction
        //
        sprite.setPosition(sprite_number, x: position.x, y: position.y)

        if direction.isChanging() {
            direction.update()
            draw(to: direction.get())
        }
    }

    func draw(to direction: EnDirection) {
        switch direction {
            case .Right : sprite.startAnimation(sprite_number, sequence: [0,1,2]  , timePerFrame: 0.05, repeat: true)
            case .Left  : sprite.startAnimation(sprite_number, sequence: [32,33,2], timePerFrame: 0.05, repeat: true)
            case .Up    : sprite.startAnimation(sprite_number, sequence: [16,17,2], timePerFrame: 0.05, repeat: true)
            case .Down  : sprite.startAnimation(sprite_number, sequence: [48,49,2], timePerFrame: 0.05, repeat: true)
            case .Stop  : sprite.stopAnimation(sprite_number)
            case .None  : sprite.draw(sprite_number, x: position.x, y: position.y, texture: 2)
        }
    }

    func drawCharacterDisappeared() {
        sprite.startAnimation(sprite_number, sequence: [3,4,5,6,7,8,9,10,11,12,13,13,14], timePerFrame: 0.13, repeat: false)
    }

    func clear() {
        sprite.stopAnimation(sprite_number)
        sprite.clear(sprite_number)
    }

}

