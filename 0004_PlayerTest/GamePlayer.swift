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
        draw(in: .None)
    }

    override func start() {
        super.start()
        timer_playerNotToEat.start()
    }

    override func stop() {
        super.stop()
        direction.set(to: .Stop)
        draw(in: .Stop)
    }
    
    override func update(interval: Int) {
        //
        //
        //
        let power: Bool = timer_playerWithPower.isCounting()
        //
        //
        //
        if turning {

            var speed1 = deligateActor.getPlayerSpeed(action: .Walking, with: power)
            var speed2 = speed1

            while(speed1 > 0) {
                if position.getAbsoluteDelta(direction: direction.get()) > 0 {
                    speed1 = position.move(direction: direction.get(), speed: speed1)
                    speed2 = position.move(direction: direction.getNext(), speed: speed2)
                } else {
                    turning = false
                    position.normalize(in: direction.getNext())
                    direction.update()
                    break
                }
            }
            
            sprite.setPosition(sprite_number, x: position.x, y: position.y)
            draw(in: direction.getNext())
            return
        }

        //
        //  移動する Direction を決める
        //
        if canMove(in: targetDirecition) {
            direction.set(to: targetDirecition)
        } else {
            //
            //  自走
            //
            direction.update()

            //
            //  曲がるか？
            //
            let deltaDistance: Int = position.getAbsoluteDelta(direction: direction.get())

            if deltaDistance >= 6 {
                if direction.get().getClockwise() == targetDirecition ||
                   direction.get().getCounterClockwise() == targetDirecition
                {
                    let targetColumn = position.column + direction.get().getHorizaontalDelta() + targetDirecition.getHorizaontalDelta()
                    let targetRow    = position.row + direction.get().getVerticalDelta() + targetDirecition.getVerticalDelta()
                    let value = deligateActor.getTile(column: targetColumn, row: targetRow)

                    if canMove(through: value) {
                        turning = true
                        direction.set(to: targetDirecition)
                        return
                    }
                }
            }
        }
        
        //
        //  移動する Speed を決める
        //
        let deltaDistance: Int = position.getAbsoluteDelta(direction: direction.getNext())
        var speed: Int = 0

        if deltaDistance < 4 {
            //
            //  何もないところを移動
            //
            speed = deligateActor.getPlayerSpeed(action: .Walking, with: power)
        } else if deltaDistance >= 4 {
            //
            //  エサを食べるかチェックする
            //
            let targetColumn = position.column + direction.getNext().getHorizaontalDelta()
            let targetRow = position.row + direction.getNext().getVerticalDelta()
            let value = deligateActor.getTile(column: targetColumn, row: targetRow)

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
        }

        //
        //  Speed だけ移動させる（壁にぶつかったら止まる）
        //
        while(speed > 0) {
            if canMove(in: direction.getNext()) {
                speed = position.move(direction: direction.getNext(), speed: speed)
            } else {
                direction.set(to: .Stop)
                speed = position.move(direction: .Stop)
            }
        }

        //
        //  プレイヤーの位置を更新,進む方向を描画
        //
        sprite.setPosition(sprite_number, x: position.x, y: position.y)
        if direction.isChanging() {
            direction.update()
            draw(in: direction.get())
        }

    }

    func canMove(through value: EnMazeValue) -> Bool {
        return value != .Wall
    }

    func canMove(in nextDirection: EnDirection)->Bool {
        if position.canMove(direction: nextDirection) {
            let targetColumn = position.column + nextDirection.getHorizaontalDelta()
            let targetRow = position.row + nextDirection.getVerticalDelta()
            let value: EnMazeValue = deligateActor.getTile(column: targetColumn, row: targetRow)
            return canMove(through: value)
        }
        return false
    }

    func draw(in direction: EnDirection) {
        switch direction {
            case .Right : sprite.startAnimation(sprite_number, sequence: [0,1,2]  , timePerFrame: 0.05, repeat: true)
            case .Left  : sprite.startAnimation(sprite_number, sequence: [32,33,2], timePerFrame: 0.05, repeat: true)
            case .Up    : sprite.startAnimation(sprite_number, sequence: [16,17,2], timePerFrame: 0.05, repeat: true)
            case .Down  : sprite.startAnimation(sprite_number, sequence: [48,49,2], timePerFrame: 0.05, repeat: true)
            case .Stop  : sprite.stopAnimation(sprite_number)
            case .None  : sprite.draw(sprite_number, x: position.x, y: position.y, texture: 2)
        }
    }

    func clear() {
        sprite.stopAnimation(sprite_number)
        sprite.clear(sprite_number)
    }
        
    func drawCharacterDisappeared() {
        sprite.startAnimation(sprite_number, sequence: [3,4,5,6,7,8,9,10,11,12,13,13,14], timePerFrame: 0.13, repeat: false)
    }

   
}

