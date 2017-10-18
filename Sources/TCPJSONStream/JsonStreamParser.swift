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
    
    public mutating func consume(data: Data) {
        guard let dataString = String(data:data, encoding: .utf8) else {
            if data.count > 0 {
                consume(data: data[1...])
            }
            return
        }
        for char in dataString {
            consume(character: char)
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
            if stack.count == 0 && !currentObjectData.isEmpty {
                emitInvalidChunk()
            }
            if let charData = charString.data(using: .utf8) {
                currentObjectData += charData
            }
            stack += [character]
            break
        case "[":
            if stack.count == 0 && !currentObjectData.isEmpty {
                emitInvalidChunk()
            }
            if let charData = charString.data(using: .utf8) {
                currentObjectData += charData
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
            guard let json = try? JSONSerialization.jsonObject(with: currentObjectData, options: [.allowFragments]) else {
                emitInvalidChunk()
                return
            }
            emitObject()
        }
        
    }
    
    
    
    
}
