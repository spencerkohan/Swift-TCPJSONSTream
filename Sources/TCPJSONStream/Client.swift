//
//  Client.swift
//  TCPJSONStream
//
//  Created by Spencer Kohan on 9/19/17.
//

import Foundation
import TCP
import EventEmitter

public class Client : TCP.Connection {
    
    var parser : JSONStreamParser = JSONStreamParser()
    
    public let didReceiveJsonData = Event<Data>()
    
    public override init(host: String, port: Int) {
        super.init(host: host, port: port)
        _ = parser.events.didDetectObject.on { data in
            _ = self.didReceiveJsonData.emit(data)
        }
        _ = events.dataReceived.on { data in
            self.parser.consume(data: data)
        }
    }
    
}

extension Data {
    var swapped : Data {
        let bytes = self.map { return $0 }
        var bytesCopy = bytes
        for i in 0..<bytes.count {
            bytesCopy[i] = i % 2 == 0 ? bytes[i+1] : bytes[i-1]
        }
        return Data(bytesCopy)
    }
    func printBytes() {
        let bytes : [UInt8] = self.map { return $0 }
        print("==============")
        let str = String(data: self, encoding: .utf8)
        print("UTF8: \(str ?? "nil")")
        print("data: \(self)")
        print("--------------")
        for byte in bytes {
            print(byte)
        }
        print("==============")
    }
}

public extension TCP.Connection {
    
    func packet(from data: Data) -> Data {
        var signature : UInt16 = UInt16(206)
        var byteLength : UInt32 = UInt32(data.count)
        let startByte = Data(buffer: UnsafeBufferPointer(start: &signature, count: 1))
        let length = Data(buffer: UnsafeBufferPointer(start: &byteLength, count: 1))
        let packet = startByte + length + data
        return packet
    }
    
    public func sendJSON<T>(object:T) where T: Encodable {
        guard let jsonData = try? JSONEncoder().encode(object) else { return }
        self.send(data: packet(from:jsonData))
    }
    
    public func sendJSON(record: Any) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: record) else { return }
        self.send(data: packet(from:jsonData))
    }
    
}
