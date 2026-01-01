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
            if !viewModel.isConnected {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)

                    Text("Apex Touch")
                        .font(.headline)

                    Text("IP: \(viewModel.ipAddress)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button("Connect") {
                        viewModel.start()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section("Live Telemetry") {
                        LabeledContent("Gear", value: "\(viewModel.gear)")
                        LabeledContent("RPM", value: "\(viewModel.rpm)")
                        LabeledContent("Speed", value: "\(viewModel.speed) km/h")
                    }

                    Section("Race Info") {
                        LabeledContent("Position", value: "P\(viewModel.position)")
                        LabeledContent("Lap", value: "\(viewModel.currentLap)")
                        LabeledContent("Tyre", value: viewModel.tyreCompound)
                        LabeledContent("Last Lap", value: viewModel.lastLapTime)
                    }

                    Section("Status") {
                        LabeledContent("Packets", value: "\(viewModel.packetsReceived)")
                        Button("Disconnect", role: .destructive) {
                            viewModel.stop()
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
