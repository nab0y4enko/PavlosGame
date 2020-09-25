//
//  DeeplinkManager.swift
//  PavlosGame
//
//  Created by Oleksii Naboichenko on 08.02.2020.
//  Copyright © 2020 Oleksii Naboichenko. All rights reserved.
//

import Foundation

final class DeeplinkManager {
    
    // MARK: - Game
    enum Game {
        case simpleMathExercise(question: String, rightAnswer: String)
        
        var textToSpeak: String {
            switch self {
            case .simpleMathExercise(let question, _):
                return "Сколько будет \(question)"
            }
        }
        
        var answer: String {
            switch self {
            case .simpleMathExercise(_, let rightAnswer):
                return rightAnswer
            }
        }
        
        // MARK: - Initializers
        init?(url: URL) {
            guard url.scheme == "com.pavlo.game" else {
                return nil
            }
            
            guard let urlComponents = URLComponents(string: url.absoluteString) else {
                return nil
            }
            
            switch url.host {
            case "simple_math_exercise":
                let questionComponent = urlComponents.queryItems?.first { $0.name == "question" }
                let rightAnswerComponent = urlComponents.queryItems?.first { $0.name == "rightAnswer" }

                guard let question = questionComponent?.value, let rightAnswer = rightAnswerComponent?.value else {
                    return nil
                }

                self = .simpleMathExercise(question: question, rightAnswer: rightAnswer)
            default:
                return nil
            }
        }
    }

    // MARK: - Singletone Implementation
    static var shared: DeeplinkManager = DeeplinkManager()

    // MARK: - Public Properties
    var currentGame: Game?
   
    // MARK: - Public Properties
    @discardableResult
    func handleUrl(_ url: URL) -> Bool {
        currentGame = Game(url: url)
        return currentGame != nil
    }
}
