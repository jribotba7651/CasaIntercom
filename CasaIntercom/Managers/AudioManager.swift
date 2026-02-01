import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    @Published var isRecording = false
    @Published var hasPermission = false

    private var engine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!

    // Use a consistent format for everything: mono, 16kHz, Float32
    private let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!

    // Callback to send audio data
    var onAudioData: ((Data) -> Void)?

    override init() {
        super.init()
        setupEngine()
        checkMicrophonePermission()
    }

    // MARK: - Setup

    private func setupEngine() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        engine.attach(playerNode)

        // Connect player with our consistent audio format
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFormat)

        print("Engine setup complete")
    }

    // MARK: - Permission

    func checkMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            hasPermission = true
            print("Microphone permission granted")
        case .denied:
            hasPermission = false
            print("Microphone permission denied")
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    print("Microphone permission: \(granted)")
                }
            }
        @unknown default:
            hasPermission = false
        }
    }

    private func activateAudioSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers])
            try session.setActive(true)
            print("Audio session active: \(session.sampleRate)Hz, \(session.inputNumberOfChannels) input channels")
            return true
        } catch {
            print("Failed to activate audio session: \(error)")
            return false
        }
    }

    // MARK: - Recording

    func startRecording() {
        print("startRecording called")

        guard hasPermission else {
            print("No microphone permission")
            checkMicrophonePermission()
            return
        }

        guard activateAudioSession() else {
            print("Could not activate audio session")
            return
        }

        // Remove any existing tap
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)

        // Start engine if not running
        if !engine.isRunning {
            do {
                try engine.start()
                print("Engine started")
            } catch {
                print("Failed to start engine: \(error)")
                return
            }
        }

        // Get the hardware format
        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        print("Hardware format: \(hardwareFormat.sampleRate)Hz, \(hardwareFormat.channelCount)ch")

        guard hardwareFormat.sampleRate > 0 && hardwareFormat.channelCount > 0 else {
            print("Invalid hardware format")
            return
        }

        isRecording = true

        // Install tap with hardware format
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, time in
            guard let self = self, self.isRecording else { return }

            if let data = self.bufferToData(buffer: buffer, sampleRate: hardwareFormat.sampleRate) {
                self.onAudioData?(data)
            }
        }

        print("Recording started")
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        engine.inputNode.removeTap(onBus: 0)
        print("Recording stopped")
    }

    // MARK: - Playback

    func playAudio(data: Data) {
        guard !data.isEmpty else { return }

        // Ensure audio session is active
        _ = activateAudioSession()

        // Start engine if needed
        if !engine.isRunning {
            do {
                try engine.start()
                print("Engine started for playback")
            } catch {
                print("Failed to start engine for playback: \(error)")
                return
            }
        }

        // Start player if needed
        if !playerNode.isPlaying {
            playerNode.play()
        }

        // Convert data to buffer and play
        if let buffer = dataToBuffer(data: data) {
            playerNode.scheduleBuffer(buffer, completionHandler: nil)
        }
    }

    // MARK: - Conversion

    private func bufferToData(buffer: AVAudioPCMBuffer, sampleRate: Double) -> Data? {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return nil }

        // Get float data
        guard let floatData = buffer.floatChannelData else { return nil }
        let channelData = floatData[0] // Use first channel (mono)

        // Convert float to Int16 for transmission (smaller size)
        var int16Data = [Int16](repeating: 0, count: frameLength)
        for i in 0..<frameLength {
            let sample = max(-1.0, min(1.0, channelData[i]))
            int16Data[i] = Int16(sample * Float(Int16.max))
        }

        // Prepend sample rate (4 bytes) so receiver knows the format
        var sampleRateUInt = UInt32(sampleRate)
        var result = Data(bytes: &sampleRateUInt, count: 4)
        result.append(Data(bytes: &int16Data, count: frameLength * 2))

        return result
    }

    private func dataToBuffer(data: Data) -> AVAudioPCMBuffer? {
        guard data.count > 4 else { return nil }

        // Extract sample rate from first 4 bytes (we ignore it and use our fixed format)
        let audioData = data.dropFirst(4)

        let frameLength = UInt32(audioData.count / 2) // Int16 = 2 bytes
        guard frameLength > 0 else { return nil }

        // Create buffer with our consistent format (mono, 16kHz, Float32)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameLength) else {
            print("Failed to create buffer")
            return nil
        }

        buffer.frameLength = frameLength

        guard let floatData = buffer.floatChannelData?[0] else {
            print("Failed to get float channel data")
            return nil
        }

        // Convert Int16 back to Float
        audioData.withUnsafeBytes { rawBuffer in
            let int16Ptr = rawBuffer.bindMemory(to: Int16.self)
            for i in 0..<Int(frameLength) {
                floatData[i] = Float(int16Ptr[i]) / Float(Int16.max)
            }
        }

        return buffer
    }
}
