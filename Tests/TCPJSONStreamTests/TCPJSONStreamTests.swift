import XCTest
@testable import TCPJSONStream

class TCPJSONStreamTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TCPJSONStream().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
        ("testStreamParser", testStreamParser),
        ("testServerClient", testServerClient),
    ]
    
    func testParsePacketHeader() {
        
        let client = Client(host:"", port:0)
        
        let validJson = "{\"x\":1}".data(using: .utf8)!
        
        let packet = Client.packet(from:validJson)
        var parser = JSONStreamParser()
        parser.parse(header:packet[..<6])
        
        XCTAssert(parser.currentPacketLength == 7)
        
    }
    
    func testStreamParser() {
        
        var parser = JSONStreamParser()
        
        _ = parser.events.didDetectObject.on { objectData in
            let string = String(data:objectData, encoding: .utf8)
            print("did detect object:")
            print(string ?? "")
        }
        
        let validJson = """
{"x":1}{"abc":["a", "b", {"c":1}]}
""".data(using: .utf8)
        
        parser.consume(data:Client.packet(from:validJson ?? Data()))
        
        XCTAssert(parser.currentPacketLength == 34)
        
        
    }
    
    func testStreamParserMultiplePackets() {
        
        var parser = JSONStreamParser()
        
        _ = parser.events.didDetectObject.on { objectData in
            let string = String(data:objectData, encoding: .utf8)
            print("did detect object:")
            print(string ?? "")
        }
        
        let data1 = """
{"x":1}
""".data(using: .utf8)!
        let data2 = """
[{"x":1},{"y":2},[2, 3, 4]]
""".data(using: .utf8)!
        
        var packets = Client.packet(from: data1)
        packets.append(Client.packet(from: data2))
        
        parser.consume(data:packets)
        
        XCTAssert(parser.currentPacketLength == 27)
        
        
    }
    
    func testServerClient() {
        
        let expectation = self.expectation(description: "Server")
        
        let server = Server(port: 3001)
        _ = server.events.clientConnected.on { client in
            print("!client connected")
            client.sendJSON(object:["x":1])
            // client.sendJSON(object:["y":2])
            _ = client.events.dataReceived.on { data in
                print("SERVER RECEIVED:")
                guard let string = String(data:data[6...], encoding:.utf8) else {
                    print("ERR!")
                    return
                }
                print(string)
                expectation.fulfill()
            }
        }
        
        
        let client = Client(host: "localhost", port: 3001)
        _ = client.didReceiveJsonData.on { data in
            print("CLIENT RECEIVED:")
            guard let string = String(data:data, encoding:.utf8) else {
                return
            }
            print(string)
        }
        
        _ = client.events.didOpen.on {
            client.sendJSON(record:["x", 2, ["a":1]])
        }
        
        server.listen()
        client.open {}

        waitForExpectations(timeout: 100) {_ in}
        
    }
}
