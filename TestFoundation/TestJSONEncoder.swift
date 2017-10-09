// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

struct TopLevelObjectWrapper<T: Codable & Equatable>: Codable, Equatable {
    var value: T

    static func ==(lhs: TopLevelObjectWrapper, rhs: TopLevelObjectWrapper) -> Bool {
        return lhs.value == rhs.value
    }

    init(_ value: T) {
        self.value = value
    }
}

class TestJSONEncoder : XCTestCase {

    // MARK: - Encoding Top-Level Empty Types
    func test_encodingTopLevelEmptyStruct() {
        let empty = EmptyStruct()
        _testRoundTrip(of: empty, expectedJSON: _jsonEmptyDictionary)
    }

    func test_encodingTopLevelEmptyClass() {
        let empty = EmptyClass()
        _testRoundTrip(of: empty, expectedJSON: _jsonEmptyDictionary)
    }

    // MARK: - Encoding Top-Level Single-Value Types
    func test_encodingTopLevelSingleValueEnum() {
        _testEncodeFailure(of: Switch.off)
        _testEncodeFailure(of: Switch.on)

        _testRoundTrip(of: TopLevelArrayWrapper(Switch.off))
        _testRoundTrip(of: TopLevelArrayWrapper(Switch.on))
    }

    func test_encodingTopLevelSingleValueStruct() {
        _testEncodeFailure(of: Timestamp(3141592653))
        _testRoundTrip(of: TopLevelArrayWrapper(Timestamp(3141592653)))
    }

    func test_encodingTopLevelSingleValueClass() {
        _testEncodeFailure(of: Counter())
        _testRoundTrip(of: TopLevelArrayWrapper(Counter()))
    }

    // MARK: - Encoding Top-Level Structured Types
    func test_encodingTopLevelStructuredStruct() {
        // Address is a struct type with multiple fields.
        let address = Address.testValue
        _testRoundTrip(of: address)
    }

    func test_encodingTopLevelStructuredClass() {
        // Person is a class with multiple fields.
        let expectedJSON = "{\"name\":\"Johnny Appleseed\",\"email\":\"appleseed@apple.com\"}".data(using: .utf8)!
        let person = Person.testValue
        _testRoundTrip(of: person, expectedJSON: expectedJSON)
    }

    func test_encodingTopLevelStructuredSingleStruct() {
        // Numbers is a struct which encodes as an array through a single value container.
        let numbers = Numbers.testValue
        _testRoundTrip(of: numbers)
    }

    func test_encodingTopLevelStructuredSingleClass() {
        // Mapping is a class which encodes as a dictionary through a single value container.
        let mapping = Mapping.testValue
        _testRoundTrip(of: mapping)
    }

    func test_encodingTopLevelDeepStructuredType() {
        // Company is a type with fields which are Codable themselves.
        let company = Company.testValue
        _testRoundTrip(of: company)
    }

    // MARK: - Output Formatting Tests
    func test_encodingOutputFormattingDefault() {
        let expectedJSON = "{\"name\":\"Johnny Appleseed\",\"email\":\"appleseed@apple.com\"}".data(using: .utf8)!
        let person = Person.testValue
        _testRoundTrip(of: person, expectedJSON: expectedJSON)
    }

    func test_encodingOutputFormattingPrettyPrinted() {
        let expectedJSON = "{\n  \"name\" : \"Johnny Appleseed\",\n  \"email\" : \"appleseed@apple.com\"\n}".data(using: .utf8)!
        let person = Person.testValue
        _testRoundTrip(of: person, expectedJSON: expectedJSON, outputFormatting: [.prettyPrinted])
    }

    func test_encodingOutputFormattingSortedKeys() {
        if #available(OSX 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            let expectedJSON = "{\"email\":\"appleseed@apple.com\",\"name\":\"Johnny Appleseed\"}".data(using: .utf8)!
            let person = Person.testValue
            _testRoundTrip(of: person, expectedJSON: expectedJSON, outputFormatting: [.sortedKeys])
        }
    }

    func test_encodingOutputFormattingPrettyPrintedSortedKeys() {
        if #available(OSX 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            let expectedJSON = "{\n  \"email\" : \"appleseed@apple.com\",\n  \"name\" : \"Johnny Appleseed\"\n}".data(using: .utf8)!
            let person = Person.testValue
            _testRoundTrip(of: person, expectedJSON: expectedJSON, outputFormatting: [.prettyPrinted, .sortedKeys])
        }
    }

    // MARK: - Date Strategy Tests
    func test_encodingDate() {
        // We can't encode a top-level Date, so it'll be wrapped in an array.
        _testRoundTrip(of: TopLevelArrayWrapper(Date()))
    }

    func test_encodingDateSecondsSince1970() {
        // Cannot encode an arbitrary number of seconds since we've lost precision since 1970.
        let seconds = 1000.0
        let expectedJSON = "[1000]".data(using: .utf8)!

        // We can't encode a top-level Date, so it'll be wrapped in an array.
        _testRoundTrip(of: TopLevelArrayWrapper(Date(timeIntervalSince1970: seconds)),
                       expectedJSON: expectedJSON,
                       dateEncodingStrategy: .secondsSince1970,
                       dateDecodingStrategy: .secondsSince1970)
    }

    func test_encodingDateMillisecondsSince1970() {
        // Cannot encode an arbitrary number of seconds since we've lost precision since 1970.
        let seconds = 1000.0
        let expectedJSON = "[1000000]".data(using: .utf8)!

        // We can't encode a top-level Date, so it'll be wrapped in an array.
        _testRoundTrip(of: TopLevelArrayWrapper(Date(timeIntervalSince1970: seconds)),
                       expectedJSON: expectedJSON,
                       dateEncodingStrategy: .millisecondsSince1970,
                       dateDecodingStrategy: .millisecondsSince1970)
    }

    func test_encodingDateISO8601() {
        if #available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = .withInternetDateTime

            let timestamp = Date(timeIntervalSince1970: 1000)
            let expectedJSON = "[\"\(formatter.string(from: timestamp))\"]".data(using: .utf8)!

            // We can't encode a top-level Date, so it'll be wrapped in an array.
            _testRoundTrip(of: TopLevelArrayWrapper(timestamp),
                           expectedJSON: expectedJSON,
                           dateEncodingStrategy: .iso8601,
                           dateDecodingStrategy: .iso8601)
        }
    }

    func test_encodingDateFormatted() {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full

        let timestamp = Date(timeIntervalSince1970: 1000)
        let expectedJSON = "[\"\(formatter.string(from: timestamp))\"]".data(using: .utf8)!

        // We can't encode a top-level Date, so it'll be wrapped in an array.
        _testRoundTrip(of: TopLevelArrayWrapper(timestamp),
                       expectedJSON: expectedJSON,
                       dateEncodingStrategy: .formatted(formatter),
                       dateDecodingStrategy: .formatted(formatter))
    }

    func test_encodingDateCustom() {
        let timestamp = Date()

        // We'll encode a number instead of a date.
        let encode = { (_ data: Date, _ encoder: Encoder) throws -> Void in
            var container = encoder.singleValueContainer()
            try container.encode(42)
        }
        let decode = { (_: Decoder) throws -> Date in return timestamp }

        // We can't encode a top-level Date, so it'll be wrapped in an array.
        let expectedJSON = "[42]".data(using: .utf8)!
        _testRoundTrip(of: TopLevelArrayWrapper(timestamp),
                       expectedJSON: expectedJSON,
                       dateEncodingStrategy: .custom(encode),
                       dateDecodingStrategy: .custom(decode))
    }

    func test_encodingDateCustomEmpty() {
        let timestamp = Date()

        // Encoding nothing should encode an empty keyed container ({}).
        let encode = { (_: Date, _: Encoder) throws -> Void in }
        let decode = { (_: Decoder) throws -> Date in return timestamp }

        // We can't encode a top-level Date, so it'll be wrapped in an array.
        let expectedJSON = "[{}]".data(using: .utf8)!
        _testRoundTrip(of: TopLevelArrayWrapper(timestamp),
                       expectedJSON: expectedJSON,
                       dateEncodingStrategy: .custom(encode),
                       dateDecodingStrategy: .custom(decode))
    }

    // MARK: - Data Strategy Tests
    func test_encodingBase64Data() {
        let data = Data(bytes: [0xDE, 0xAD, 0xBE, 0xEF])

        // We can't encode a top-level Data, so it'll be wrapped in an array.
        let expectedJSON = "[\"3q2+7w==\"]".data(using: .utf8)!
        _testRoundTrip(of: TopLevelArrayWrapper(data), expectedJSON: expectedJSON)
    }

    func test_encodingCustomData() {
        // We'll encode a number instead of data.
        let encode = { (_ data: Data, _ encoder: Encoder) throws -> Void in
            var container = encoder.singleValueContainer()
            try container.encode(42)
        }
        let decode = { (_: Decoder) throws -> Data in return Data() }

        // We can't encode a top-level Data, so it'll be wrapped in an array.
        let expectedJSON = "[42]".data(using: .utf8)!
        _testRoundTrip(of: TopLevelArrayWrapper(Data()),
                       expectedJSON: expectedJSON,
                       dataEncodingStrategy: .custom(encode),
                       dataDecodingStrategy: .custom(decode))
    }

    func test_encodingCustomDataEmpty() {
        // Encoding nothing should encode an empty keyed container ({}).
        let encode = { (_: Data, _: Encoder) throws -> Void in }
        let decode = { (_: Decoder) throws -> Data in return Data() }

        // We can't encode a top-level Data, so it'll be wrapped in an array.
        let expectedJSON = "[{}]".data(using: .utf8)!
        _testRoundTrip(of: TopLevelArrayWrapper(Data()),
                       expectedJSON: expectedJSON,
                       dataEncodingStrategy: .custom(encode),
                       dataDecodingStrategy: .custom(decode))
    }

    // MARK: - Non-Conforming Floating Point Strategy Tests
    func test_encodingNonConformingFloats() {
        _testEncodeFailure(of: TopLevelArrayWrapper(Float.infinity))
        _testEncodeFailure(of: TopLevelArrayWrapper(-Float.infinity))
        _testEncodeFailure(of: TopLevelArrayWrapper(Float.nan))

        _testEncodeFailure(of: TopLevelArrayWrapper(Double.infinity))
        _testEncodeFailure(of: TopLevelArrayWrapper(-Double.infinity))
        _testEncodeFailure(of: TopLevelArrayWrapper(Double.nan))
    }

    func test_encodingNonConformingFloatStrings() {
        let encodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "INF", negativeInfinity: "-INF", nan: "NaN")
        let decodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "INF", negativeInfinity: "-INF", nan: "NaN")


        _testRoundTrip(of: TopLevelArrayWrapper(Float.infinity),
                       expectedJSON: "[\"INF\"]".data(using: .utf8)!,
                       nonConformingFloatEncodingStrategy: encodingStrategy,
                       nonConformingFloatDecodingStrategy: decodingStrategy)
        _testRoundTrip(of: TopLevelArrayWrapper(-Float.infinity),
                       expectedJSON: "[\"-INF\"]".data(using: .utf8)!,
                       nonConformingFloatEncodingStrategy: encodingStrategy,
                       nonConformingFloatDecodingStrategy: decodingStrategy)

        // Since Float.nan != Float.nan, we have to use a placeholder that'll encode NaN but actually round-trip.
        _testRoundTrip(of: TopLevelArrayWrapper(FloatNaNPlaceholder()),
                       expectedJSON: "[\"NaN\"]".data(using: .utf8)!,
                       nonConformingFloatEncodingStrategy: encodingStrategy,
                       nonConformingFloatDecodingStrategy: decodingStrategy)

        _testRoundTrip(of: TopLevelArrayWrapper(Double.infinity),
                       expectedJSON: "[\"INF\"]".data(using: .utf8)!,
                       nonConformingFloatEncodingStrategy: encodingStrategy,
                       nonConformingFloatDecodingStrategy: decodingStrategy)
        _testRoundTrip(of: TopLevelArrayWrapper(-Double.infinity),
                       expectedJSON: "[\"-INF\"]".data(using: .utf8)!,
                       nonConformingFloatEncodingStrategy: encodingStrategy,
                       nonConformingFloatDecodingStrategy: decodingStrategy)

        // Since Double.nan != Double.nan, we have to use a placeholder that'll encode NaN but actually round-trip.
        _testRoundTrip(of: TopLevelArrayWrapper(DoubleNaNPlaceholder()),
                       expectedJSON: "[\"NaN\"]".data(using: .utf8)!,
                       nonConformingFloatEncodingStrategy: encodingStrategy,
                       nonConformingFloatDecodingStrategy: decodingStrategy)
    }

    // MARK: - Encoder Features
    func test_nestedContainerCodingPaths() {
        let encoder = JSONEncoder()
        do {
            let _ = try encoder.encode(NestedContainersTestType())
        } catch let error {
            XCTFail("Caught error during encoding nested container types: \(error)")
        }
    }

    func test_superEncoderCodingPaths() {
        let encoder = JSONEncoder()
        do {
            let _ = try encoder.encode(NestedContainersTestType(testSuperEncoder: true))
        } catch let error {
            XCTFail("Caught error during encoding nested container types: \(error)")
        }
    }

    // MARK: - Test encoding and decoding of built-in Codable types
    func test_codingOfBool() {
        test_codingOf(value: Bool(true), toAndFrom: "true")
        test_codingOf(value: Bool(false), toAndFrom: "false")

        do {
            _ = try JSONDecoder().decode([Bool].self, from: "[1]".data(using: .utf8)!)
            XCTFail("Coercing non-boolean numbers into Bools was expected to fail")
        } catch { }
    }

    func test_codingOfInt8() {
        test_codingOf(value: Int8(-42), toAndFrom: "-42")
    }

    func test_codingOfUInt8() {
        test_codingOf(value: UInt8(42), toAndFrom: "42")
    }

    func test_codingOfInt16() {
        test_codingOf(value: Int16(-30042), toAndFrom: "-30042")
    }

    func test_codingOfUInt16() {
        test_codingOf(value: UInt16(30042), toAndFrom: "30042")
    }

    func test_codingOfInt32() {
        test_codingOf(value: Int32(-2000000042), toAndFrom: "-2000000042")
    }

    func test_codingOfUInt32() {
        test_codingOf(value: UInt32(2000000042), toAndFrom: "2000000042")
    }

    func test_codingOfInt64() {
        test_codingOf(value: Int64(-9000000000000000042), toAndFrom: "-9000000000000000042")
    }

    func test_codingOfUInt64() {
        test_codingOf(value: UInt64(9000000000000000042), toAndFrom: "9000000000000000042")
    }

    func test_codingOfInt() {
        let intSize = MemoryLayout<Int>.size
        switch intSize {
        case 4: // 32-bit
            test_codingOf(value: Int(-2000000042), toAndFrom: "-2000000042")
        case 8: // 64-bit
            test_codingOf(value: Int(-9000000000000000042), toAndFrom: "-9000000000000000042")
        default:
            XCTFail("Unexpected UInt size: \(intSize)")
        }
    }

    func test_codingOfUInt() {
        let uintSize = MemoryLayout<UInt>.size
        switch uintSize {
        case 4: // 32-bit
            test_codingOf(value: UInt(2000000042), toAndFrom: "2000000042")
        case 8: // 64-bit
            test_codingOf(value: UInt(9000000000000000042), toAndFrom: "9000000000000000042")
        default:
            XCTFail("Unexpected UInt size: \(uintSize)")
        }
    }

    func test_codingOfFloat() {
        test_codingOf(value: Double(1.5), toAndFrom: "1.5")
    }

    func test_codingOfDouble() {
        test_codingOf(value: Float(1.5), toAndFrom: "1.5")
    }

    func test_codingOfString() {
        test_codingOf(value: "Hello, world!", toAndFrom: "\"Hello, world!\"")
    }

    func test_codingOfURL() {
        test_codingOf(value: URL(string: "https://swift.org")!, toAndFrom: "\"https://swift.org\"")
    }


    // UInt and Int
    func test_codingOfUIntMinMax() {

        struct MyValue: Codable {
            let int64Min = Int64.min
            let int64Max = Int64.max
            let uint64Min = UInt64.min
            let uint64Max = UInt64.max
        }

        func compareJSON(_ s1: String, _ s2: String) {
            let ss1 = s1.trimmingCharacters(in: CharacterSet(charactersIn: "{}")).split(separator: Character(",")).sorted()
            let ss2 = s2.trimmingCharacters(in: CharacterSet(charactersIn: "{}")).split(separator: Character(",")).sorted()
            XCTAssertEqual(ss1, ss2)
        }

        do {
            let encoder = JSONEncoder()
            let myValue = MyValue()
            let result = try encoder.encode(myValue)
            let r = String(data: result, encoding: .utf8) ?? "nil"
            compareJSON(r, "{\"uint64Min\":0,\"uint64Max\":18446744073709551615,\"int64Min\":-9223372036854775808,\"int64Max\":9223372036854775807}")
        } catch {
            XCTFail(String(describing: error))
        }
    }

    // MARK: - Helper Functions
    private var _jsonEmptyDictionary: Data {
        return "{}".data(using: .utf8)!
    }

    private func _testEncodeFailure<T : Encodable>(of value: T) {
        do {
            let _ = try JSONEncoder().encode(value)
            XCTFail("Encode of top-level \(T.self) was expected to fail.")
        } catch {}
    }

    private func _testRoundTrip<T>(of value: T,
                                   expectedJSON json: Data? = nil,
                                   outputFormatting: JSONEncoder.OutputFormatting = [],
                                   dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
                                   dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                   dataEncodingStrategy: JSONEncoder.DataEncodingStrategy = .base64Encode,
                                   dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64Decode,
                                   nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .throw,
                                   nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw) where T : Codable, T : Equatable {
        var payload: Data! = nil
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = outputFormatting
            encoder.dateEncodingStrategy = dateEncodingStrategy
            encoder.dataEncodingStrategy = dataEncodingStrategy
            encoder.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
            payload = try encoder.encode(value)
        } catch {
            XCTFail("Failed to encode \(T.self) to JSON: \(error)")
        }
        
        if let expectedJSON = json {
            // We do not compare expectedJSON to payload directly, because they might have values like
            // {"name": "Bob", "age": 22}
            // and
            // {"age": 22, "name": "Bob"}
            // which if compared as Data would not be equal, but the contained JSON values are equal.
            // So we wrap them in a JSON type, which compares data as if it were a json.

            let expectedJSONObject: JSON
            let payloadJSONObject: JSON

            do {
                expectedJSONObject = try JSON(data: expectedJSON)
            } catch {
                XCTFail("Invalid JSON data passed as expectedJSON: \(error)")
                return
            }

            do {
                payloadJSONObject = try JSON(data: payload)
            } catch {
                XCTFail("Produced data is not a valid JSON: \(error)")
                return
            }

            XCTAssertEqual(expectedJSONObject, payloadJSONObject, "Produced JSON not identical to expected JSON.")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = dateDecodingStrategy
            decoder.dataDecodingStrategy = dataDecodingStrategy
            decoder.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
            let decoded = try decoder.decode(T.self, from: payload)
            XCTAssertEqual(decoded, value, "\(T.self) did not round-trip to an equal value.")
        } catch {
            XCTFail("Failed to decode \(T.self) from JSON: \(error)")
        }
    }

    func test_codingOf<T: Codable & Equatable>(value: T, toAndFrom stringValue: String) {
        _testRoundTrip(of: TopLevelObjectWrapper(value),
                       expectedJSON: "{\"value\":\(stringValue)}".data(using: .utf8)!)

        _testRoundTrip(of: TopLevelArrayWrapper(value),
                       expectedJSON: "[\(stringValue)]".data(using: .utf8)!)
    }
}

// MARK: - Helper Global Functions
func expectEqualPaths(_ lhs: [CodingKey?], _ rhs: [CodingKey?], _ prefix: String) {
    if lhs.count != rhs.count {
        XCTFail("\(prefix) [CodingKey?].count mismatch: \(lhs.count) != \(rhs.count)")
        return
    }

    for (k1, k2) in zip(lhs, rhs) {
        switch (k1, k2) {
        case (.none, .none): continue
        case (.some(let _k1), .none):
            XCTFail("\(prefix) CodingKey mismatch: \(type(of: _k1)) != nil")
            return
        case (.none, .some(let _k2)):
            XCTFail("\(prefix) CodingKey mismatch: nil != \(type(of: _k2))")
            return
        default: break
        }

        let key1 = k1!
        let key2 = k2!

        switch (key1.intValue, key2.intValue) {
        case (.none, .none): break
        case (.some(let i1), .none):
            XCTFail("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != nil")
            return
        case (.none, .some(let i2)):
            XCTFail("\(prefix) CodingKey.intValue mismatch: nil != \(type(of: key2))(\(i2))")
            return
        case (.some(let i1), .some(let i2)):
            guard i1 == i2 else {
                XCTFail("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != \(type(of: key2))(\(i2))")
                return
            }

            break
        }

        XCTAssertEqual(key1.stringValue,
                       key2.stringValue,
                       "\(prefix) CodingKey.stringValue mismatch: \(type(of: key1))('\(key1.stringValue)') != \(type(of: key2))('\(key2.stringValue)')")
    }
}

// MARK: - Test Types
/* FIXME: Import from %S/Inputs/Coding/SharedTypes.swift somehow. */

// MARK: - Empty Types
fileprivate struct EmptyStruct : Codable, Equatable {
    static func ==(_ lhs: EmptyStruct, _ rhs: EmptyStruct) -> Bool {
        return true
    }
}

fileprivate class EmptyClass : Codable, Equatable {
    static func ==(_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
        return true
    }
}

// MARK: - Single-Value Types
/// A simple on-off switch type that encodes as a single Bool value.
fileprivate enum Switch : Codable {
    case off
    case on

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(Bool.self) {
        case false: self = .off
        case true:  self = .on
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .off: try container.encode(false)
        case .on:  try container.encode(true)
        }
    }
}

/// A simple timestamp type that encodes as a single Double value.
fileprivate struct Timestamp : Codable, Equatable {
    let value: Double

    init(_ value: Double) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }

    static func ==(_ lhs: Timestamp, _ rhs: Timestamp) -> Bool {
        return lhs.value == rhs.value
    }
}

/// A simple referential counter type that encodes as a single Int value.
fileprivate final class Counter : Codable, Equatable {
    var count: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        count = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.count)
    }

    static func ==(_ lhs: Counter, _ rhs: Counter) -> Bool {
        return lhs === rhs || lhs.count == rhs.count
    }
}

// MARK: - Structured Types
/// A simple address type that encodes as a dictionary of values.
fileprivate struct Address : Codable, Equatable {
    let street: String
    let city: String
    let state: String
    let zipCode: Int
    let country: String

    init(street: String, city: String, state: String, zipCode: Int, country: String) {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }

    static func ==(_ lhs: Address, _ rhs: Address) -> Bool {
        return lhs.street == rhs.street &&
            lhs.city == rhs.city &&
            lhs.state == rhs.state &&
            lhs.zipCode == rhs.zipCode &&
            lhs.country == rhs.country
    }

    static var testValue: Address {
        return Address(street: "1 Infinite Loop",
                       city: "Cupertino",
                       state: "CA",
                       zipCode: 95014,
                       country: "United States")
    }
}

/// A simple person class that encodes as a dictionary of values.
fileprivate class Person : Codable, Equatable {
    let name: String
    let email: String

    // FIXME: This property is present only in order to test the expected result of Codable synthesis in the compiler.
    // We want to test against expected encoded output (to ensure this generates an encodeIfPresent call), but we need an output format for that.
    // Once we have a VerifyingEncoder for compiler unit tests, we should move this test there.
    let website: URL?

    init(name: String, email: String, website: URL? = nil) {
        self.name = name
        self.email = email
        self.website = website
    }

    static func ==(_ lhs: Person, _ rhs: Person) -> Bool {
        return lhs.name == rhs.name &&
            lhs.email == rhs.email &&
            lhs.website == rhs.website
    }

    static var testValue: Person {
        return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
    }
}

/// A simple company struct which encodes as a dictionary of nested values.
fileprivate struct Company : Codable, Equatable {
    let address: Address
    var employees: [Person]

    init(address: Address, employees: [Person]) {
        self.address = address
        self.employees = employees
    }

    static func ==(_ lhs: Company, _ rhs: Company) -> Bool {
        return lhs.address == rhs.address && lhs.employees == rhs.employees
    }

    static var testValue: Company {
        return Company(address: Address.testValue, employees: [Person.testValue])
    }
}

// MARK: - Helper Types

/// A key type which can take on any string or integer value.
/// This needs to mirror _JSONKey.
fileprivate struct _TestKey : CodingKey {
  var stringValue: String
  var intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  init?(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }

  init(index: Int) {
    self.stringValue = "Index \(index)"
    self.intValue = index
  }
}

/// Wraps a type T so that it can be encoded at the top level of a payload.
fileprivate struct TopLevelArrayWrapper<T> : Codable, Equatable where T : Codable, T : Equatable {
    let value: T

    init(_ value: T) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(value)
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        value = try container.decode(T.self)
        assert(container.isAtEnd)
    }

    static func ==(_ lhs: TopLevelArrayWrapper<T>, _ rhs: TopLevelArrayWrapper<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

fileprivate struct FloatNaNPlaceholder : Codable, Equatable {
    init() {}

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Float.nan)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let float = try container.decode(Float.self)
        if !float.isNaN {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Couldn't decode NaN."))
        }
    }

    static func ==(_ lhs: FloatNaNPlaceholder, _ rhs: FloatNaNPlaceholder) -> Bool {
        return true
    }
}

fileprivate struct DoubleNaNPlaceholder : Codable, Equatable {
    init() {}

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Double.nan)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let double = try container.decode(Double.self)
        if !double.isNaN {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Couldn't decode NaN."))
        }
    }

    static func ==(_ lhs: DoubleNaNPlaceholder, _ rhs: DoubleNaNPlaceholder) -> Bool {
        return true
    }
}

/// A type which encodes as an array directly through a single value container.
struct Numbers : Codable, Equatable {
    let values = [4, 8, 15, 16, 23, 42]

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValues = try container.decode([Int].self)
        guard decodedValues == values else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The Numbers are wrong!"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    static func ==(_ lhs: Numbers, _ rhs: Numbers) -> Bool {
        return lhs.values == rhs.values
    }

    static var testValue: Numbers {
        return Numbers()
    }
}

/// A type which encodes as a dictionary directly through a single value container.
fileprivate final class Mapping : Codable, Equatable {
    let values: [String : URL]

    init(values: [String : URL]) {
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String : URL].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    static func ==(_ lhs: Mapping, _ rhs: Mapping) -> Bool {
        return lhs === rhs || lhs.values == rhs.values
    }

    static var testValue: Mapping {
        return Mapping(values: ["Apple": URL(string: "http://apple.com")!,
                                "localhost": URL(string: "http://127.0.0.1")!])
    }
}

struct NestedContainersTestType : Encodable {
    let testSuperEncoder: Bool

    init(testSuperEncoder: Bool = false) {
        self.testSuperEncoder = testSuperEncoder
    }

    enum TopLevelCodingKeys : Int, CodingKey {
        case a
        case b
        case c
    }

    enum IntermediateCodingKeys : Int, CodingKey {
        case one
        case two
    }

    func encode(to encoder: Encoder) throws {
        if self.testSuperEncoder {
            var topLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
            expectEqualPaths(encoder.codingPath, [], "Top-level Encoder's codingPath changed.")
            expectEqualPaths(topLevelContainer.codingPath, [], "New first-level keyed container has non-empty codingPath.")

            let superEncoder = topLevelContainer.superEncoder(forKey: .a)
            expectEqualPaths(encoder.codingPath, [], "Top-level Encoder's codingPath changed.")
            expectEqualPaths(topLevelContainer.codingPath, [], "First-level keyed container's codingPath changed.")
            expectEqualPaths(superEncoder.codingPath, [TopLevelCodingKeys.a], "New superEncoder had unexpected codingPath.")
            _testNestedContainers(in: superEncoder, baseCodingPath: [TopLevelCodingKeys.a])
        } else {
            _testNestedContainers(in: encoder, baseCodingPath: [])
        }
    }

    func _testNestedContainers(in encoder: Encoder, baseCodingPath: [CodingKey?]) {
        expectEqualPaths(encoder.codingPath, baseCodingPath, "New encoder has non-empty codingPath.")

        // codingPath should not change upon fetching a non-nested container.
        var firstLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
        expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
        expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "New first-level keyed container has non-empty codingPath.")

        // Nested Keyed Container
        do {
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .a)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "New second-level keyed container had unexpected codingPath.")

            // Inserting a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self, forKey: .one)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.one], "New third-level keyed container had unexpected codingPath.")

            // Inserting an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer(forKey: .two)
            expectEqualPaths(encoder.codingPath, baseCodingPath + [], "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath + [], "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.a], "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.two], "New third-level unkeyed container had unexpected codingPath.")
        }

        // Nested Unkeyed Container
        do {
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedUnkeyedContainer(forKey: .b)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "New second-level keyed container had unexpected codingPath.")

            // Appending a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(keyedBy: IntermediateCodingKeys.self)
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 0)], "New third-level keyed container had unexpected codingPath.")
            
            // Appending an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer()
            expectEqualPaths(encoder.codingPath, baseCodingPath, "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath, "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath, baseCodingPath + [TopLevelCodingKeys.b], "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath, baseCodingPath + [TopLevelCodingKeys.b, _TestKey(index: 1)], "New third-level unkeyed container had unexpected codingPath.")
        }
    }
}

// MARK: - Helpers

fileprivate struct JSON: Equatable {
    private var jsonObject: Any

    fileprivate init(data: Data) throws {
        self.jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
    }

    static func ==(lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs.jsonObject, rhs.jsonObject) {
        case let (lhs, rhs) as ([AnyHashable: Any], [AnyHashable: Any]):
            return NSDictionary(dictionary: lhs) == NSDictionary(dictionary: rhs)
        case let (lhs, rhs) as ([Any], [Any]):
            return NSArray(array: lhs) == NSArray(array: rhs)
        default:
            return false
        }
    }
}

// MARK: - Run Tests

extension TestJSONEncoder {
    static var allTests: [(String, (TestJSONEncoder) -> () throws -> Void)] {
        return [
            ("test_encodingTopLevelEmptyStruct", test_encodingTopLevelEmptyStruct),
            ("test_encodingTopLevelEmptyClass", test_encodingTopLevelEmptyClass),
            ("test_encodingTopLevelSingleValueEnum", test_encodingTopLevelSingleValueEnum),
            ("test_encodingTopLevelSingleValueStruct", test_encodingTopLevelSingleValueStruct),
            ("test_encodingTopLevelSingleValueClass", test_encodingTopLevelSingleValueClass),
            ("test_encodingTopLevelStructuredStruct", test_encodingTopLevelStructuredStruct),
            ("test_encodingTopLevelStructuredClass", test_encodingTopLevelStructuredClass),
            ("test_encodingTopLevelDeepStructuredType", test_encodingTopLevelDeepStructuredType),
            ("test_encodingDate", test_encodingDate),
            ("test_encodingDateSecondsSince1970", test_encodingDateSecondsSince1970),
            ("test_encodingDateMillisecondsSince1970", test_encodingDateMillisecondsSince1970),
            ("test_encodingDateISO8601", test_encodingDateISO8601),
            ("test_encodingDateFormatted", test_encodingDateFormatted),
            ("test_encodingDateCustom", test_encodingDateCustom),
            ("test_encodingDateCustomEmpty", test_encodingDateCustomEmpty),
            ("test_encodingBase64Data", test_encodingBase64Data),
            ("test_encodingCustomData", test_encodingCustomData),
            ("test_encodingCustomDataEmpty", test_encodingCustomDataEmpty),
            ("test_encodingNonConformingFloats", test_encodingNonConformingFloats),
            ("test_encodingNonConformingFloatStrings", test_encodingNonConformingFloatStrings),
            ("test_nestedContainerCodingPaths", test_nestedContainerCodingPaths),
            ("test_superEncoderCodingPaths", test_superEncoderCodingPaths),
            ("test_codingOfBool", test_codingOfBool),
            ("test_codingOfInt8", test_codingOfInt8),
            ("test_codingOfUInt8", test_codingOfUInt8),
            ("test_codingOfInt16", test_codingOfInt16),
            ("test_codingOfUInt16", test_codingOfUInt16),
            ("test_codingOfInt32", test_codingOfInt32),
            ("test_codingOfUInt32", test_codingOfUInt32),
            ("test_codingOfInt64", test_codingOfInt64),
            ("test_codingOfUInt64", test_codingOfUInt64),
            ("test_codingOfInt", test_codingOfInt),
            ("test_codingOfUInt", test_codingOfUInt),
            ("test_codingOfUIntMinMax", test_codingOfUIntMinMax),
            ("test_codingOfFloat", test_codingOfFloat),
            ("test_codingOfDouble", test_codingOfDouble),
            ("test_codingOfString", test_codingOfString),
            ("test_codingOfURL", test_codingOfURL),
        ]
    }
}
