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
        
        parser.consume(data:validJson ?? Data())
        
        
        
    }
    
    func testServerClient() {
        
        let expectation = self.expectation(description: "Server")
        
        let server = Server(port: 3001)
        _ = server.events.clientConnected.on { client in
            print("!client connected")
            client.sendJSON(object:["x":1])
            client.sendJSON(object:["y":2])
            _ = client.events.dataReceived.on { data in
                print("SERVER RECEIVED:")
                guard let string = String(data:data, encoding:.utf8) else {
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
