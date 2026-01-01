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
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !viewModel.isConnected {
                    setupView
                } else {
                    telemetryView
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
                        .font(.system(size: h * 0.05, weight: .medium, design: .monospaced))
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
            
            VStack(spacing: 0) {
                // 1. Top: Gradient RPM Bar
                rpmBar
                    .frame(height: h * 0.05)
                    .padding(.top, h * 0.05)
                    .padding(.horizontal, w * 0.05)

                Spacer(minLength: 0)

                // 2. Center: Gear & Speed
                VStack(spacing: -h * 0.04) {
                    Text(viewModel.gear == 0 ? "N" : viewModel.gear == -1 ? "R" : "\(viewModel.gear)")
                        .font(.system(size: h * 0.45, weight: .black, design: .rounded))
                        .fontDesign(.monospaced)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                    
                    HStack(alignment: .firstTextBaseline, spacing: w * 0.01) {
                        Text("\(viewModel.speed)")
                            .font(.system(size: h * 0.18, weight: .bold, design: .monospaced))
                        Text("KM/H")
                            .font(.system(size: h * 0.06, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }

                Spacer(minLength: 0)

                // 3. Bottom Grid: Pos | Laps | Tyre
                HStack(spacing: 0) {
                    // Position
                    VStack(spacing: h * 0.01) {
                        Text("POS")
                            .font(.system(size: h * 0.05, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 0) {
                            Text("\(viewModel.position)")
                                .font(.system(size: h * 0.1, weight: .black, design: .monospaced))
                            Text("/\(viewModel.totalCars)")
                                .font(.system(size: h * 0.07, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: h * 0.12)

                    // Laps
                    VStack(spacing: h * 0.01) {
                        Text("LAP")
                            .font(.system(size: h * 0.05, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 0) {
                            Text("\(viewModel.currentLap)")
                                .font(.system(size: h * 0.1, weight: .black, design: .monospaced))
                            Text("/\(viewModel.totalLaps)")
                                .font(.system(size: h * 0.07, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: h * 0.12)
                        
                    // Tyre
                     VStack(spacing: h * 0.01) {
                        Text("TYRE")
                            .font(.system(size: h * 0.05, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.tyreCompound)
                            .font(.system(size: h * 0.08, weight: .black, design: .monospaced))
                            .foregroundColor(tyreColor)
                            .padding(h * 0.02)
                            .background(
                                Circle()
                                    .stroke(tyreColor, lineWidth: 2)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, h * 0.03)
                .background(
                    RoundedRectangle(cornerRadius: h * 0.06)
                        .fill(Color(white: 0.12))
                )
                .padding(.horizontal, w * 0.02)
                
                // 4. Extra: Current Lap Time
                HStack {
                    Text("LAP TIME")
                        .font(.system(size: h * 0.05, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.currentLapTime)
                        .font(.system(size: h * 0.07, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, w * 0.06)
                .padding(.vertical, h * 0.02)
                .background(
                    Capsule()
                        .fill(Color(white: 0.08))
                )
                .padding(.horizontal, w * 0.02)
                .padding(.bottom, h * 0.03)
            }
        }
        .onLongPressGesture {
            viewModel.stop()
        }
    }

    private var rpmBar: some View {
         GeometryReader { geo in
            let rpmPercent = Double(viewModel.rpm) / Double(viewModel.maxRPM)
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color(white: 0.2))
                
                // Active Gradient Bar
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.green, .red, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(min(max(rpmPercent, 0), 1.0)))
                    .animation(.linear(duration: 0.1), value: rpmPercent) // Smooth update
            }
         }
    }

    private var tyreColor: Color {
        switch viewModel.tyreCompound {
        case "S": return .red
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
