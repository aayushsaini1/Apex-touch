import Foundation

extension Data {
    func scanValue<T>(at offset: Int) -> T {
        let size = MemoryLayout<T>.size
        guard offset + size <= self.count else {
            // Return a default value rather than crashing if packet is malformed
            return UnsafeMutablePointer<T>.allocate(capacity: 1).pointee
        }
        return self.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: T.self) }
    }

    func parseHeader() -> PacketHeader {
        return PacketHeader(
            packetFormat: scanValue(at: 0),
            gameYear: scanValue(at: 2),
            gameMajorVersion: scanValue(at: 3),
            gameMinorVersion: scanValue(at: 4),
            packetVersion: scanValue(at: 5),
            packetId: scanValue(at: 6),
            sessionUID: scanValue(at: 7),
            sessionTime: scanValue(at: 15),
            frameIdentifier: scanValue(at: 19),
            overallFrameIdentifier: scanValue(at: 23),
            playerCarIndex: scanValue(at: 27),
            secondaryPlayerCarIndex: scanValue(at: 28)
        )
    }

    func parseCarTelemetry(playerIndex: Int) -> CarTelemetryData {
        let entrySize = 60
        let offset = 29 + (playerIndex * entrySize)

        return CarTelemetryData(
            speed: scanValue(at: offset),
            throttle: scanValue(at: offset + 2),
            steer: scanValue(at: offset + 6),
            brake: scanValue(at: offset + 10),
            clutch: scanValue(at: offset + 14),
            gear: scanValue(at: offset + 15),
            engineRPM: scanValue(at: offset + 16),
            drs: scanValue(at: offset + 18),
            revLightsPercent: scanValue(at: offset + 19),
            revLightsBitValue: scanValue(at: offset + 20),
            brakesTemperature: [
                scanValue(at: offset + 22), scanValue(at: offset + 24),
                scanValue(at: offset + 26), scanValue(at: offset + 28),
            ],
            tyresSurfaceTemperature: [
                scanValue(at: offset + 30), scanValue(at: offset + 31),
                scanValue(at: offset + 32), scanValue(at: offset + 33),
            ],
            tyresInnerTemperature: [
                scanValue(at: offset + 34), scanValue(at: offset + 35),
                scanValue(at: offset + 36), scanValue(at: offset + 37),
            ],
            engineTemperature: scanValue(at: offset + 38),
            tyresPressure: [
                scanValue(at: offset + 40), scanValue(at: offset + 44),
                scanValue(at: offset + 48), scanValue(at: offset + 52),
            ],
            surfaceType: [
                scanValue(at: offset + 56), scanValue(at: offset + 57),
                scanValue(at: offset + 58), scanValue(at: offset + 59),
            ]
        )
    }

    func parseLapData(playerIndex: Int) -> LapData {
        let entrySize = 113
        let offset = 29 + (playerIndex * entrySize)

        return LapData(
            lastLapTimeInMS: scanValue(at: offset),
            currentLapTimeInMS: scanValue(at: offset + 4),
            sector1TimeInMS: scanValue(at: offset + 8),
            sector2TimeInMS: scanValue(at: offset + 10),
            deltaToCarInFrontInMS: scanValue(at: offset + 12),
            deltaToRaceLeaderInMS: scanValue(at: offset + 14),
            lapDistance: scanValue(at: offset + 16),
            totalDistance: scanValue(at: offset + 20),
            safetyCarDelta: scanValue(at: offset + 24),
            carPosition: scanValue(at: offset + 28),
            currentLapNum: scanValue(at: offset + 29),
            pitStatus: scanValue(at: offset + 30),
            numPitStops: scanValue(at: offset + 31),
            sector: scanValue(at: offset + 32),
            currentLapInvalid: scanValue(at: offset + 33),
            penalties: scanValue(at: offset + 34),
            totalWarnings: scanValue(at: offset + 35),
            cornerCuttingWarnings: scanValue(at: offset + 36),
            numUnservedDriveThroughPens: scanValue(at: offset + 37),
            numUnservedStopGoPens: scanValue(at: offset + 38),
            gridPosition: scanValue(at: offset + 39),
            driverStatus: scanValue(at: offset + 40),
            resultStatus: scanValue(at: offset + 41),
            pitLaneTimerActive: scanValue(at: offset + 42),
            pitLaneTimeInLaneInMS: scanValue(at: offset + 43),
            pitStopTimerInMS: scanValue(at: offset + 45),
            pitStopShouldServePen: scanValue(at: offset + 47)
        )
    }

    func parseCarStatus(playerIndex: Int) -> CarStatusData {
        let entrySize = 115
        let offset = 29 + (playerIndex * entrySize)

        return CarStatusData(
            tractionControl: scanValue(at: offset),
            antiLockBrakes: scanValue(at: offset + 1),
            fuelMix: scanValue(at: offset + 2),
            fuelInTank: scanValue(at: offset + 3),
            fuelCapacity: scanValue(at: offset + 7),
            fuelRemainingLaps: scanValue(at: offset + 11),
            maxRPM: scanValue(at: offset + 15),
            idleRPM: scanValue(at: offset + 17),
            maxGears: scanValue(at: offset + 19),
            drsAllowed: scanValue(at: offset + 20),
            drsActivationDistance: scanValue(at: offset + 21),
            actualTyreCompound: scanValue(at: offset + 23),
            visualTyreCompound: scanValue(at: offset + 24),
            tyresAgeLaps: scanValue(at: offset + 25),
            vehicleFiaFlags: scanValue(at: offset + 26),
            enginePowerICE: scanValue(at: offset + 27),
            enginePowerMGUK: scanValue(at: offset + 31),
            ersStoreEnergy: scanValue(at: offset + 35),
            ersDeployMode: scanValue(at: offset + 39),
            ersHarvestedThisLapMGUK: scanValue(at: offset + 40),
            ersHarvestedThisLapMGUH: scanValue(at: offset + 44),
            ersDeployedThisLap: scanValue(at: offset + 48),
            networkPaused: scanValue(at: offset + 52)
        )
    }
}
