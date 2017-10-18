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
}

public extension TCP.Connection {
    
    func packet(from data: Data) -> Data {
        var signature : UInt16 = 206
        var byteLength : UInt32 = UInt32(data.count) + 6
        var packet = Data()
        let startByte = Data(buffer: UnsafeBufferPointer(start: &signature, count: 1))
        let length = Data(buffer: UnsafeBufferPointer(start: &byteLength, count: 1))        
        return startByte.swapped + length.swapped + data
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
