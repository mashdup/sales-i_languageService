//
//  LanguageController.swift
//  App
//
//  Created by Dillon on 23/04/2018.
//


import Vapor
import FluentMySQL

struct LanguageController : RouteCollection{
    let authKey = "9832ryeifhjsdeiu238r0=^HJKIO789sdija*(^7doijsd_A*(1salpsijd"
    let routeBase = "languages";
    func boot(router: Router) throws {
        router.get("api",routeBase, use: getAvailableLanguages)
        router.post("api",routeBase, use: createLanguage)
        router.delete("api",routeBase, use: deleteLanguage)
    }
    
    func createLanguage(_ req : Request) throws -> Future<Language> {
        let auth = req.http.headers["Authorization"][0]
        if auth != authKey { throw Abort(.forbidden, reason: "Not authorised to add language")}
        return try req.content.decode(Language.self).flatMap(to: Language.self) { language in
            //delete any with same key
            
            _ = try Language.query(on: req).filter(\.key == language.key).all().map(to: [Language].self) { languages in
                for savedLanguage in languages {
                    _ = savedLanguage.delete(on: req)
                }
                return languages
            }
            
            return language.save(on: req)
        }
    }
    
    func deleteLanguage(_ req : Request) throws -> Future<HTTPStatus> {
        let auth = req.http.headers["Authorization"][0]
        if auth != authKey { throw Abort(.forbidden, reason: "Not authorised to delete language")}
        return try req.content.decode(Language.self).flatMap(to: Language.self) { language in
            
            return try Language.query(on: req).filter(\.key == language.key).all().map(to: Language.self) { languages in
                if languages.count == 0 { throw Abort(.notFound, reason : "No existing Indentifier")}
                
                for savedLanguage in languages {
                        _ = savedLanguage.delete(on: req)
                    
                }
                return language
            }
            }.transform(to: .noContent)
    }
    
    func getAvailableLanguages(_ req : Request) throws -> Future<[Language]> {
        return req.withConnection(to: .mysql) { db -> Future<[Language]> in
            return db.query(Language.self).all()
        }
    }
}
