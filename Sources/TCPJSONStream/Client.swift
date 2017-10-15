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

public extension TCP.Connection {
    
    public func sendJSON<T>(object:T) where T: Encodable {
        guard let jsonData = try? JSONEncoder().encode(object) else { return }
        self.send(data: jsonData)
    }
    
    public func sendJSON(record: Any) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: record) else { return }
        self.send(data: jsonData)
    }
    
}
