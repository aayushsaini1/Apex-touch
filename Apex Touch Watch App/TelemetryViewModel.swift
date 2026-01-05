import Combine
import Foundation
import WatchKit
import SwiftUI

class TelemetryViewModel: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    @Published var rpm: UInt16 = 0
    @Published var gear: Int8 = 0
    @Published var speed: UInt16 = 0
    @Published var position: UInt8 = 0
    @Published var currentLap: UInt8 = 0
    // @Published var lastLapTime: String = "0:00.000"
    @Published var currentLapTime: String = "0:00.000"
    @Published var tyreCompound: String = "U"
    @Published var driverName: String = "FER"
    @Published var maxRPM: UInt16 = 12000 // Default for F1
    @Published var revLightsPercent: UInt8 = 0
    @Published var totalLaps: UInt8 = 0
    @Published var totalCars: UInt8 = 20 // Default
    @Published var safetyCarStatus: UInt8 = 0
    @Published var resultStatus: UInt8 = 2 // Default to Active
    @Published var teamId: UInt8 = 255
    
    private var lastLapNum: UInt8 = 0
    @Published var currentPitStatus: UInt8 = 0

    @Published var isConnected = false
    @Published var isInDemoMode = false
    @Published var sessionEnded = false
    @Published var packetsReceived = 0
    
    private var demoTimer: Timer?
    private var staticFluctuationTimer: Timer?
    private var demoStartTime: Date?
    
    private var extendedSession: WKExtendedRuntimeSession?
    
    var teamColor: Color {
        switch teamId {
        case 0: return Color(red: 0.0, green: 0.63, blue: 0.61) // Mercedes (Teal)
        case 1: return Color(red: 0.94, green: 0.10, blue: 0.17) // Ferrari (Red)
        case 2: return Color(red: 0.02, green: 0.0, blue: 0.94) // Red Bull (Navy)
        case 3: return Color(red: 0.0, green: 0.35, blue: 1.0) // Williams (Blue)
        case 4: return Color(red: 0.0, green: 0.44, blue: 0.38) // Aston Martin (Green)
        case 5: return Color(red: 0.0, green: 0.36, blue: 0.66) // Alpine (Blue)
        case 6: return Color(red: 0.4, green: 0.57, blue: 1.0) // RB (VCARB Blue)
        case 7: return Color(red: 0.71, green: 0.73, blue: 0.74) // Haas (Gray)
        case 8: return Color(red: 1.0, green: 0.53, blue: 0.0) // McLaren (Orange)
        case 9: return Color(red: 0.32, green: 0.89, blue: 0.32) // Sauber (Neon Green)
        default: return Color(red: 0, green: 0.26, blue: 0.93) // Generic F1 Blue
        }
    }
    @Published var ipAddress: String = "Detecting..."

    private let udpListener = UDPListener()
    private var bag = Set<AnyCancellable>()

    override init() {
        super.init()
        self.ipAddress = TelemetryViewModel.getIPAddress()
        
        udpListener.$isListening
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isListening in
                // Only update isConnected if we are NOT in demo mode
                // If in demo mode, we want to stay connected regardless of UDP state
                guard let self = self else { return }
                if !self.isInDemoMode {
                    self.isConnected = isListening
                }
            }
            .store(in: &bag)

        udpListener.onDataReceived = { [weak self] data in
            self?.processData(data)
        }
    }

    func start() {
        startExtendedSession()
        udpListener.start(port: 20777)
    }

    func stop() {
        stopExtendedSession()
        udpListener.stop()
        demoTimer?.invalidate()
        demoTimer = nil
        staticFluctuationTimer?.invalidate()
        staticFluctuationTimer = nil
        isInDemoMode = false
        sessionEnded = false
        resultStatus = 2 // Reset to Active
        currentPitStatus = 0
        safetyCarStatus = 0
        gear = 0
        speed = 0
        rpm = 0
    }

    private func processData(_ data: Data) {
        guard data.count >= PacketHeader.size else {
            print("Telemetry: Packet too small (\(data.count))")
            return
        }

        let header = data.parseHeader()
        let playerIndex = Int(header.playerCarIndex)

        // Only update packetsReceived occasionally or silently to save UI cycles
        if header.frameIdentifier % 20 == 0 {
             DispatchQueue.main.async {
                 self.packetsReceived += 1
             }
        }

        switch PacketID(rawValue: header.packetId) {
        case .carTelemetry:
            let telemetry = data.parseCarTelemetry(playerIndex: playerIndex)
            updateTelemetry(telemetry)
        case .session:
            let session = data.parseSessionData()
            DispatchQueue.main.async {
                self.totalLaps = session.totalLaps
                self.safetyCarStatus = session.safetyCarStatus
            }
        case .lapData:
            let lapData = data.parseLapData(playerIndex: playerIndex)
            updateLapData(lapData)
        case .participants:
            let participant = data.parseParticipants(playerIndex: playerIndex)
            let numActiveCars = data.scanValue(at: 29) as UInt8 // From Header
            DispatchQueue.main.async {
                 if numActiveCars > 0 {
                     self.totalCars = numActiveCars
                 }
                 self.teamId = participant.teamId
                 if !participant.name.isEmpty {
                    // Take first 3 letters, uppercased
                    let shortName = participant.name.prefix(3).uppercased()
                    self.driverName = String(shortName)
                 }
            }
        case .carStatus:
            let status = data.parseCarStatus(playerIndex: playerIndex)
            updateCarStatus(status)
        case .event:
            let event = data.parseEventData()
            if event.eventCode == "RTMT", let idx = event.vehicleIdx, idx == playerIndex {
                DispatchQueue.main.async {
                    self.resultStatus = 4 // Force DNF state
                }
            } else if event.eventCode == "CHQF" { // Chequered Flag
                 DispatchQueue.main.async {
                     self.sessionEnded = true
                 }
            }
        // PacketID 10 is Final Classification, can also be used as a trigger
        default:
            if header.packetId == 10 { // Final Classification
                 DispatchQueue.main.async {
                     self.sessionEnded = true
                 }
            }
            break
        }
    }

    private func updateTelemetry(_ data: CarTelemetryData) {
        DispatchQueue.main.async {
            if self.gear != data.gear {
                self.triggerHaptic(currentGear: self.gear, newGear: data.gear)
            }
            self.rpm = data.engineRPM
            self.revLightsPercent = data.revLightsPercent
            self.gear = data.gear
            self.speed = data.speed
        }
    }

    private func updateLapData(_ data: LapData) {
        DispatchQueue.main.async {
            // Display only when > 0
            self.position = data.carPosition
            self.currentLap = data.currentLapNum
            self.currentPitStatus = data.pitStatus
            
            /*
            // Logic Guarding: Only refresh last lap time when lap increases
            if data.currentLapNum > self.lastLapNum {
                if data.lastLapTimeInMS > 0 && data.lastLapTimeInMS != 4294967295 {
                    self.lastLapTime = self.formatTime(data.lastLapTimeInMS)
                }
                self.lastLapNum = data.currentLapNum
            }
            */
            self.lastLapNum = data.currentLapNum
            self.resultStatus = data.resultStatus
            
            self.currentLapTime = self.formatTime(data.currentLapTimeInMS)
        }
    }

    private func updateCarStatus(_ data: CarStatusData) {
        DispatchQueue.main.async {
            // Tyre Pit Exit Lock: Only update if not in pits (pitStatus == 0)
            if self.currentPitStatus == 0 {
                self.tyreCompound = self.mapTyreCompound(data.visualTyreCompound)
            }
            
            if data.maxRPM > 0 {
                self.maxRPM = data.maxRPM
            }
        }
    }

    private func formatTime(_ ms: UInt32) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let milliseconds = ms % 1000
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }

    private func triggerHaptic(currentGear: Int8, newGear: Int8) {
        // Use custom HapticManager for silent gear shifts
        HapticManager.shared.triggerGearShift(isUpshift: newGear > currentGear)
    }

    private func mapTyreCompound(_ visualId: UInt8) -> String {
        // Log raw value for debugging
        print("Tyre Visual ID: \(visualId)")
        
        switch visualId {
        case 16, 0: return "S" // Soft
        case 17, 1: return "M" // Medium
        case 18, 2: return "H" // Hard
        case 7, 3:  return "I" // Inter
        case 8, 4:  return "W" // Wet
        default: return "U" // Unknown
        }
    }
    
    func startRaceDemo() {
        stop() // Reset any active state
        startExtendedSession()
        
        // Order matters: Set Flag FIRST, then connect
        isInDemoMode = true
        isConnected = true
        
        teamId = 1 // Ferrari
        currentLap = 1
        totalLaps = 2
        totalCars = 22
        tyreCompound = "S"
        maxRPM = 13500
        demoStartTime = Date()
        
        demoTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateDemoState()
        }
    }
    
    // Static Demos
    func startSafetyCarDemo() {
        setupStaticDemo()
        safetyCarStatus = 1
        speed = 120
        gear = 3
        rpm = 5500
        position = 4
    }
    
    func startPitLaneDemo() {
        setupStaticDemo()
        currentPitStatus = 1
        speed = 80
        limitSpeedToPit()
    }
    
    func startChequeredFlagDemo() {
        setupStaticDemo()
        sessionEnded = true
        position = 1
        speed = 310
    }
    
    func startDNFDemo() {
        setupStaticDemo()
        resultStatus = 4 // DNF
    }
    
    private func setupStaticDemo() {
        stop()
        startExtendedSession()
        isInDemoMode = true
        isConnected = true
        teamId = 1 // Ferrari
        currentLap = 5
        totalLaps = 50
        totalCars = 20
        tyreCompound = "M"
        maxRPM = 13500
        
        // Start subtle fluctuation timer for realism
        staticFluctuationTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.applySubtleFluctuation()
        }
    }
    
    private func applySubtleFluctuation() {
        // Add very small random fluctuation to RPM (±2-3%)
        if rpm > 0 {
            let baseRPM = Double(rpm)
            let fluctuation = Double.random(in: -0.03...0.03) * baseRPM
            rpm = UInt16(max(1000, baseRPM + fluctuation))
            
            // Update rev lights percentage accordingly
            revLightsPercent = UInt8((Double(rpm) / Double(maxRPM)) * 100)
        }
    }
    
    private func limitSpeedToPit() {
         // Helper to ensure gear logic handles 'IN PIT' text if needed
         gear = 1 
    }
    
    private func updateDemoState() {
        guard let startTime = demoStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        
        DispatchQueue.main.async {
            // End Demo after 120s
            if elapsed >= 120 {
                self.stop()
                return
            }
            
            
            // Simulated Lap Timer Logic
            // Reset when entering pits (Phase 4 starts at 70s)
            if elapsed >= 70 && elapsed < 70.2 {
                self.currentLapTime = "0:00.000"
            } else if elapsed < 70 {
                // Lap 1 Timer
                let lapTimeMs = UInt32(elapsed * 1000)
                self.currentLapTime = self.formatTime(lapTimeMs)
            } else if elapsed >= 90 {
                // Lap 2 Timer (Starts counting after pit exit at 90s)
                let lapTimeMs = UInt32((elapsed - 90) * 1000)
                self.currentLapTime = self.formatTime(lapTimeMs)
            }

            // Phase Logic
            if elapsed < 30 {
                // Phase 1: Acceleration (0-30s)
                self.safetyCarStatus = 0
                self.currentPitStatus = 0
                let progress = elapsed / 30.0
                self.speed = UInt16(min(330, elapsed * 15)) // Accelerate
                
                // Position logic
                if elapsed < 10 { self.position = 10 }
                else if elapsed < 15 { self.position = 9 }
                else if elapsed < 20 { self.position = 8 }
                else if elapsed < 25 { self.position = 7 }
                else { self.position = 6 }
                
                self.updateSimulatedPhysics(speed: Double(self.speed))
                
            } else if elapsed < 50 {
                // Phase 2: Safety Car (30-50s)
                self.safetyCarStatus = 1
                self.speed = 120
                self.position = 5
                self.updateSimulatedPhysics(speed: 120)
                
            } else if elapsed < 70 {
                // Phase 3: Restart (50-70s)
                self.safetyCarStatus = 0
                let p = (elapsed - 50) / 20.0
                self.speed = UInt16(120 + (190 * p))
                self.position = 5
                self.updateSimulatedPhysics(speed: Double(self.speed))
                
            } else if elapsed < 90 {
                // Phase 4: Pit Window (70-90s)
                self.currentPitStatus = 1
                self.speed = 80
                self.position = 9
                self.updateSimulatedPhysics(speed: 80)
                
            } else if elapsed < 115 {
                // Phase 5: Final Climb (90-115s)
                self.currentPitStatus = 0
                
                // Demo Logic: Increment Lap on Pit Exit
                if self.currentLap == 1 { self.currentLap = 2 }

                let p = (elapsed - 90) / 25.0
                self.speed = UInt16(80 + (260 * p))
                
                if elapsed < 95 { self.position = 7 }
                else if elapsed < 100 { self.position = 4 }
                else if elapsed < 105 { self.position = 2 }
                else { 
                    self.position = 1 
                }
                self.updateSimulatedPhysics(speed: Double(self.speed))
                
            } else {
                // Phase 6: Session End (115-120s)
                self.speed = 340
                self.position = 1
                self.sessionEnded = true // Trigger Chequered Flag UI
                // self.updateSimulatedPhysics(speed: 340) // No need physics, UI replaced
            }
        }
    }
    
    private func updateSimulatedPhysics(speed: Double) {
        // Simple sawtooth RPM mapping based on speed thresholds (8 gears)
        let thresholds: [Double] = [0, 40, 80, 120, 160, 210, 260, 310, 400]
        var simulatedGear: Int8 = 1
        for i in 0..<thresholds.count-1 {
            if speed >= thresholds[i] && speed < thresholds[i+1] {
                simulatedGear = Int8(i + 1)
                break
            }
        }
        
        if self.gear != simulatedGear {
            self.triggerHaptic(currentGear: self.gear, newGear: simulatedGear)
            self.gear = simulatedGear
        }
        
        // RPM mapping
        let gearStart = thresholds[Int(simulatedGear-1)]
        let gearEnd = thresholds[Int(simulatedGear)]
        let gearRange = gearEnd - gearStart
        let gearProgress = (speed - gearStart) / gearRange
        
        // RPM goes from 10k to 13.5k in each gear
        var simulatedRPM = 10000 + (3500 * gearProgress)
        
        // Fluctuation/Noise for realism
        if speed > 300 || simulatedRPM > 13000 {
            // High speed/RPM: 5-10% variance
            let noise = Double.random(in: -0.05...0.05) * simulatedRPM
            simulatedRPM += noise
        } else if speed < 150 {
            // Safety car / low speed: 5-8% variance for more visible fluctuation
            let noise = Double.random(in: -0.08...0.08) * simulatedRPM
            simulatedRPM += noise
        }
        
        self.rpm = UInt16(simulatedRPM)
        
        // Flash Purple logic: If > 95%, force it to range that triggers purple
        var percent = (simulatedRPM / 13500.0)
        
        // If near redline (optimal shift), make it flash 100% occasionally
        if percent > 0.95 {
             // 50/50 chance to hit 100% (Purple) vs 95% (Red) to create "flash" effect
             if Bool.random() { percent = 1.0 }
        }
        
        self.revLightsPercent = UInt8(percent * 100)
    }

    static func getIPAddress() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee,
                      let addr = interface.ifa_addr else { continue }
                let addrFamily = addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    if let name = interface.ifa_name, String(cString: name) == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? "No Wi-Fi"
    }

    // MARK: - WKExtendedRuntimeSession Management

    private func startExtendedSession() {
        guard extendedSession == nil else { return }
        
        // .smartHome is a good fit for monitoring external telemetry data
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = self
        extendedSession?.start()
        print("Extended Runtime Session Started")
    }

    private func stopExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = nil
        print("Extended Runtime Session Stopped")
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session did start")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended runtime session will expire")
        // Optionally restart the session if still connected
        if isConnected || isInDemoMode {
            stopExtendedSession()
            startExtendedSession()
        }
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Extended runtime session invalidated: \(reason.rawValue)")
        if let error = error {
            print("Session error: \(error.localizedDescription)")
        }
        extendedSession = nil
    }
}
