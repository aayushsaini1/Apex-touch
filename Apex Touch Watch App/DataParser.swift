import Foundation

extension Data {
    func scanValue<T>(at offset: Int) -> T {
        let size = MemoryLayout<T>.size
        guard offset + size <= self.count else {
            // Return zero-initialized memory instead of garbage
            var zeroValue = UnsafeMutablePointer<T>.allocate(capacity: 1)
            defer { zeroValue.deallocate() }
            let zeroData = Data(count: size)
            return zeroData.withUnsafeBytes { $0.loadUnaligned(as: T.self) }
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
        let entrySize = 57 // Official F1 25 LapData Entry Size
        let offset = 29 + (playerIndex * entrySize)

        return LapData(
            lastLapTimeInMS: scanValue(at: offset),         // 0
            currentLapTimeInMS: scanValue(at: offset + 4),  // 4
            sector1TimeMSPart: scanValue(at: offset + 8),
            sector1TimeMinutesPart: scanValue(at: offset + 10),
            sector2TimeMSPart: scanValue(at: offset + 11),
            sector2TimeMinutesPart: scanValue(at: offset + 13),
            deltaToCarInFrontMSPart: scanValue(at: offset + 14),
            deltaToCarInFrontMinutesPart: scanValue(at: offset + 16),
            deltaToRaceLeaderMSPart: scanValue(at: offset + 17),
            deltaToRaceLeaderMinutesPart: scanValue(at: offset + 19),
            lapDistance: scanValue(at: offset + 20),
            totalDistance: scanValue(at: offset + 24),
            safetyCarDelta: scanValue(at: offset + 28),
            carPosition: scanValue(at: offset + 32),        
            currentLapNum: scanValue(at: offset + 33),      
            pitStatus: scanValue(at: offset + 34),
            numPitStops: scanValue(at: offset + 35),
            sector: scanValue(at: offset + 36),
            currentLapInvalid: scanValue(at: offset + 37),
            penalties: scanValue(at: offset + 38),
            totalWarnings: scanValue(at: offset + 39),
            cornerCuttingWarnings: scanValue(at: offset + 40),
            numUnservedDriveThroughPens: scanValue(at: offset + 41),
            numUnservedStopGoPens: scanValue(at: offset + 42),
            gridPosition: scanValue(at: offset + 43),
            driverStatus: scanValue(at: offset + 44),
            resultStatus: scanValue(at: offset + 45),
            pitLaneTimerActive: scanValue(at: offset + 46),
            pitLaneTimeInLaneInMS: scanValue(at: offset + 47),
            pitStopTimerInMS: scanValue(at: offset + 49),
            pitStopShouldServePen: scanValue(at: offset + 51)
        )
    }

    func parseCarStatus(playerIndex: Int) -> CarStatusData {
        let entrySize = 55 // Correct size for F1 25
        let offset = 29 + (playerIndex * entrySize)

        return CarStatusData(
            tractionControl: scanValue(at: offset),
            antiLockBrakes: scanValue(at: offset + 1),
            fuelMix: scanValue(at: offset + 2),
            frontBrakeBias: scanValue(at: offset + 3),
            pitLimiterStatus: scanValue(at: offset + 4),
            fuelInTank: scanValue(at: offset + 5),
            fuelCapacity: scanValue(at: offset + 9),
            fuelRemainingLaps: scanValue(at: offset + 13),
            maxRPM: scanValue(at: offset + 17),
            idleRPM: scanValue(at: offset + 19),
            maxGears: scanValue(at: offset + 21),
            drsAllowed: scanValue(at: offset + 22),
            drsActivationDistance: scanValue(at: offset + 23),
            actualTyreCompound: scanValue(at: offset + 25),
            visualTyreCompound: scanValue(at: offset + 26),
            tyresAgeLaps: scanValue(at: offset + 27),
            vehicleFiaFlags: scanValue(at: offset + 28),
            enginePowerICE: scanValue(at: offset + 29),
            enginePowerMGUK: scanValue(at: offset + 33),
            ersStoreEnergy: scanValue(at: offset + 37),
            ersDeployMode: scanValue(at: offset + 41),
            ersHarvestedThisLapMGUK: scanValue(at: offset + 42),
            ersHarvestedThisLapMGUH: scanValue(at: offset + 46),
            ersDeployedThisLap: scanValue(at: offset + 50),
            networkPaused: scanValue(at: offset + 54)
        )
    }

    func parseParticipants(playerIndex: Int) -> ParticipantData {
        let entrySize = 57 // Official F1 25 Participants Entry Size
        let offset = 30 + (playerIndex * entrySize)
        
        // Name is 32 bytes at offset + 7
        let nameStart = offset + 7
        let nameLength = 32
        
        var nameString = "Unknown"
        if nameStart + nameLength <= self.count {
            let nameBytes = self.subdata(in: nameStart..<nameStart+nameLength)
            if let str = String(data: nameBytes, encoding: .utf8) {
                nameString = str.trimmingCharacters(in: .controlCharacters).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return ParticipantData(
            aiControlled: scanValue(at: offset),
            driverId: scanValue(at: offset + 1),
            networkId: scanValue(at: offset + 2),
            teamId: scanValue(at: offset + 3),
            myTeam: scanValue(at: offset + 4),
            raceNumber: scanValue(at: offset + 5),
            nationality: scanValue(at: offset + 6),
            name: nameString,
            yourTelemetry: scanValue(at: offset + 55),
            showOnlineNames: 1,
            platform: 1
        )
    }

    func parseSessionData() -> SessionData {
        // Header is 29 bytes
        // weather (29), trackTemp (30), airTemp (31), totalLaps (32)
        // ... see F1 23/24 packet spec
        
        return SessionData(
            totalLaps: scanValue(at: 32),
            sessionType: scanValue(at: 34),
            trackId: scanValue(at: 35),
            formula: scanValue(at: 36),
            sessionTimeLeft: scanValue(at: 37),
            sessionDuration: scanValue(at: 39),
            pitSpeedLimit: scanValue(at: 41),
            gamePaused: scanValue(at: 42),
            isSpectating: scanValue(at: 43),
            spectatorCarIndex: scanValue(at: 44),
            sliProNativeSupport: scanValue(at: 45),
            numMarshalZones: scanValue(at: 46),
            safetyCarStatus: scanValue(at: 153),
            networkGame: scanValue(at: 201),
            numWeatherForecastSamples: scanValue(at: 202),
            forecastAccuracy: scanValue(at: 250), // Simplified
            aiDifficulty: scanValue(at: 251),
            seasonLinkIdentifier: scanValue(at: 252),
            weekendLinkIdentifier: scanValue(at: 256),
            sessionMinutes: scanValue(at: 260),
            trackTemperature: scanValue(at: 30),
            airTemperature: scanValue(at: 31),
            weather: scanValue(at: 29)
        )
    }

    func parseEventData() -> EventData {
        let codeStart = 29
        let codeLength = 4
        var codeString = ""
        
        if codeStart + codeLength <= self.count {
            let codeBytes = self.subdata(in: codeStart..<codeStart+codeLength)
            codeString = String(data: codeBytes, encoding: .ascii) ?? ""
        }
        
        var vehicleIdx: UInt8? = nil
        if codeString == "RTMT" {
            // F1 25 Spec: RTMT vehicleIdx is at header (29) + code (4) = 33
            vehicleIdx = scanValue(at: 33)
        }
        
        return EventData(eventCode: codeString, vehicleIdx: vehicleIdx)
    }
}
