//
//  ZIPFoundationArchiveTests+ZIP64.swift
//  ZIPFoundation
//
//  Copyright © 2017-2026 Thomas Zoechling, https://www.peakstep.com and the ZIP Foundation project authors.
//  Released under the MIT License.
//
//  See https://github.com/weichsel/ZIPFoundation/blob/master/LICENSE for license information.
//

import XCTest
@testable import ZIPFoundation

extension ZIPFoundationTests {

    func testArchiveZIP64EOCDRecord() {
        let eocdRecordBytes: [UInt8] = [0x50, 0x4b, 0x06, 0x06, 0x2c, 0x00, 0x00, 0x00,
                                        0x00, 0x00, 0x00, 0x00, 0x2d, 0x00, 0x03, 0x15,
                                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x4c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                        0x5a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let zip64EOCDRecord = Archive.ZIP64EndOfCentralDirectoryRecord(data: Data(eocdRecordBytes),
                                                                       additionalDataProvider: {_ -> Data in
                                                                        return Data() })
        XCTAssertNotNil(zip64EOCDRecord)
    }

    func testArchiveWithOutlookZIP64EOCDVersionEnumeratesEntries() throws {
        let path = "Local/com.microsoft.__Messages/Inbox/message_00000.xml"
        let payload = Data("<message/>".utf8)
        let archiveURL = try makeOutlookZIP64Archive([(path, payload)])
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        let archive = try Archive(url: archiveURL, accessMode: .read)
        XCTAssertEqual(archive.map(\.path), [path])
        let entry = try XCTUnwrap(archive[path])

        var extracted = Data()
        _ = try archive.extract(entry) { extracted.append($0) }
        XCTAssertEqual(extracted, payload)
    }

    func testArchiveInvalidZIP64EOCERecordConditions() {
        let emptyEOCDRecord = Archive.ZIP64EndOfCentralDirectoryRecord(data: Data(),
                                                                       additionalDataProvider: {_ -> Data in
                                                                        return Data() })
        XCTAssertNil(emptyEOCDRecord)
        let eocdRecordIncludingExtraByte: [UInt8] = [0x50, 0x4b, 0x06, 0x06, 0x2c, 0x00, 0x00, 0x00,
                                                     0x00, 0x00, 0x00, 0x00, 0x2d, 0x00, 0x03, 0x15,
                                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                     0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                     0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                     0x4c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                     0x5a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                     0x00, 0x00]
        let invalidEOCDRecord = Archive.ZIP64EndOfCentralDirectoryRecord(data: Data(eocdRecordIncludingExtraByte),
                                                                         additionalDataProvider: {_ -> Data in
                                                                            return Data() })
        XCTAssertNil(invalidEOCDRecord)
        let eocdRecordMissingByte: [UInt8] = [0x50, 0x4b, 0x06, 0x06, 0x2c, 0x00, 0x00, 0x00,
                                              0x00, 0x00, 0x00, 0x00, 0x2d, 0x00, 0x03, 0x15,
                                              0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                              0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let invalidEOCDRecord2 = Archive.ZIP64EndOfCentralDirectoryRecord(data: Data(eocdRecordMissingByte),
                                                                          additionalDataProvider: {_ -> Data in
                                                                             return Data() })
        XCTAssertNil(invalidEOCDRecord2)
    }

    func testArchiveZIP64EOCDRecordAllowsLowVersionNeeded() {
        let eocdRecordWithWrongVersion: [UInt8] = [0x50, 0x4b, 0x06, 0x06, 0x2c, 0x00, 0x00, 0x00,
                                                   0x00, 0x00, 0x00, 0x00, 0x1e, 0x03, 0x14, 0x00,
                                                   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                   0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                   0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                   0x4c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                   0x5a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let invalidEOCDRecord3 = Archive.ZIP64EndOfCentralDirectoryRecord(data: Data(eocdRecordWithWrongVersion),
                                                                          additionalDataProvider: {_ -> Data in
                                                                             return Data() })
        XCTAssertNotNil(invalidEOCDRecord3)
    }

    func testArchiveZIP64EOCDLocator() {
        let eocdLocatorBytes: [UInt8] = [0x50, 0x4b, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00,
                                         0x9a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                         0x01, 0x00, 0x00, 0x00]
        let zip64EOCDRecord = Archive.ZIP64EndOfCentralDirectoryLocator(data: Data(eocdLocatorBytes),
                                                                        additionalDataProvider: {_ -> Data in
                                                                            return Data() })
        XCTAssertNotNil(zip64EOCDRecord)
    }

    func testArchiveInvalidZIP64EOCDLocatorConditions() {
        let emptyEOCDLocator = Archive.ZIP64EndOfCentralDirectoryLocator(data: Data(),
                                                                         additionalDataProvider: {_ -> Data in
                                                                            return Data() })
        XCTAssertNil(emptyEOCDLocator)
        let eocdLocatorIncludingExtraByte: [UInt8] = [0x50, 0x4b, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00,
                                                      0x9a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                      0x01, 0x00, 0x00, 0x00, 0x00]
        let invalidEOCDLocator = Archive.ZIP64EndOfCentralDirectoryLocator(data: Data(eocdLocatorIncludingExtraByte),
                                                                           additionalDataProvider: {_ -> Data in
                                                                            return Data() })
        XCTAssertNil(invalidEOCDLocator)
        let eocdLocatorMissingByte: [UInt8] = [0x50, 0x4b, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00,
                                               0x9a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let invalidEOCDLocator2 = Archive.ZIP64EndOfCentralDirectoryLocator(data: Data(eocdLocatorMissingByte),
                                                                           additionalDataProvider: {_ -> Data in
                                                                            return Data() })
        XCTAssertNil(invalidEOCDLocator2)
    }

    private func makeOutlookZIP64Archive(_ entries: [(path: String, data: Data)]) throws -> URL {
        var url = ZIPFoundationTests.tempZipDirectoryURL
        url.appendPathComponent(ProcessInfo.processInfo.globallyUniqueString)
        url.appendPathExtension("zip")

        var archive = Data()
        var centralDirectory = Data()

        for entry in entries {
            let localHeaderOffset = UInt64(archive.count)
            let name = Data(entry.path.utf8)

            var localExtra = Data()
            localExtra.appendUInt16LE(0x0001)
            localExtra.appendUInt16LE(16)
            localExtra.appendUInt64LE(UInt64(entry.data.count))
            localExtra.appendUInt64LE(UInt64(entry.data.count))

            archive.appendUInt32LE(0x0403_4b50)
            archive.appendUInt16LE(45)
            archive.appendUInt16LE(0x0800)
            archive.appendUInt16LE(0)
            archive.appendUInt16LE(0)
            archive.appendUInt16LE(0)
            archive.appendUInt32LE(entry.data.crc32(checksum: 0))
            archive.appendUInt32LE(UInt32.max)
            archive.appendUInt32LE(UInt32.max)
            archive.appendUInt16LE(UInt16(name.count))
            archive.appendUInt16LE(UInt16(localExtra.count))
            archive.append(name)
            archive.append(localExtra)
            archive.append(entry.data)

            var centralExtra = Data()
            centralExtra.appendUInt16LE(0x0001)
            centralExtra.appendUInt16LE(24)
            centralExtra.appendUInt64LE(UInt64(entry.data.count))
            centralExtra.appendUInt64LE(UInt64(entry.data.count))
            centralExtra.appendUInt64LE(localHeaderOffset)

            centralDirectory.appendUInt32LE(0x0201_4b50)
            centralDirectory.appendUInt16LE(45)
            centralDirectory.appendUInt16LE(45)
            centralDirectory.appendUInt16LE(0x0800)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt32LE(entry.data.crc32(checksum: 0))
            centralDirectory.appendUInt32LE(UInt32.max)
            centralDirectory.appendUInt32LE(UInt32.max)
            centralDirectory.appendUInt16LE(UInt16(name.count))
            centralDirectory.appendUInt16LE(UInt16(centralExtra.count))
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt32LE(0)
            centralDirectory.appendUInt32LE(UInt32.max)
            centralDirectory.append(name)
            centralDirectory.append(centralExtra)
        }

        let centralDirectoryOffset = UInt64(archive.count)
        let centralDirectorySize = UInt64(centralDirectory.count)
        archive.append(centralDirectory)

        let zip64EOCDOffset = UInt64(archive.count)
        archive.appendUInt32LE(0x0606_4b50)
        archive.appendUInt64LE(44)
        archive.appendUInt16LE(45)
        archive.appendUInt16LE(10) // Outlook OLM sample uses 1.0 here despite ZIP64 fields.
        archive.appendUInt32LE(0)
        archive.appendUInt32LE(0)
        archive.appendUInt64LE(UInt64(entries.count))
        archive.appendUInt64LE(UInt64(entries.count))
        archive.appendUInt64LE(centralDirectorySize)
        archive.appendUInt64LE(centralDirectoryOffset)

        archive.appendUInt32LE(0x0706_4b50)
        archive.appendUInt32LE(0)
        archive.appendUInt64LE(zip64EOCDOffset)
        archive.appendUInt32LE(1)

        archive.appendUInt32LE(0x0605_4b50)
        archive.appendUInt16LE(UInt16.max)
        archive.appendUInt16LE(UInt16.max)
        archive.appendUInt16LE(UInt16.max)
        archive.appendUInt16LE(UInt16.max)
        archive.appendUInt32LE(UInt32.max)
        archive.appendUInt32LE(UInt32.max)
        archive.appendUInt16LE(0)

        try archive.write(to: url)
        return url
    }
}

private extension Data {
    mutating func appendUInt16LE(_ value: UInt16) {
        append(UInt8(value & 0x00ff))
        append(UInt8(value >> 8))
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        appendUInt16LE(UInt16(value & 0x0000_ffff))
        appendUInt16LE(UInt16(value >> 16))
    }

    mutating func appendUInt64LE(_ value: UInt64) {
        appendUInt32LE(UInt32(value & 0x0000_0000_ffff_ffff))
        appendUInt32LE(UInt32(value >> 32))
    }
}
