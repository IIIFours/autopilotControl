//
//  ContentView.swift
//  autopilotControl
//
//  Created by Alexander Schlake on 10/23/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager();
    
    @State private var kpInput: Float = 0.0;
    @State private var kiInput: Float = 0.0;
    @State private var kdInput: Float = 0.0;
    @State private var valuesInitialized = false;
        
    var body: some View {
        NavigationView {
            VStack() {
                if bleManager.isConnected {
                    VStack() {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Proportional (Kp)")
                            }
                            Stepper("", value: $kpInput, in: 0...10, step: 0.1)
                            Text("\(String(format: "%.1f", kpInput))")
                        }.padding(.horizontal)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Integral (Ki)")
                            }
                            Stepper("", value: $kiInput, in: 0...10, step: 0.1)
                            Text("\(String(format: "%.1f", kiInput))")
                        }.padding(.horizontal)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Derivative (Kd)")
                            }
                            Stepper("", value: $kdInput, in: 0...10, step: 0.1)
                            Text("\(String(format: "%.1f", kdInput))")
                        }.padding(.horizontal)
                        
                        Button(action: {
                            bleManager.sendUpdatedPIDValues(kpInput: kpInput, kiInput: kiInput, kdInput: kdInput);
                        }) {
                            Text("Update Gains")
                                .padding()
                                .background(Color.teal)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }.padding()
                        List {
                            ForEach(bleManager.autopilot.allDescriptions(), id: \.self) { description in
                                Text(description)
                                    .font(.body)
                            }
                        }
                    }.onAppear {
                        if !valuesInitialized {
                            kpInput = bleManager.autopilot.kp;
                            kiInput = bleManager.autopilot.ki;
                            kdInput = bleManager.autopilot.kd;
                            self.valuesInitialized = true;
                        }
                    }
                } else {
                    Text("Connecting...")
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()
            .navigationTitle("Autopilot Control")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
