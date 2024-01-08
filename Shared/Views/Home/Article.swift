//
//  Article.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.07.22.
//

import Foundation

/// Struct wich represents an image with coresponding title and subtitle.
struct ImageCard {
    
    let imageName: String
    let header: String
    let subHeader: String
    
}

/// Struct which represents an article.
struct Article: Identifiable {
    
    var id: String = UUID().uuidString
    
    let author: String
    let minRead: Int
    let text: String
    var usesMarkdown: Bool=false
    
    let card: ImageCard
}


/// All articles available
var articles = [
    
    Article(id: "survey", author: "Alexander", minRead: 1, text: "article_survey_text",
            usesMarkdown: true,
            card: ImageCard(imageName: "survey", header: "article_survey_header", subHeader: "article_survey_subheader")),
    
    Article(author: "Leon", minRead: 1, text: "article_howitworks_text", card: ImageCard(imageName: "Investigating", header: "article_howitworks_header", subHeader: "article_howitworks_subheader")),
    
    helpArticle,
    
    Article(author: "Alexander & Leon", minRead: 3,
            text: "article_supported_trackers_text",
            usesMarkdown: true,
            card: ImageCard(imageName: "Map", header: "article_supported_trackers_header", subHeader: "article_supported_trackers_subheader")),
    
    faqArticle
    
]

let faqArticle = Article(author: "Leon", minRead: 3,
                         text: "article_faq_text",
                         usesMarkdown: true,
                         card: ImageCard(imageName: "FAQ", header: "article_faq_header", subHeader: "article_faq_subheader"))

let helpArticle = Article(author: "Alexander & Leon", minRead: 3,
                              text: "article_supported_get_help_text",
                              usesMarkdown: true,
                              card: ImageCard(imageName: "StopSign", header: "article_supported_get_help_header", subHeader: "article_supported_get_help_subheader"))
