# BroadcastWavCapture

Swift Package to resample and record audio data as lenear PCM formatted single channel wav file.

## Installation

Supports SwiftPM.

## Reference

### [`WAV`](./Sources/BroadcastWavCapture/WAV.swift)

Struct defines binary structure(RIFF chunk, Format chunk, Data chunk) of WAV file.

### [`WAV.File`](./Sources/BroadcastWavCapture/WAV+File.swift)

- `static func load(from url: URL) throws -> WAV.File`
   - Return struct represents wav file stored on device storage.

### [`WAVWriter`](./Sources/BroadcastWavCapture/WAVWriter.swift)

- `init(url: URL, sampleRate: UInt32)`
   - Create wav file on device storage
- `func writeAudio(data: Data)`
   - Write contents of data chunk
- `func completeMetadata()`
   - Fill metadata for mainly content size

### [`WAVSignalResampler`](./Sources/BroadcastWavCapture/WAVSignalResampler.swift)

- `init(countInFlightBuffers: Int = 1)`
   - Initialize with parameter to apply number of buffering.

- `func resample(signalsOf sampleBuffer: CMSampleBuffer, sampleRate: Int) throws -> Data`
   - Extract audio buffer from CMSampleBuffer
   - Convert big-endian to little-endian.
   - Interpolates signals to adjust sampling rate.
 
## Sample Application

<img src="https://github.com/user-attachments/assets/a717bed2-adaf-43d9-8a97-d0c1eed0ec6b" width="100" alt="Application icon of BroadcastWavCaptureApp." title="BroadcastWavCaptureApp">

### [BroadcastWavCaptureApp](./App)

Record audio using broadcast upload extension and browse stored files from application.

<img src="https://github.com/user-attachments/assets/691c80da-2d38-4edc-bceb-355fb7f01602" width="750">

| List of files | Show information of WAV file | Preview audio wave form |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/c3324730-c809-44f3-b8fb-1399bc802d91" width="250"> | <img src="https://github.com/user-attachments/assets/7390398a-e681-4cb3-8d32-a5bbdc1805b6" width="250"> | <img src="https://github.com/user-attachments/assets/921cfc48-042e-4ba5-831a-6e73940c4e0f" width="250"> |
