//
//  Language.swift
//  App
//
//  Created by Dillon on 23/04/2018.
//

import Vapor
import FluentMySQL

final class Language : Codable {
    var id : Int?
    var key : String
    var value : String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

extension Language : Migration {}
extension Language : Content {}
extension Language : MySQLModel {}
extension Language : Parameter {}
extension Language : Model {}
