//
//  InternalBattery.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

// https://stackoverflow.com/questions/57145091/swift-macos-batterylevel-property

#if os(macOS)

public class InternalBattery {
    public var name: String?
    
    public var timeToFull: Int?
    public var timeToEmpty: Int?
    
    public var manufacturer: String?
    public var manufactureDate: Date?
    
    public var currentCapacity: Int?
    public var maxCapacity: Int?
    public var designCapacity: Int?
    
    public var cycleCount: Int?
    public var designCycleCount: Int?
    
    public var acPowered: Bool?
    public var isCharging: Bool?
    public var isCharged: Bool?
    public var amperage: Int?
    public var voltage: Double?
    public var watts: Double?
    public var temperature: Double?
    
    public var charge: Double? {
        if let current = self.currentCapacity,
           let max = self.maxCapacity {
            return (Double(current) / Double(max)) * 100.0
        }
        return nil
    }
    
    public var health: Double? {
        if let design = self.designCapacity,
           let current = self.maxCapacity {
            return (Double(current) / Double(design)) * 100.0
        }

        return nil
    }
    
    public var timeLeft: String {
        if let isCharging = self.isCharging {
            if let minutes = isCharging ? self.timeToFull : self.timeToEmpty {
                if minutes <= 0 {
                    return "-"
                }
                
                return String(format: "%.2d:%.2d", minutes / 60, minutes % 60)
            }
        }
        
        return "-"
    }
    
    public var timeRemaining: Int? {
        if let isCharging = self.isCharging {
            return isCharging ? self.timeToFull : self.timeToEmpty
        }
        
        return nil
    }
}

#endif
