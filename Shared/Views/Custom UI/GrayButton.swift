//
//  File.swift
//
//
//  Created by Leon Böttger on 16.03.24.
//

import SwiftUI

public struct GrayButton: View {
    
    public init(label: String,
                hasPadding: Bool = true,
                vibrates: Bool = true,
                action: @escaping () -> ()) {
        self.label = label
        self.action = action
        self.hasPadding = hasPadding
        self.vibrates = vibrates
    }
    
    let vibrates: Bool
    let label: String
    let hasPadding: Bool
    let action: () -> ()
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    public var body: some View {
        LUIButton(action: {
            
            if(vibrates) {
                lightVibration()
            }
            action()
            
        }) {
            HStack(spacing: 0) {
                Text(label.localized())
                    .lineLimit(1)
            }
#if !os(tvOS)
            .grayButton()
#endif
        }
        .padding(hasPadding ? .horizontal : .horizontal, 0)
        .opacity(isEnabled ? 1 : 0.5)
    }
}


extension View {
    func grayButton() -> ModifiedContent<Self, GrayButtonModifier> {
        return modifier(GrayButtonModifier())
    }
}


struct GrayButtonModifier: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(colorScheme.isLight ? .mainColor : .white)
            .font(.headline)
            .padding()
            .padding(.vertical, -1)
            .frame(minWidth: 0, maxWidth: 320, alignment: .center)
            .background(
                ZStack {
                    if colorScheme.isLight {
                        Color.sheetBackground
                        Color.gray.opacity(0.2)
                    }
                    else {
                        Color.sheetForeground
                        Color.white.opacity(0.1)
                    }
                }
                    .cornerRadius(20))
    }
}



#Preview {
    GrayButton(label: "Hello", action: {})
}
