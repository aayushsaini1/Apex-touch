import WatchKit

class HapticManager {
    static let shared = HapticManager()
    
    func triggerGearShift(isUpshift: Bool) {
        // Since all other WKHapticTypes (success, directionUp, etc.) include an audio tone,
        // we use a "burst" of .click haptics to create a heavier, mechanical feel 
        // without triggering the system speaker.
        
        let count = isUpshift ? 6 : 4
        let interval = 0.02 // 20ms between pulses for a "heavy" combined feel
        
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * interval)) {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }
}
