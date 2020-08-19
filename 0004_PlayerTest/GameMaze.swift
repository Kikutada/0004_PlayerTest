//
//  GameMaze.swift
//  0003_GameArchTest
//
//  Created by Kikutada on 2020/08/13.
//  Copyright © 2020 Kikutada. All rights reserved.
//

import Foundation

let MAZE_MAX_DISTANCE: Int  = 36*36+44*44
let MAZE_UNIT: Int = 8

enum EnMazeTile: Int {
    case Road = 0x00
    case Feed = 0x01
    case PowerFeed = 0x02
    case Fruit = 0x03
    case Slow = 0xFC
    case Oneway = 0xFD
    case Gate = 0xFE
    case Wall = 0xFF
    
    init?( _ value : Int) {
        switch value {
        case 0x00: self = .Road
        case 0x01: self = .Feed
        case 0x02: self = .PowerFeed
        case 0x03: self = .Fruit
        case 0xFC: self = .Slow
        case 0xFD: self = .Oneway
        case 0xFE: self = .Gate
        case 0xFF: self = .Wall
        default:   return nil
        }
    }
}

protocol ActorDeligate {

    func playerEatFeed(column: Int, row: Int, power: Bool)
    func playerEatFruit(column: Int, row: Int)
    func getPlayerSpeed(action: CgPlayer.EnPlayerAction, with power: Bool) -> Int
    func getTimeOfPlayerWithPower() -> Int
    func getTimeOfPlayerNotToEat() -> Int

    func setTile(column: Int, row: Int, value: EnMazeTile)
    func getTile(column: Int, row: Int) -> EnMazeTile
    func getTileAttribute(to direction: EnDirection, column: Int, row: Int) -> EnMazeTile
}


/// Maze scene class for play mode
/// This class has some methods to draw a maze and starting messages.
class CgSceneMaze: CgSceneFrame, ActorDeligate {

    var player : CgPlayer!

    convenience init(object: CgSceneFrame) {
        self.init(binding: object, context: object.context, sprite: object.sprite, background: object.background, sound: object.sound)
        player = CgPlayer(object: self, deligateActor: self)
    }

    /// Handle sequence
    /// To override in a derived class.
    /// - Parameter sequence: Sequence number
    /// - Returns: If true, continue the sequence, if not, end the sequence.
    override func handleSequence(sequence: Int) -> Bool {
        switch sequence {
            case  0:
                drawFrame()
                let _ = setAndDraw()
                printPlayers()
                printBlinking1Up()

                drawPowerFeed(state: .Blinking)

                player.reset()
                player.start()
                
                goToNextSequence()
            
            case  1:
                // Foever loop
                break

            case  10:
                blinkingTimer = 104  // 104*16ms = 1664ms
                goToNextSequence()

            case  11:
                if blinkingTimer == 0 {
                    goToNextSequence()
                } else {
                    let remain = blinkingTimer % 26
                    if remain == 0 {
                        drawMazeWall(color: .White)
                    } else if remain == 13 { // 13*16ms = 208ms
                        drawMazeWall(color: .Blue)
                    }
                    blinkingTimer -= 1
                }

            case 12:
                // Stop and exit running sequence.
                return false

            default:
                // Stop and exit running sequence.
                return false
        }
        
        // Play BGM
        if player.timer_playerWithPower.isCounting() {
            sound.playBGM(.BgmPower)
        } else {
            sound.playBGM(.BgmNormal)
        }
        
        // Continue running sequence.
        return true
    }

    func playerEatFeed(column: Int, row: Int, power: Bool) {
        background.put(0, column: column, row: row, texture: 16*29)
        setTile(column: column,row: row, value: .Road)

        if power {
            addScore(pts: 50)
        } else {
            sound.playSE(.EatDot)
            addScore(pts: 10)
        }
    }

    func getTimeOfPlayerWithPower() -> Int {
        return 6000 //ms
    }
    
    func getTimeOfPlayerNotToEat() -> Int {
        return 4000 // ms
    }
    
    func playerEatFruit(column: Int, row: Int) {
        background.put(0, column: column, row: row, texture: 16*29)
        setTile(column: column,row: row, value: .Road)
    }
    
    func getPlayerSpeed(action: CgPlayer.EnPlayerAction, with power: Bool) -> Int {
        let speed: Int
        switch action {
            case .Walking where !power : speed = 16
            case .Walking where  power : speed = 18
            case .EatingDot where !power : speed = 15
            case .EatingDot where  power : speed = 17
            case .EatingPower where !power : speed = 13
            case .EatingPower where  power : speed = 15
            case .EatingFruit where !power : speed = 15
            case .EatingFruit where  power : speed = 17
            default: speed = 16
        }
        return speed
    }

    func setTile(column: Int, row: Int, value: EnMazeTile) {
        mazeValues[column][row] = value
    }

    func getTile(column: Int, row: Int) -> EnMazeTile {
        if column < 0 {
            return mazeValues[BG_WIDTH-1][row]
        } else if column >= BG_WIDTH {
            return mazeValues[0][row]
        }
        return mazeValues[column][row]
    }

    func getTileAttribute(column: Int, row: Int) -> EnMazeTile {
        if column < 0 {
            return mazeAttributes[BG_WIDTH-1][row]
        } else if column >= BG_WIDTH {
            return mazeAttributes[0][row]
        }
        return mazeAttributes[column][row]
    }

    func getTileAttribute(to direction: EnDirection, column: Int, row: Int) -> EnMazeTile {
        switch direction {
            case .Left : return getTileAttribute(column: column-1, row: row)
            case .Right: return getTileAttribute(column: column+1, row: row)
            case .Up   : return getTileAttribute(column: column  , row: row+1)
            case .Down : return getTileAttribute(column: column  , row: row-1)
            default    : return getTileAttribute(column: column  , row: row)
        }
    }

    func addScore(pts: Int) {
        context.score += pts
        printPlayerScore()
        if context.updateHighScore() {
            printHighScore()
        }
        if !context.score_extendedPlayer {
            if context.score >= context.score_extendPlayer {
                context.score_extendedPlayer = true
                sound.playSE(.ExtraPacman)
                context.numberOfPlayers += 1
                printPlayers()
            }
        }
    }

    
    struct StMazePosition {
        var column: Int
        var row: Int
    }

    private var numberOfDots: Int = 0
    private var mazeValues = [[EnMazeTile]](repeating: [EnMazeTile](repeating: .Road, count: BG_HEIGHT), count: BG_WIDTH)
    private var mazeAttributes = [[EnMazeTile]](repeating: [EnMazeTile](repeating: .Road, count: BG_HEIGHT), count: BG_WIDTH)
    private var powerFeeds = [StMazePosition]()
    private var blinkingTimer: Int = 0

    func setAndDraw() -> Int {
        resetSequence()
        setMazeValuesAndAttributes()
        drawMaze()
        printFrame()
        printPlayerScore()
        printHighScore()
        printRounds()

        return numberOfDots
    }
    
    private func setMazeValuesAndAttributes() {
        
        let mazeSource = getMazeSource()
        var row = BG_HEIGHT-4

        numberOfDots = 0
        powerFeeds.removeAll()

        for str in mazeSource {
            var column = 0
            for c in str {
                switch(c) {
                    case "_" :
                        mazeValues[column][row] = EnMazeTile.Road
                        mazeAttributes[column][row] = EnMazeTile.Slow
                    case " " :
                        mazeValues[column][row] = EnMazeTile.Road
                        mazeAttributes[column][row] = EnMazeTile.Road
                    case "1" :
                        mazeValues[column][row] = EnMazeTile.Feed
                        mazeAttributes[column][row] = EnMazeTile.Road
                        numberOfDots += 1
                    case "2" :
                        mazeValues[column][row] = EnMazeTile.Feed
                        mazeAttributes[column][row] = EnMazeTile.Oneway
                        numberOfDots += 1
                    case "3" :
                        mazeValues[column][row] = EnMazeTile.PowerFeed
                        mazeAttributes[column][row] = EnMazeTile.Road
                        numberOfDots += 1
                        let pd = StMazePosition(column: column, row: row)
                        powerFeeds.append(pd)
                    default :
                        mazeValues[column][row] = EnMazeTile.Wall
                        mazeAttributes[column][row] = EnMazeTile.Wall
                }
                column += 1
            }
            row -= 1
        }
    }

    ///　Draw maze with walls and dots
    private func drawMaze() {
        var row = BG_HEIGHT-4
        
        let mazeSource = getMazeSource()

        for str in mazeSource {
            var i = 0
            for c in str.utf8 {
                let txNo: Int
                switch c {
                    case 50 : txNo = 592  // Oneway with dot "2" -> "1"
                    case 95 : txNo = 576  // Slow "_" -> " "
                    default : txNo = Int(c)+544 // 576-32
                }
                background.put(0, column: i, row: row, texture: txNo)
                i += 1
            }
            row -= 1
        }
    }
    
    /// Maze color
    enum EnMazeWallColor: Int {
        case Blue = 0, White = 1
    }
    
    /// Draw only the wall of the maze
    /// - Parameter color: Maze color
    private func drawMazeWall(color: EnMazeWallColor) {
        var row = BG_HEIGHT-4
        let offset: Int = color.rawValue*48

        let mazeSource = getMazeSource()

        for str in mazeSource {
            var i = 0
            for c in str.utf8 {
                let txNo: Int
                if c < 57 || c == 87 {
                    txNo = offset+576
                } else {
                    txNo = Int(c)+offset+544
                }
                background.put(0, column: i, row: row, texture: txNo)
                i += 1
            }
            row -= 1
        }
    }

    enum EnPowerFeedState {
        case Clear, Stop, Blinking
        
        func getTexture()->Int {
            switch self {
                case .Clear: return 464
                case .Stop: return 595
                case .Blinking: return 768
            }
        }
    }

    func drawPowerFeed(state: EnPowerFeedState) {
        for t in powerFeeds {
            if mazeValues[t.column][t.row] == EnMazeTile.PowerFeed {
                background.put(0, column: t.column, row: t.row, texture: state.getTexture())
            }
        }
    }

    func printBlinking1Up() {
        background.put(0, column: 3, row: 35, texture: 769)  // 1 -> 1
        background.put(0, column: 4, row: 35, texture: 770)  // 2 -> U
        background.put(0, column: 5, row: 35, texture: 771)  // 3 -> P
    }

    enum EnPrintStateMessage {
        case PlayerOneReady, Ready, ClearPlayerOne, ClearReady, GameOver
    }
    
    /// Print starting message
    /// - Parameter state: Kind of message
    func printStateMessage(_ state: EnPrintStateMessage) {
        switch state {
            case .PlayerOneReady:
                background.print(0, color: .Cyan, column:  9, row: 21, string: "PLAYER ONE")
                fallthrough
            case .Ready:
                background.print(0, color: .Yellow, column: 11, row: 15, string: "READY!")
            case .ClearPlayerOne:
                background.print(0, color: .Cyan, column:  9, row: 21, string: "          ")
            case .ClearReady:
                background.print(0, color: .Yellow, column: 11, row: 15, string: "      ")
            case .GameOver:
                background.print(0, color: .Red, column:  9, row: 15, string: "GAME  OVER")
        }
    }


    func getMazeSource() -> [String] {
        
        let mazeSource: [String] = [
            "aggggggggggggjiggggggggggggb",
            "e111111111111EF111111111111f",
            "e1AGGB1AGGGB1EF1AGGGB1AGGB1f",
            "e3E  F1E   F1EF1E   F1E  F3f",
            "e1CHHD1CHHHD1CD1CHHHD1CHHD1f",
            "e11111111111111111111111111f",
            "e1AGGB1AB1AGGGGGGB1AB1AGGB1f",
            "e1CHHD1EF1CHHJIHHD1EF1CHHD1f",
            "e111111EF1111EF1111EF111111f",
            "chhhhB1EKGGB1EF1AGGLF1Ahhhhd",
            "     e1EIHHD2CD2CHHJF1f     ",
            "     e1EF          EF1f     ",
            "     e1EF QhUWWVhR EF1f     ",
            "gggggD1CD f      e CD1Cggggg",
            "__    1   f      e   1    __" ,
            "hhhhhB1AB f      e AB1Ahhhhh",
            "     e1EF SggggggT EF1f     ",
            "     e1EF          EF1f     ",
            "     e1EF AGGGGGGB EF1f     ",
            "aggggD1CD1CHHJIHHD1CD1Cggggb",
            "e111111111111EF111111111111f",
            "e1AGGB1AGGGB1EF1AGGGB1AGGB1f",
            "e1CHJF1CHHHD2CD2CHHHD1EIHD1f",
            "e311EF1111111  1111111EF113f",
            "kGB1EF1AB1AGGGGGGB1AB1EF1AGl",
            "YHD1CD1EF1CHHJIHHD1EF1CD1CHZ",
            "e111111EF1111EF1111EF111111f",
            "e1AGGGGLKGGB1EF1AGGLKGGGGB1f",
            "e1CHHHHHHHHD1CD1CHHHHHHHHD1f",
            "e11111111111111111111111111f",
            "chhhhhhhhhhhhhhhhhhhhhhhhhhd"
        ]

        return mazeSource
    }

}
