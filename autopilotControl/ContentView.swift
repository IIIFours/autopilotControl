//
//  ContentView.swift
//  autopilotControl
//
//  Created by Alexander Schlake on 10/23/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager() // ObservedObject to track BLE changes
        
        var body: some View {
            VStack {
                if bleManager.isConnected {
                    Text("Connected to BLE Module")
                        .foregroundColor(.green)
                } else {
                    Text("Connecting...")
                        .foregroundColor(.red)
                }
                
                Text(String(describing: bleManager.autopilot))
                    .font(.body)
                    .padding()
                
                Spacer()
            }
            .padding()
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
