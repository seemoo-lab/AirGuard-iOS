//
//  CustomLabel.swift
//  AirGuard
//
//  Created by Leon Böttger on 10.05.22.
//

import SwiftUI

struct SettingsLabel: View {
    let imageName: String
    let text: String
    var backgroundColor: Color = Color.blue
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var body: some View {
        HStack{
            SettingsIcon(imageName: imageName, backgroundColor: backgroundColor)
            Text(text.localized())
                .foregroundColor(Color("DarkBlue"))
                .multilineTextAlignment(.leading)
            Spacer()
            
        }
        .frame(height: Constants.SettingsLabelHeight)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .opacity(isEnabled ? 1 : 0.5)
    }
}


struct CustomPickerLabel: View {
    let selection: String
    var backgroundColor = Color.blue
    let description: String
    let imageName: String
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var body: some View {
        HStack() {
            SettingsLabel(imageName: imageName, text: description, backgroundColor: self.backgroundColor)
            Spacer()
            Text(selection.localized()).foregroundColor(.gray)
                .animation(nil)
                .opacity(isEnabled ? 1 : 0.5)
        }
    }
}


struct NavigationLinkLabel: View {
    let imageName: String
    let text: String
    var backgroundColor: Color
    var isNavLink: Bool
    let status: String
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    init(imageName: String, text: String, backgroundColor: Color = Color.blue, isNavLink: Bool = true, status: String = "") {
        self.imageName = imageName
        self.text = text
        self.backgroundColor = backgroundColor
        self.isNavLink = isNavLink
        self.status = status
    }
    
    
    var body: some View {
        HStack {
            SettingsLabel(imageName: imageName, text: text, backgroundColor: backgroundColor)
            Spacer()
            
            if(status != "") {
                Text(status.localized())
                    .foregroundColor(.gray)
                    .opacity(isEnabled ? 1 : 0.5)
            }
            
            if(isNavLink) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .opacity(isEnabled ? 1 : 0.5)
            }
            else {
                Image(systemName: "link")
                    .foregroundColor(.gray)
                    .opacity(isEnabled ? 1 : 0.5)
            }
        }
    }
}


struct SettingsIcon: View {
    let imageName: String
    let backgroundColor: Color
    let size: CGFloat = 30
    
    var body: some View {
        
        ZStack{
            Circle()
                .foregroundColor(backgroundColor)
            
            Image(systemName: imageName)
                .font(.system(size: size / 2, weight: .bold))
                .foregroundColor(.white)
                .clipped()
            
        }.frame(width: size, height: size)
        .padding(.trailing, 5)
        .compositingGroup()
    }
}
