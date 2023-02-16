//
//  UnsupportedDeviceView.swift
//  NearbyInteractionMe
//
//  Created by RMP on 22/07/1444 AH.
//

import SwiftUI

struct UnsupportedDeviceView: View {
    var body: some View {
        
        ZStack {
            
            Color(.systemGray5).ignoresSafeArea()
            
            VStack(spacing: 10) {
                
                Text("Unsupported Device").font(.largeTitle).fontWeight(.semibold).foregroundColor(Color(.systemGray))
                Text("This sample app requires an iPhone 11 or later device with a U1 chip.").multilineTextAlignment(.center).fontWeight(.semibold).foregroundColor(Color(.systemGray))
                
            }
            
        }
        
    }
}

struct UnsupportedDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        UnsupportedDeviceView()
    }
}
