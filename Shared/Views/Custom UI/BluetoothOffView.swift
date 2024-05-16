//
//  BluetoothOffView.swift
//  AirGuard
//
//  Created by Leon Böttger on 18.05.22.
//

import SwiftUI

struct ExclamationmarkView: View {
    
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 60, weight: .light, design: .default))
            .background(Rectangle()
                .frame(width: 20, height: 30)
                .padding(.top, 5)
                .foregroundColor(.white))
            .padding(10)
        
    }
}

#Preview {
    ExclamationmarkView()
        .foregroundColor(.airGuardBlue)
}
