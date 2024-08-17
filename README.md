# i2c

This is a starter library for I2C use that aims to replace the I2C functions of the AVR library.

## Basic I2C function

The timeout you pass is in arbitrary units, and should be calibrated if you want an exact timeout, but for most purposes, using some large value like 50_000 will give a long enough timeout to detect a bus problem or a hanging peripheral and respond accordingly.

### General functions

`static func setup()`


### Low level I2C functions

`static func start(timeout: UInt16) -> Bool`

`static func stop(timeout: UInt16) -> Bool`

`static func write(byte: UInt8, timeout: UInt16) -> Bool `

`static func read(sendAck: Bool, timeout: UInt16) -> UInt8? `

### Slave I2C functions

`static func slaveInit(address: UInt8)`

`static func slaveReadRegister(address: UInt8, register: UInt8, timeout: UInt16) -> UInt8?`

`static func slaveWriteRegister(address: UInt8, register: UInt8, value: UInt8, timeout: UInt16) -> Bool`

### Low level Slave I2C functions

`static func slaveRelease()`

`static func slaveRead(address: UInt8, timeout: UInt16) -> UInt8?`

`static func slaveWrite(address: UInt8, byte: UInt8, timeout: UInt16) -> Bool`

