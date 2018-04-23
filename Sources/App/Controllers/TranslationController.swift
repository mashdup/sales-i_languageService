//
//  LanguageController.swift
//  App
//
//  Created by Dillon on 20/04/2018.
//

import Vapor
import FluentMySQL

struct TranslationController: RouteCollection {
    let authKey = "9870uijlHGYkjsldkans90SIuj098sd908iJALK90sdlkls0"
    let routeBase = "translations";
    func boot(router: Router) throws {
        router.get("api",routeBase,String.parameter,String.parameter, use: getTranslations)
        router.get("api",routeBase, use: getAllTranslations)
        router.post("api",routeBase, use: createTranslation)
        router.delete("api",routeBase, use: deleteTransaltion)
    }
    
    func createTranslation(_ req : Request) throws -> Future<Translation> {
        let authHeader : Array? = req.http.headers["Authorization"]
        if authHeader?.count == 0 {throw Abort(.forbidden, reason: "Missing Authorization Header")}
        let auth: String? = req.http.headers["Authorization"][0]
        if auth != authKey { throw Abort(.forbidden, reason: "Not authorised to add translation")}
        return try req.content.decode(Translation.self).flatMap(to: Translation.self) { translation in
            //delete any with same key
            
            _ = try Translation.query(on: req).filter(\.identifier == translation.identifier).all().map(to: [Translation].self) { translations in
                for savedTranslation in translations {
                    if savedTranslation.platform == "any" || savedTranslation.platform == translation.platform {
                        _ = savedTranslation.delete(on: req)
                    }
                }
                return translations
            }
            
            return translation.save(on: req)
        }
    }
    
    func deleteTransaltion(_ req : Request) throws -> Future<HTTPStatus> {
        let authHeader : Array? = req.http.headers["Authorization"]
        if authHeader?.count == 0 {throw Abort(.forbidden, reason: "Missing Authorization Header")}
        let auth: String? = req.http.headers["Authorization"][0]
        if auth != authKey { throw Abort(.forbidden, reason: "Not authorised to delete translation")}
        return try req.content.decode(Translation.self).flatMap(to: Translation.self) { translation in
            
            return try Translation.query(on: req).filter(\.identifier == translation.identifier).all().map(to: Translation.self) { translations in
                if translations.count == 0 { throw Abort(.notFound, reason : "No existing Indentifier")}
                
                for savedTranslation in translations {
                    if savedTranslation.platform == "any" || savedTranslation.platform == translation.platform {
                        _ = savedTranslation.delete(on: req)
                    }
                }
                return translation
            }
        }.transform(to: .noContent)
    }
    
    func getTranslations(_ req: Request) throws -> Future<Dictionary<String, String>> {
        
        let translationCode = try req.parameters.next(String.self)
        let platformName = try req.parameters.next(String.self)
        
        var translationDict = Dictionary<String, String> ()

        return req.withConnection(to: .mysql) { db -> Future<Dictionary<String, String>> in
            return try db.query(Translation.self).filter(\.code == translationCode).sort(QuerySort(field: QueryField(name: "identifier") , direction: .ascending)).run() { translation in
                    if translation.platform == platformName || translation.platform == "any" {
                        translationDict[translation.identifier] = translation.translation
                    }
                }.map(to: Dictionary<String, String>.self) {
                    return translationDict
            }
        }
    }
    
    func getAllTranslations(_ req : Request)throws  -> Future<[Translation]> {
        
        return req.withConnection(to: .mysql) { db -> Future<[Translation]> in
            return db.query(Translation.self).all()
        }
    }
}
