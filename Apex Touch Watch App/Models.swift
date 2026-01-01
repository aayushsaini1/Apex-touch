import Foundation

struct PacketHeader {
    let packetFormat: UInt16
    let gameYear: UInt8
    let gameMajorVersion: UInt8
    let gameMinorVersion: UInt8
    let packetVersion: UInt8
    let packetId: UInt8
    let sessionUID: UInt64
    let sessionTime: Float
    let frameIdentifier: UInt32
    let overallFrameIdentifier: UInt32
    let playerCarIndex: UInt8
    let secondaryPlayerCarIndex: UInt8
    
    static let size = 29 // 2 + 1 + 1 + 1 + 1 + 1 + 8 + 4 + 4 + 4 + 1 + 1
}

enum PacketID: UInt8 {
    case motion = 0
    case session = 1
    case lapData = 2
    case event = 3
    case participants = 4
    case carSetups = 5
    case carTelemetry = 6
    case carStatus = 7
    case finalClassification = 8
    case lobbyInfo = 9
    case carDamage = 10
    case sessionHistory = 11
    case tyreSets = 12
    case motionEx = 13
}

struct SessionData {
    let totalLaps: UInt8
    let sessionType: UInt8
    let trackId: Int8
    let formula: UInt8
    let sessionTimeLeft: UInt16
    let sessionDuration: UInt16
    let pitSpeedLimit: UInt8
    let gamePaused: UInt8
    let isSpectating: UInt8
    let spectatorCarIndex: UInt8
    let sliProNativeSupport: UInt8
    let numMarshalZones: UInt8
    // ... marshals zones parsing omitted for brevity
    let safetyCarStatus: UInt8
    let networkGame: UInt8
    let numWeatherForecastSamples: UInt8
    // ... weather samples omitted
    let forecastAccuracy: UInt8
    let aiDifficulty: UInt8
    let seasonLinkIdentifier: UInt32
    let weekendLinkIdentifier: UInt32
    let sessionMinutes: UInt8
    let trackTemperature: Int8
    let airTemperature: Int8
    let weather: UInt8
}

struct CarTelemetryData {
    let speed: UInt16
    let throttle: Float
    let steer: Float
    let brake: Float
    let clutch: UInt8
    let gear: Int8
    let engineRPM: UInt16
    let drs: UInt8
    let revLightsPercent: UInt8
    let revLightsBitValue: UInt16
    let brakesTemperature: [UInt16] // 4
    let tyresSurfaceTemperature: [UInt8] // 4
    let tyresInnerTemperature: [UInt8] // 4
    let engineTemperature: UInt16
    let tyresPressure: [Float] // 4
    let surfaceType: [UInt8] // 4
}

struct LapData {
    let lastLapTimeInMS: UInt64
    let currentLapTimeInMS: UInt64
    let sector1TimeInMS: UInt16
    let sector2TimeInMS: UInt16
    let deltaToCarInFrontInMS: UInt16
    let deltaToRaceLeaderInMS: UInt16
    let lapDistance: Float
    let totalDistance: Float
    let safetyCarDelta: Float
    let carPosition: UInt8
    let currentLapNum: UInt8
    let pitStatus: UInt8
    let numPitStops: UInt8
    let sector: UInt8
    let currentLapInvalid: UInt8
    let penalties: UInt8
    let totalWarnings: UInt8
    let cornerCuttingWarnings: UInt8
    let numUnservedDriveThroughPens: UInt8
    let numUnservedStopGoPens: UInt8
    let gridPosition: UInt8
    let driverStatus: UInt8
    let resultStatus: UInt8
    let pitLaneTimerActive: UInt8
    let pitLaneTimeInLaneInMS: UInt16
    let pitStopTimerInMS: UInt16
    let pitStopShouldServePen: UInt8
}

struct CarStatusData {
    let tractionControl: UInt8
    let antiLockBrakes: UInt8
    let fuelMix: UInt8
    let fuelInTank: Float
    let fuelCapacity: Float
    let fuelRemainingLaps: Float
    let maxRPM: UInt16
    let idleRPM: UInt16
    let maxGears: UInt8
    let drsAllowed: UInt8
    let drsActivationDistance: UInt16
    let actualTyreCompound: UInt8
    let visualTyreCompound: UInt8
    let tyresAgeLaps: UInt8
    let vehicleFiaFlags: Int8
    let enginePowerICE: Float
    let enginePowerMGUK: Float
    let ersStoreEnergy: Float
    let ersDeployMode: UInt8
    let ersHarvestedThisLapMGUK: Float
    let ersHarvestedThisLapMGUH: Float
    let ersDeployedThisLap: Float
    let networkPaused: UInt8
}

struct ParticipantData {
    let aiControlled: UInt8
    let driverId: UInt8
    let networkId: UInt8
    let teamId: UInt8
    let myTeam: UInt8
    let raceNumber: UInt8
    let nationality: UInt8
    let name: String
    let yourTelemetry: UInt8
    let showOnlineNames: UInt8
    let platform: UInt8
}
