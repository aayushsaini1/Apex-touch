import Combine
import Foundation
import WatchKit

class TelemetryViewModel: ObservableObject {
    @Published var rpm: UInt16 = 0
    @Published var gear: Int8 = 0
    @Published var speed: UInt16 = 0
    @Published var position: UInt8 = 0
    @Published var currentLap: UInt8 = 0
    @Published var lastLapTime: String = "0:00.000"
    @Published var tyreCompound: String = "Unknown"

    @Published var isConnected = false
    @Published var packetsReceived = 0
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
        case .lapData:
            let lapData = data.parseLapData(playerIndex: playerIndex)
            updateLapData(lapData)
        case .carStatus:
            let status = data.parseCarStatus(playerIndex: playerIndex)
            updateCarStatus(status)
        default:
            break
        }
    }

    private func updateTelemetry(_ data: CarTelemetryData) {
        DispatchQueue.main.async {
            if self.gear != data.gear {
                self.triggerHaptic(for: data.gear)
            }
            self.rpm = data.engineRPM
            self.gear = data.gear
            self.speed = data.speed
        }
    }

    private func updateLapData(_ data: LapData) {
        DispatchQueue.main.async {
            self.position = data.carPosition
            self.currentLap = data.currentLapNum
            self.lastLapTime = self.formatTime(data.lastLapTimeInMS)
        }
    }

    private func updateCarStatus(_ data: CarStatusData) {
        DispatchQueue.main.async {
            self.tyreCompound = self.mapTyreCompound(data.visualTyreCompound)
        }
    }

    private func triggerHaptic(for gear: Int8) {
        // Gear 0 is Neutral, -1 is Reverse
        WKInterfaceDevice.current().play(.click)
    }

    private func formatTime(_ ms: UInt32) -> String {
        let totalSeconds = Double(ms) / 1000.0
        let minutes = Int(totalSeconds / 60)
        let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, seconds)
    }

    private func mapTyreCompound(_ visualId: UInt8) -> String {
        switch visualId {
        case 16: return "S"  // Soft
        case 17: return "M"  // Medium
        case 18: return "H"  // Hard
        case 8: return "W"  // Wet
        default: return "U"  // Unknown
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
