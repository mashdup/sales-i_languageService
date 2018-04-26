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
        router.delete("api",routeBase,String.parameter,String.parameter,String.parameter, use: deleteTransaltion)
    }
    
    func createTranslation(_ req : Request) throws -> Future<[Translation]> {
        let authHeader : Array? = req.http.headers["Authorization"]
        if authHeader?.count == 0 {throw Abort(.forbidden, reason: "Missing Authorization Header")}
        let auth: String? = req.http.headers["Authorization"][0]
        if auth != authKey { throw Abort(.forbidden, reason: "Not authorised to add translation")}
        return try req.content.decode([Translation].self).map(to: [Translation].self) { translations in
            //delete any with same key
        
            for translation in translations {
                _ = try Translation.query(on: req).filter(\.identifier == translation.identifier).all().map(to: [Translation].self) { savedTranslations in
                    for savedTranslation in savedTranslations {
                        if savedTranslation.platform == translation.platform {
                            if (savedTranslation.code == translation.code) {
                                _ = savedTranslation.delete(on: req)
                            }
                        }
                    }
                    return savedTranslations
                }
                
                _ = translation.save(on: req)
            }
            return translations
        }
    }
    
    func deleteTransaltion(_ req : Request) throws -> Future<HTTPStatus> {
        let authHeader : Array? = req.http.headers["Authorization"]
        if authHeader?.count == 0 {throw Abort(.forbidden, reason: "Missing Authorization Header")}
        let auth: String? = req.http.headers["Authorization"][0]
        if auth != authKey { throw Abort(.forbidden, reason: "Not authorised to delete translation")}
        
        let languageCode = try req.parameters.next(String.self)
        let platform = try req.parameters.next(String.self)
        let identifier = try req.parameters.next(String.self)
        return try Translation.query(on: req).filter(\.identifier == identifier).all().map(to: Void.self) { translations in
            if translations.count == 0 { throw Abort(.notFound, reason : "No existing Indentifier")}
            
            for savedTranslation in translations {
                if savedTranslation.platform == platform {
                    if (savedTranslation.code == languageCode) {
                        _ = savedTranslation.delete(on: req)
                    }
                }
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
        return Translation.query(on: req).all()
    }
}
