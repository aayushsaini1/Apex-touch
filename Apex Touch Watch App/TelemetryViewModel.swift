import Combine
import Foundation
import WatchKit
import SwiftUI

class TelemetryViewModel: ObservableObject {
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
    private var currentPitStatus: UInt8 = 0

    @Published var isConnected = false
    @Published var packetsReceived = 0
    
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

    init() {
        self.ipAddress = TelemetryViewModel.getIPAddress()
        
        udpListener.$isListening
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)

        udpListener.onDataReceived = { [weak self] data in
            self?.processData(data)
        }
    }

    func start() {
        udpListener.start(port: 20777)
    }

    func stop() {
        udpListener.stop()
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
            }
        default:
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
        // Very subtle directional haptics
        if newGear > currentGear {
            // Upshift: Subtle rising feel
            WKInterfaceDevice.current().play(.directionUp)
        } else if newGear < currentGear {
            // Downshift: Subtle falling feel
            WKInterfaceDevice.current().play(.directionDown)
        }
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
}
