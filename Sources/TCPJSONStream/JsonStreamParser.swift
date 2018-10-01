//
//  JsonStreamParser.swift
//  TCPJSONStreamPackageDescription
//
//  Created by Spencer Kohan on 9/19/17.
//

import Foundation
import EventEmitter

public struct JSONStreamParser {
    
    public struct Events {
        public let didDetectObject = Event<Data>()
        public let didDetectInvalidChunk = Event<Data>()
    }
    
    public let events = Events()
    var currentObjectData = Data()
    var escaping = false
    var stack = [Character]()
    
    enum State {
        case parsingHeader
        case parsingObject
    }
    var state : State = .parsingHeader
    
    var dataStream : Data = Data()
    
    mutating func parse(header:Data) {
        let length : UInt32  = Data(header[2...]).withUnsafeBytes { (ptr: UnsafePointer<UInt32>) -> UInt32 in
            return ptr.pointee
        }
        currentPacketLength = Int(length)
    }
    
    var currentPacketLength : Int = 0
    
    public mutating func consume(data: Data) {
        
        dataStream.append(data)
        
        if state == .parsingHeader {
            if dataStream.count < 6 {
                return
            }
            let header = Data(dataStream[..<6])
            dataStream = Data(dataStream[6...])
            parse(header: header)
            state = .parsingObject
        }
        
        if dataStream.count >= currentPacketLength {
            let packetData = Data(dataStream[..<currentPacketLength])
            dataStream = Data(dataStream[currentPacketLength...])
            guard let dataString = String(data:packetData, encoding: .utf8) else {
                return
            }
            stack = []
            currentObjectData = Data()
            for char in dataString {
                consume(character: char)
            }
            state = .parsingHeader
            if dataStream.count > 0 {
                let stream = dataStream
                dataStream = Data()
                consume(data:stream)
            }
        }
        

        
    }
    
    
    
    mutating func reset() {
        self.currentObjectData = Data()
        self.stack = []
    }
    
    mutating func emitObject() {
        self.events.didDetectObject.emit(currentObjectData)
        reset()
    }
    
    mutating func emitInvalidChunk() {
        self.events.didDetectInvalidChunk.emit(currentObjectData)
        reset()
    }
    
    mutating func consume(character: Character) {
        
        let charString = String(character)
        if let charData = charString.data(using: .utf8) {
            currentObjectData += charData
        }
        
        if escaping {
            self.escaping = false
            return
        }
        switch character {
        case "\\":
            self.escaping = true
            return
        case "{":
            if stack.count == 0 && currentObjectData.count > 1 {
                emitInvalidChunk()
            }
            stack += [character]
            break
        case "[":
            if stack.count == 0 && currentObjectData.count > 1 {
                emitInvalidChunk()
            }
            stack += [character]
            break
        case "}":
            if stack.last == "{" {
                stack = [Character](stack[..<(stack.count-1)])
            } else {
                emitInvalidChunk()
                return
            }
            break
        case "]":
            if stack.last == "[" {
                stack = [Character](stack[..<(stack.count-1)])
            } else {
                emitInvalidChunk()
                return
            }
            break
        default:
            break
        }
        
        
        if stack.count == 0 && !currentObjectData.isEmpty {
            guard let _ = String(data:currentObjectData, encoding: .utf8) else {
                return
            }
            guard let _ = try? JSONSerialization.jsonObject(with: currentObjectData, options: [.allowFragments]) else {
                emitInvalidChunk()
                return
            }
            emitObject()
        }
        
    }
    
    
    
    
}
