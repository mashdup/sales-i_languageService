//
//  Language.swift
//  App
//
//  Created by Dillon on 20/04/2018.
//

import Vapor
import FluentMySQL

final class Translation : Codable {
    var id : Int?
    var code : String
    var identifier : String
    var translation : String
    var platform : String
    
    init(code: String, identifier: String, translation: String, platform: String) {
        self.code = code;
        self.identifier = identifier
        self.translation = translation
        self.platform = platform
    }
}

extension Translation : Migration {}
extension Translation : Content {}
extension Translation : MySQLModel {}
extension Translation : Parameter {}
extension Translation : Model {}
