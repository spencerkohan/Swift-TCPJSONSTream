//
//  Server.swift
//  TCPJSONStreamPackageDescription
//
//  Created by Spencer Kohan on 9/19/17.
//

import Foundation

import TCP
import EventEmitter

public class Server {
    
    let tcpServer : TCP.Server
    
    struct Events {
        let didReceiveJsonData = Event<(Connection, Data)>()
        let clientConnected = Event<Connection>()
    }
    
    let events = Events()
    
    init(server: TCP.Server) {
        self.tcpServer = server
        setupEvents()
    }
    
    init(port:Int) {
        self.tcpServer = TCP.Server(port: port)
        setupEvents()
    }
    
    func listen() {
        tcpServer.listen()
    }
    
    func setupEvents() {
        _ = tcpServer.events.clientConnected.on { client in
            var parser = JSONStreamParser()
            _ = parser.events.didDetectObject.on { data in
                self.events.didReceiveJsonData.emit((client, data))
            }
            _ = client.events.dataReceived.on { data in
                parser.consume(data: data)
            }
            self.events.clientConnected.emit(client)
        }
    }
    
    
}
