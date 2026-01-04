import Foundation
import SwiftUI

// For IP Address lookup
#if canImport(Darwin)
    import Darwin
#endif

struct ContentView: View {
    @StateObject private var viewModel = TelemetryViewModel()
    @State private var showDemoMenu = false

    var body: some View {
        NavigationStack {
            setupView
                .navigationDestination(isPresented: $viewModel.isConnected) {
                    telemetryView
                }
        }
    }

    private var setupView: some View {
        GeometryReader { geo in
            let h = geo.size.height
            
            VStack(spacing: h * 0.05) {
                Spacer()
                
                Image(systemName: "f1.circle.fill")
                    .font(.system(size: h * 0.25))
                    .foregroundStyle(.linearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                
                VStack(spacing: h * 0.02) {
                    Text("APEX TOUCH")
                        .font(.orbitron(size: h * 0.1, weight: 900))
                    
                    Text(viewModel.ipAddress)
                        .font(.system(size: h * 0.07, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Button {
                    viewModel.start()
                } label: {
                    Text("START ENGINE")
                        .font(.orbitron(size: h * 0.08, weight: 700))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                
                Button {
                    showDemoMenu = true
                } label: {
                    Text("DEMO MODE")
                        .font(.orbitron(size: h * 0.06, weight: 600))
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .controlSize(.regular)
                .padding(.top, h * 0.02)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .navigationDestination(isPresented: $showDemoMenu) {
            DemoMenuView(viewModel: viewModel)
        }
    }

    struct DemoMenuView: View {
        @ObservedObject var viewModel: TelemetryViewModel
        
        var body: some View {
            GeometryReader { geo in
                let h = geo.size.height
                ScrollView {
                    VStack(spacing: h * 0.03) {
                        Text("SELECT MODE")
                            .font(.orbitron(size: h * 0.1, weight: 700))
                            .padding(.vertical, h * 0.02)
                        
                        demoButton(title: "Race Demo", color: .red, h: h) {
                            viewModel.startRaceDemo()
                        }
                        
                        demoButton(title: "Safety Car", color: .yellow, h: h) {
                            viewModel.startSafetyCarDemo()
                        }
                        
                        demoButton(title: "Pit Lane", color: .orange, h: h) {
                            viewModel.startPitLaneDemo()
                        }
                        
                        demoButton(title: "Chequered Flag", color: .green, h: h) {
                            viewModel.startChequeredFlagDemo()
                        }
                        
                        demoButton(title: "DNF State", color: .gray, h: h) {
                            viewModel.startDNFDemo()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        func demoButton(title: String, color: Color, h: CGFloat, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(title)
                    .font(.orbitron(size: h * 0.06, weight: 600))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .controlSize(.large)
        }
    }
    
    // Extracted TelemetryView to be reusable
    struct TelemetryView: View {
        @ObservedObject var viewModel: TelemetryViewModel
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack {
                    // 1. DNF State Coverage
                    if viewModel.resultStatus >= 4 && viewModel.resultStatus <= 7 {
                        RadialGradient(
                            colors: [Color(white: 0.1), Color(white: 0.35)],
                            center: .top,
                            startRadius: 0,
                            endRadius: h
                        )
                        .ignoresSafeArea()
                        
                        Text("DNF")
                            .font(.orbitron(size: h * 0.25, weight: 900))
                            .foregroundColor(.white)
                    } else {
                        // 2. Active Session Backgrounds
                        if viewModel.safetyCarStatus == 1 || viewModel.safetyCarStatus == 2 {
                            Color.yellow.ignoresSafeArea()
                        } else {
                            RadialGradient(
                                colors: [viewModel.teamColor, .black],
                                center: .bottom,
                                startRadius: 0,
                                endRadius: h * 1.3
                            )
                            .ignoresSafeArea()
                        }

                        // 3. Telemetry Content
                        let isSafetyCar = viewModel.safetyCarStatus == 1 || viewModel.safetyCarStatus == 2
                        let contentColor: Color = isSafetyCar ? .black : .white
                        let secondaryColor: Color = isSafetyCar ? .black.opacity(0.6) : .white.opacity(0.4)

                        VStack(spacing: 0) {
                            // MAIN CLUSTER
                            ZStack {
                                if viewModel.sessionEnded {
                                    // CHEQUERED FLAG FINISH STATE
                                    ZStack {
                                        // 2. Top Chequered Pattern
                                        Image("flag_header") 
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: w * 1.1, height: h * 0.4)
                                            .position(x: w/2, y: h * 0.08)
                                        
                                        VStack(spacing: h * 0.02) {
                                            Text("Chequered Flag")
                                                .font(.orbitron(size: h * 0.08, weight: 400))
                                                .foregroundStyle(.white.opacity(0.8))
                                                .padding(.top, h * 0.15)
                                            
                                            Group {
                                                Text("P\(viewModel.position)")
                                                    .font(.orbitron(size: h * 0.35, weight: 900))
                                                    .foregroundStyle(.white)
                                            }
                                            .padding(.vertical, h * 0.02)
                                            
                                            HStack(alignment: .firstTextBaseline, spacing: w * 0.02) {
                                                Text("\(viewModel.speed)")
                                                    .font(.orbitron(size: h * 0.12, weight: 700))
                                                    .foregroundStyle(.white)
                                                Text("kph")
                                                    .font(.orbitron(size: h * 0.1, weight: 400))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                } else {
                                    // STANDARD RPM/GEAR CLUSTER
                                    ZStack {
                                        Circle()
                                            .trim(from: 0.6, to: 0.9)
                                            .stroke(contentColor.opacity(0.12), style: StrokeStyle(lineWidth: h * 0.08, lineCap: .round))
                                        
                                        let rpmPercent = Double(viewModel.revLightsPercent) / 90.0
                                        Circle()
                                            .trim(from: 0.6, to: 0.6 + (0.3 * CGFloat(min(max(rpmPercent, 0), 1.0))))
                                            .stroke(
                                                rpmPercent >= 1.0 ? AnyShapeStyle(Color.purple) : AnyShapeStyle(AngularGradient(
                                                    colors: [.green, .yellow, .orange, .red, Color(red: 0.8, green: 0, blue: 0.8), .purple],
                                                    center: .center,
                                                    startAngle: .degrees(216),
                                                    endAngle: .degrees(360)
                                                )),
                                                style: StrokeStyle(lineWidth: h * 0.08, lineCap: .round)
                                            )
                                            .animation(.linear(duration: 0.1), value: rpmPercent)
                                    }
                                    .frame(width: w * 0.9, height: w * 0.9)
                                    .offset(y: h * 0.3)
                                    
                                    // Gear & Speed
                                    VStack(spacing: -h * 0.01) {
                                        if viewModel.currentPitStatus == 1 {
                                            Text("IN PIT")
                                                .font(.orbitron(size: h * 0.18, weight: 900))
                                                .foregroundStyle(.yellow)
                                                .padding(.bottom, h * 0.05)
                                        } else {
                                            Text(viewModel.gear == 0 ? "N" : viewModel.gear == -1 ? "R" : "\(viewModel.gear)")
                                                .font(.orbitron(size: h * 0.4, weight: 900))
                                                .foregroundStyle(contentColor)
                                        }
                                        
                                        HStack(alignment: .firstTextBaseline, spacing: w * 0.02) {
                                            Text("\(viewModel.speed)")
                                                .font(.orbitron(size: h * 0.14, weight: 700))
                                                .foregroundStyle(contentColor)
                                            Text("KPH")
                                                .font(.orbitron(size: h * 0.12, weight: 700))
                                                .foregroundColor(secondaryColor)
                                        }
                                    }
                                    .offset(y: h * 0.05)
                                }
                            }
                            .frame(height: h * 0.45)
                            
                            Spacer(minLength: 0)

                            // BOTTOM DATA GRID
                            VStack(spacing: h * 0.02) {
                                HStack(alignment: .center) {
                                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                                        Text("P")
                                            .font(.orbitron(size: h * 0.11, weight: 700))
                                            .foregroundColor(contentColor)
                                        Text("\(viewModel.position)")
                                            .font(.orbitron(size: h * 0.11, weight: 900))
                                            .foregroundColor(contentColor)
                                        Text("/\(viewModel.totalCars)")
                                            .font(.orbitron(size: h * 0.11, weight: 400))
                                            .foregroundColor(secondaryColor)
                                    }
                                    
                                    Spacer()
                                    
                                    Image("tyre_\(viewModel.tyreCompound)")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: h * 0.24, height: h * 0.24)
                                }
                                .padding(.horizontal, w * 0.1)

                                if isSafetyCar {
                                    // Safety Car Overlay Text
                                    Text("SAFETY CAR")
                                        .font(.orbitron(size: h * 0.12, weight: 900))
                                        .foregroundColor(.black)
                                        .padding(.bottom, h * 0.02)
                                } else {
                                    // Standard Lap Time & Count
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(viewModel.currentLapTime)
                                            .font(.orbitron(size: h * 0.09, weight: 700))
                                            .foregroundColor(contentColor)
                                        
                                        Spacer()
                                        
                                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                                            Text("LAP")
                                                .font(.orbitron(size: h * 0.09, weight: 400))
                                                .foregroundColor(secondaryColor)
                                            Text("\(viewModel.currentLap)")
                                                .font(.orbitron(size: h * 0.09, weight: 900))
                                                .foregroundColor(contentColor)
                                            Text("/\(viewModel.totalLaps)")
                                                .font(.orbitron(size: h * 0.09, weight: 400))
                                                .foregroundColor(secondaryColor)
                                        }
                                    }
                                    .padding(.horizontal, w * 0.1)
                                }
                            }
                            .padding(.bottom, -h * 0.1)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .onDisappear {
                viewModel.stop()
            }
        }
    }

    private var telemetryView: some View {
        TelemetryView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
