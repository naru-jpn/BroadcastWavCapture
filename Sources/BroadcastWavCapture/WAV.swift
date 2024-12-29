//
//  WAV.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import Foundation

/// WAV for 1-Channel LPCM
public struct WAV {
    public let sampleRate: UInt32
}

extension WAV {
    /// Represent RIFF header.
    public struct RIFFHeader {
        /// Marks the file as a riff file
        /// 1-4
        public let mark = "RIFF"
        /// Size of the overall file - 8 bytes
        /// 5-8
        public let fileSize: UInt32
        /// File Type Header.
        /// 9-12
        public let fileType = "WAVE"

        public init(fileSize: UInt32) {
            self.fileSize = fileSize
        }

        /// Represent as Data
        public var data: Data {
            guard let mark = mark.data(using: .utf8) else {
                fatalError("Failed to get data for mark.")
            }
            let fileSize = {
                var littleEndian = self.fileSize.littleEndian
                return Data(bytes: &littleEndian, count: 4)
            }()
            guard let fileType = fileType.data(using: .utf8) else {
                fatalError("Failed to get data for fileType.")
            }
            return mark + fileSize + fileType
        }
    }

    /// Represent format chunk.
    public struct Format {
        /// Marks the format chunk
        /// 13-16
        public let mark: String = "fmt "
        /// Fixed `16` for PCM
        /// 17-20
        public let size: UInt32 = 16
        /// Fixed `1` for PCM
        /// 21-22
        public let format: UInt16 = 1
        /// Monaural
        /// 23-24
        public let numChannels: UInt16 = 1
        /// Sample rate
        /// 25-28
        public let sampleRate: UInt32
        /// Byte rate (SampleRate x NumChannels x BitsPerSample/8)
        /// 29-32
        public let byteRate: UInt32
        /// Bytes for single sample (NumChannels x BitsPerSample/8)
        /// 33-34
        public let blockAlign: UInt16 = 2
        /// Quantization bit rate
        /// 35-36
        public let bitsPerSample: UInt16 = 16

        init(sampleRate: UInt32) {
            self.sampleRate = sampleRate
            self.byteRate = sampleRate * UInt32(numChannels) * (UInt32(bitsPerSample) / 8)
        }

        /// Represent as Data
        public var data: Data {
            guard let mark = mark.data(using: .utf8) else {
                fatalError("Failed to get data for mark.")
            }
            let size = {
                var littleEndian = self.size.littleEndian
                return Data(bytes: &littleEndian, count: 4)
            }()
            let format = {
                var littleEndian = self.format.littleEndian
                return Data(bytes: &littleEndian, count: 2)
            }()
            let numChannels = {
                var littleEndian = self.numChannels.littleEndian
                return Data(bytes: &littleEndian, count: 2)
            }()
            let sampleRate = {
                var littleEndian = self.sampleRate.littleEndian
                return Data(bytes: &littleEndian, count: 4)
            }()
            let byteRate = {
                var littleEndian = self.byteRate.littleEndian
                return Data(bytes: &littleEndian, count: 4)
            }()
            let blockAlign = {
                var littleEndian = self.blockAlign.littleEndian
                return Data(bytes: &littleEndian, count: 2)
            }()
            let bitsPerSample = {
                var littleEndian = self.bitsPerSample.littleEndian
                return Data(bytes: &littleEndian, count: 2)
            }()
            return mark + size + format + numChannels + sampleRate + byteRate + blockAlign + bitsPerSample
        }
    }

    public struct DataHeader {
        /// Marks the format chunk
        /// 37-40
        public let mark: String = "data"
        /// Bytes of data
        /// 41-44
        public let dataSize: UInt32

        /// Represent as Data
        public var data: Data {
            guard let mark = mark.data(using: .utf8) else {
                fatalError("Failed to get data for mark.")
            }
            let dataSize = {
                var littleEndian = self.dataSize.littleEndian
                return Data(bytes: &littleEndian, count: 4)
            }()
            return mark + dataSize
        }
    }

    public struct Headers {
        public let riffHeader: RIFFHeader
        public let format: Format
        public let dataHeader: DataHeader

        public init(riffHeader: RIFFHeader, format: Format, dataHeader: DataHeader) {
            self.riffHeader = riffHeader
            self.format = format
            self.dataHeader = dataHeader
        }

        public var data: Data {
            riffHeader.data + format.data + dataHeader.data
        }
    }
}

extension WAV {
    public var headersForEmptyWav: Headers {
        let dataSize: UInt32 = 0
        return Headers(
            riffHeader: RIFFHeader(fileSize: dataSize + 44 - 8),
            format: Format(sampleRate: sampleRate),
            dataHeader: DataHeader(dataSize: dataSize)
        )
    }

    public var dataForEmptyWav: Data {
        headersForEmptyWav.data
    }
}
