//
//  GameContext.swift
//  0003_GameArchTest
//
//  Created by Kikutada on 2020/08/12.
//  Copyright © 2020 Kikutada. All rights reserved.
//

import Foundation

/// Context and settings for game
class CgContext {

    enum EnLanguage: Int {
        case English = 0, Japanese
    }

    var language: EnLanguage = .Japanese

    var highScore = 100
    var score = 0
    var credit = 1
    var numberOfPlayers = 3
    var round = 1
    
    var score_extendPlayer: Int = 200
    var score_extendedPlayer: Bool = false
    
    /// Update high score
    /// - Returns: If true, the high score has been updated.
    func updateHighScore()->Bool {
        let highScoreUpdated: Bool = score > highScore
        if highScoreUpdated { highScore = score }
        return highScoreUpdated
    }
}
