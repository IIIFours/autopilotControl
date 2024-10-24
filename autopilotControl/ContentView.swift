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
                if bleManager.isConnected && bleManager.autopilot.kp != 0.0 && bleManager.autopilot.ki != 0.0 && bleManager.autopilot.kd != 0.0 {
                    VStack() {
                        HStack {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Proportional")
                                }
                            } icon: {
                                Image(systemName: "angle")
                            }
                            Stepper("", value: $kpInput, in: 0...10, step: 0.1)
                            Text("\(String(format: "%.1f", kpInput))")
                        }.padding(.bottom)
                        
                        HStack {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Integral")
                                }
                            } icon: {
                                Image(systemName: "sum")
                            }
                            Spacer()
                            Stepper("", value: $kiInput, in: 0...10, step: 0.1)
                            Text("\(String(format: "%.1f", kiInput))")
                        }.padding(.bottom)
                        
                        HStack {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Derivative")
                                }
                            } icon: {
                                Image(systemName: "function")
                            }
                            Spacer()
                            Stepper("", value: $kdInput, in: 0...10, step: 0.1)
                            Text("\(String(format: "%.1f", kdInput))")
                        }.padding(.bottom)
                        
                        Button(action: {
                            bleManager.sendUpdatedPIDValues(kpInput: kpInput, kiInput: kiInput, kdInput: kdInput);
                        }) {
                            Text("Update Gains")
                                .padding()
                                .background(Color.teal)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }.padding(.bottom)
                        HStack {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Active")
                                }
                            } icon: {
                                Image(systemName: "clock")
                            }
                            Text("\(String(format: "%.fmin", (bleManager.autopilot.previousTime/1000)/60))")
                        }.padding(.bottom)
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
                    Text("Waiting for connection...")
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
