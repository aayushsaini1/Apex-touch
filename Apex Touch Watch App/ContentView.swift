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
                if !viewModel.isConnected {
                    setupView
                } else {
                    telemetryView
                }
            }
            .background(backgroundColor.ignoresSafeArea())
        }
    }

    private var setupView: some View {
        VStack(spacing: 12) {
            Image(systemName: "f1.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.linearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
            
            VStack(spacing: 4) {
                Text("APEX TOUCH")
                    .font(.system(.headline, design: .monospaced))
                    .fontWeight(.black)
                
                Text(viewModel.ipAddress)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Button {
                viewModel.start()
            } label: {
                Text("START ENGINE")
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    private var telemetryView: some View {
        VStack(spacing: 0) {
            // Top HUD
            HStack {
                VStack(alignment: .leading) {
                    Text("POS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("\(viewModel.position)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.black)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("LAP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("\(viewModel.currentLap)")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.black)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Spacer()

            // Gear and Speed
            VStack(spacing: -10) {
                Text(viewModel.gear == 0 ? "N" : viewModel.gear == -1 ? "R" : "\(viewModel.gear)")
                    .font(.system(size: 90, weight: .black, design: .rounded))
                    .italic()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(viewModel.speed)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                    Text("KM/H")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Bottom Info
            HStack {
                Text(viewModel.tyreCompound)
                    .font(.system(size: 14, weight: .black))
                    .padding(6)
                    .background(Circle().stroke(tyreColor, lineWidth: 2))
                
                Spacer()
                
                Text(viewModel.lastLapTime)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .overlay(alignment: .top) {
             revBar
        }
        .onLongPressGesture {
            viewModel.stop()
        }
    }

    private var revBar: some View {
        GeometryReader { geo in
            let rpmPercent = Double(viewModel.rpm) / Double(viewModel.maxRPM)
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: geo.size.width * CGFloat(min(rpmPercent, 1.0)))
            }
        }
        .frame(height: 4)
    }

    private var backgroundColor: Color {
        guard viewModel.isConnected else { return Color.black }
        
        let rpmPercent = Double(viewModel.rpm) / Double(viewModel.maxRPM)
        
        if rpmPercent > 0.98 {
            return Color.purple
        } else if rpmPercent > 0.90 {
            return Color.red
        } else if rpmPercent > 0.82 {
            return Color.orange
        } else if rpmPercent > 0.70 {
            return Color.green
        } else {
            return Color.black
        }
    }

    private var tyreColor: Color {
        switch viewModel.tyreCompound {
        case "S": return .red
        case "M": return .yellow
        case "H": return .white
        case "I": return .green
        case "W": return .blue
        default: return .gray
        }
    }
}


#Preview {
    ContentView()
}
