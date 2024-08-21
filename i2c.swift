import HAL

// twcr flags
private let TWINT = 7
private let TWEA = 6
private let TWSTA = 5
private let TWSTO = 4
private let TWWC = 3
private let TWEN = 2
private let TWIE = 0

/*
public protocol Twi {
    associatedtype Twamr: MutableRegisterValue
    associatedtype Twcr: MutableRegisterValue
    associatedtype Twar: MutableRegisterValue
    associatedtype Twsr: MutableRegisterValue

    static var twamr: Twamr  { get set }
    static var twcr:  Twcr  { get set }
    static var twdr:  UInt8  { get set }
    static var twar:  Twar  { get set }
    static var twsr:  Twsr  { get set }
    static var twbr:  UInt8  { get set }
}
*/

public extension Twi where Twsr.RegisterType == UInt8 {
    /// This just sets the speed. You can call it without parameters for a sensible default.
    /// Use direct register control if you want things like the premultiplier.
    /// It doesn't activate the hardware as there's little point until you're about to perform
    /// a start (as master) or initiate listening (as slave).
    static func setup(speed: UInt8 = 0x47) {
        twbr = speed
    }

    /// This is the general purpose function that allows the hardware to complete transmission,
    /// clear its current condition or generally tell the software to act.
    /// The timeout you pass is in arbitrary units, and should be calibrated if you want an exact
    /// timeout, but for most purposes, using some large value like 50_000 will give a long enough
    /// timeout to detect a bus problem or a hanging peripheral and respond accordingly.
    @discardableResult
    static func waitForHardware(timeout: UInt16) -> Bool {
        var timeout = timeout

        while timeout > 0, twcr.registerValue&(1<<TWINT) == 0 {
            timeout -= 1
        }

        return timeout > 0
    }

    @discardableResult
    static func start(timeout: UInt16) -> Bool {
        twcr.registerValue = (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
        
        guard waitForHardware(timeout: timeout) else {
            return false
        }
    
        return twsr.registerValue == 0x08 || twsr.registerValue == 0x10 // TW_START or repeated start
    }

    /// note: this takes a timeout parameter but currently ignores it
    /// because a stop condition is usually the end of drive and we
    /// do not need to wait for it to complete
    @discardableResult
    static func stop(timeout: UInt16) -> Bool {
        twcr.registerValue = (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
 
        return true
    }

    @discardableResult
    static func write(byte: UInt8, timeout: UInt16) -> Bool where Twsr.RegisterType == UInt8 {
        twdr = byte
        twcr.registerValue = (1<<TWINT)|(1<<TWEN)
        
        guard waitForHardware(timeout: timeout) else {
            return false
        }
    
        // TW_MT_DATA_ACK || TW_MT_SLA_ACK || TW_MR_DATA_ACK || TW_MR_SLA_ACK
        return (twsr.registerValue == 0x28) || (twsr.registerValue == 0x18) || (twsr.registerValue == 0x40) || (twsr.registerValue == 0x50)
    }

    @discardableResult
    static func slaveWrite(byte: UInt8, sendAck: Bool, timeout: UInt16) -> Bool where Twsr.RegisterType == UInt8 {
        twdr = byte

        if sendAck {
            twcr.registerValue = (1<<TWINT)|(1<<TWEA)|(1<<TWEN)
        } else {
            twcr.registerValue = (1<<TWINT)|(1<<TWEN)
        }

        guard waitForHardware(timeout: timeout) else {
            return false
        }

        return true
    }

    @discardableResult
    static func read(sendAck: Bool, timeout: UInt16) -> UInt8? {
        if sendAck {
            twcr.registerValue = (1<<TWINT)|(1<<TWEA)|(1<<TWEN)
        } else {
            twcr.registerValue = (1<<TWINT)|(1<<TWEN)
        }

        guard waitForHardware(timeout: timeout) else {
            return nil
        }
    
        return twdr
    }

    static func readFromDevice(address: UInt8, timeout: UInt16) -> UInt8? {
        guard start(timeout: timeout) else { return nil }
        defer { stop(timeout: timeout) }
        guard write(byte: ((address&0x7f)<<1)+1, timeout: timeout) else { return nil }
        return read(sendAck: false, timeout: timeout)
    }

    @discardableResult
    static func writeToDevice(address: UInt8, byte: UInt8, timeout: UInt16) -> Bool {
        guard start(timeout: timeout) else { return false }
        guard write(byte: ((address&0x7f)<<1), timeout: timeout) else { return false }
        guard write(byte: byte, timeout: timeout) else { return false }
        stop(timeout: timeout)
        return true
    }

    @discardableResult
    static func readDeviceRegister(address: UInt8, register: UInt8, timeout: UInt16) -> UInt8? {
        guard start(timeout: timeout) else { return nil }
        defer { stop(timeout: timeout) }

        guard write(byte: ((address&0x7f)<<1), timeout: timeout) else { return nil }
        guard write(byte: register, timeout: timeout) else { return nil }

        guard start(timeout: timeout) else { return nil }
        guard write(byte: ((address&0x7f)<<1)+1, timeout: timeout) else { return nil }
        return read(sendAck: false, timeout: timeout)
    }

    @discardableResult
    static func writeDeviceRegister(address: UInt8, register: UInt8, value: UInt8, timeout: UInt16) -> Bool {
        guard start(timeout: timeout) else { return false }
        defer { stop(timeout: timeout) }
        guard write(byte: ((address&0x7f)<<1), timeout: timeout) else { return false }
        guard write(byte: register, timeout: timeout) else { return false }
        guard write(byte: value, timeout: timeout) else { return false }
        return true
    }

    static func slaveInit(address: UInt8) where Twar.RegisterType == UInt8 {
        twcr.registerValue = (1<<TWINT)|(1<<TWEA)|(1<<TWEN)
        let slaveAddress: UInt8 = address<<1
        twar.registerValue = slaveAddress
    }

    /// note: this version doesn't re-enable interrupts
    static func slaveRelease() {
        twcr.registerValue = (1<<TWINT)|(1<<TWEA)|(1<<TWEN)
    }
}