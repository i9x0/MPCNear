//
//  ContentView.swift
//  NearbyInteractionMe
//
//  Created by RMP on 22/07/1444 AH.
//

import SwiftUI


struct SupportedDeviceView: View {
    
    
    @State var shouldShowTheMonkey = false
    
//    init() {
//
//        viewModel.startup()
//
//    }
    
    @ObservedObject var viewModel = MPNSession()
    
    
    var body: some View {
        
        VStack{
            Text(viewModel.deviseName ?? "Null")
            Text(viewModel.details ?? "Null")
            Text(viewModel.monky ?? "Null")
            Text(viewModel.distanceN ?? "Null")
            
        }
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SupportedDeviceView()
    }
}



