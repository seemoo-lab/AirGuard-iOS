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
    
    let id = UUID()
    
    let author: String
    let minRead: Int
    let text: String
    var usesMarkdown: Bool=false
    
    let card: ImageCard
}


/// Card for survey. Unused since there is no survey at the moment.
let survey = ImageCard(imageName: "Survey", header: "survey_header", subHeader: "survey_subheader")


/// All articles available
let articles = [
    
    Article(author: "Leon", minRead: 1, text: "article_howitworks_text", card: ImageCard(imageName: "Investigating", header: "article_howitworks_header", subHeader: "article_howitworks_subheader")),
    
    Article(author: "Alexander", minRead: 1,
            text: "article_supported_get_help_text",
            usesMarkdown: true,
            card: ImageCard(imageName: "HelpArticle", header: "article_supported_get_help_header", subHeader: "article_supported_get_help_subheader")),
    
    Article(author: "Leon", minRead: 1, text: "article_notification_text", card: ImageCard(imageName: "Location", header: "article_notification_header", subHeader: "article_notification_subheader")),
    
    Article(author: "Leon", minRead: 2, text: "article_limitations_text", card: ImageCard(imageName: "Couch", header: "article_limitations_header", subHeader: "article_limitations_subheader")),
    
    Article(author: "Alexander", minRead: 2,
            text: "article_supported_trackers_text",
            usesMarkdown: true,
            card: ImageCard(imageName: "TrackersArticle", header: "article_supported_trackers_header", subHeader: "article_supported_trackers_subheader"))
    
]
