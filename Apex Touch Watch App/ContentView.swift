//
//  ContentView.swift
//  Apex Touch Watch App
//
//  Created by Aayush Saini on 01/01/26.
//

import Foundation
import SwiftUI

// For IP Address lookup
#if canImport(Darwin)
    import Darwin
#endif

struct ContentView: View {
    @StateObject private var viewModel = TelemetryViewModel()

    var body: some View {
        NavigationStack {
            setupView
                .navigationDestination(isPresented: $viewModel.isConnected) {
                    telemetryView
                        .navigationBarBackButtonHidden(false)
                        .toolbar {
                            // This ensures the native back button works as expected
                            // and the clock is visible in the status bar.
                        }
                }
        }
    }

    private var setupView: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            VStack(spacing: h * 0.05) {
                Spacer()
                
                Image(systemName: "f1.circle.fill")
                    .font(.system(size: h * 0.25))
                    .foregroundStyle(.linearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                
                VStack(spacing: h * 0.02) {
                    Text("APEX TOUCH")
                        .font(.system(size: h * 0.1, weight: .black, design: .monospaced))
                    
                    Text(viewModel.ipAddress)
                        .font(.system(size: h * 0.07, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Button {
                    viewModel.start()
                } label: {
                    Text("START ENGINE")
                        .font(.system(size: h * 0.08, weight: .bold, design: .monospaced))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                
                Spacer()
            }
            .frame(width: w)
        }
    }

    private var telemetryView: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Background Gradient
                RadialGradient(
                    colors: [Color(red: 0, green: 0.26, blue: 0.93), .black], // #0043ED to Black
                    center: .bottom,
                    startRadius: 0,
                    endRadius: h * 1.3
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MAIN CLUSTER (Arc + Gear)
                    // MAIN CLUSTER (Arc + Gear)
                    ZStack {
                        // 1. RPM Arc - Positioned at the top
                        ZStack {
                            // Background Track
                            Circle()
                                .trim(from: 0.6, to: 0.9)
                                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: h * 0.08, lineCap: .round))
                                .rotationEffect(.degrees(0))
                            
                            // Active Arc
                            let rpmPercent = Double(viewModel.revLightsPercent) / 90.0
                            Circle()
                                .trim(from: 0.6, to: 0.6 + (0.3 * CGFloat(min(max(rpmPercent, 0), 1.0))))
                                .stroke(
                                    rpmPercent >= 1.0 ? AnyShapeStyle(Color.purple) : AnyShapeStyle(AngularGradient(
                                        colors: [.green, .yellow, .orange, .red, Color(red: 0.8, green: 0, blue: 0.8), .purple],
                                        center: .center,
                                        startAngle: .degrees(216), // 0.6 * 360
                                        endAngle: .degrees(360)
                                    )),
                                    style: StrokeStyle(lineWidth: h * 0.08, lineCap: .round)
                                )
                                .rotationEffect(.degrees(0))
                                .animation(.linear(duration: 0.1), value: rpmPercent)
                        }
                        .frame(width: w * 0.9, height: w * 0.9)
                        .offset(y: h * 0.3) // Pull arc up to hug the top
                        
                        // 2. Central Gear & Speed - Centered in the top half
                        VStack(spacing: -h * 0.01) {
                            Text(viewModel.gear == 0 ? "N" : viewModel.gear == -1 ? "R" : "\(viewModel.gear)")
                                .font(.orbitron(size: h * 0.4, weight: 900))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2)
                            
                            HStack(alignment: .firstTextBaseline, spacing: w * 0.02) {
                                Text("\(viewModel.speed)")
                                    .font(.orbitron(size: h * 0.14, weight: 700))
                                Text("KPH")
                                    .font(.orbitron(size: h * 0.12, weight: 700))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .offset(y: h * 0.05) // Move up slightly
                    }
                    .frame(height: h * 0.45) // Reduced height to prevent crowding
                    
                    Spacer(minLength: 0)

                    // 3. BOTTOM DATA GRID
                    VStack(spacing: h * 0.02) {
                        HStack(alignment: .center) {
                            // Position
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("P")
                                    .font(.orbitron(size: h * 0.11, weight: 700))
                                    .foregroundColor(.white)
                                Text("\(viewModel.position)")
                                    .font(.orbitron(size: h * 0.11, weight: 900))
                                Text("/\(viewModel.totalCars)")
                                    .font(.orbitron(size: h * 0.11, weight: 400))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // Tyre Image from Assets
                            Image("tyre_\(viewModel.tyreCompound)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: h * 0.24, height: h * 0.24)
                        }
                        .padding(.horizontal, w * 0.1)

                        // Lap Time & Count
                        HStack(alignment: .firstTextBaseline) {
                            Text(viewModel.currentLapTime)
                                .font(.orbitron(size: h * 0.11, weight: 700))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 1) {
                                Text("LAP")
                                    .font(.orbitron(size: h * 0.11, weight: 400))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("\(viewModel.currentLap)")
                                    .font(.orbitron(size: h * 0.11, weight: 900))
                            }
                        }
                        .padding(.horizontal, w * 0.1)
                    }
                    .padding(.bottom, -h * 0.1)
                }
            }
        }
        .onDisappear {
            // Stop UDP when navigating back (e.g. swipe back or button)
            viewModel.stop()
        }
    }

    private var tyreColor: Color {
        switch viewModel.tyreCompound {
        case "S": return Color(red: 1, green: 0.1, blue: 0.1)
        case "M": return Color.yellow
        case "H": return Color.white
        case "I": return Color.green
        case "W": return Color.blue
        default: return .white
        }
    }
}

#Preview {
    ContentView()
}
