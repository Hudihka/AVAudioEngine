//
//  TestViewController.swift
//  Raycast
//
//  Created by Админ on 01.04.2020.
//  Copyright © 2020 Razeware. All rights reserved.
//

import UIKit
import AVFoundation

class TestViewController: UIViewController {

    let engine = AVAudioEngine()

    struct K {
        static let secondsPerChunk: Float64 = 10 //длительность одного куска
    }

    var chunkFile: AVAudioFile! = nil
    var outputFramesPerSecond: Float64 = 0  // aka input sample rate
    var chunkFrames: AVAudioFrameCount = 0  //количество кусков
    var chunkFileNumber: Int = 0
    
    

    func writeBuffer(_ buffer: AVAudioPCMBuffer) {
        let samplesPerSecond = buffer.format.sampleRate

        if chunkFile == nil {
            createNewChunkFile(numChannels: buffer.format.channelCount, samplesPerSecond: samplesPerSecond)
        }

        try! chunkFile.write(from: buffer)
        chunkFrames += buffer.frameLength

        if chunkFrames > AVAudioFrameCount(K.secondsPerChunk * samplesPerSecond) {
            chunkFile = nil // close file
        }
    }

    func createNewChunkFile(numChannels: AVAudioChannelCount, samplesPerSecond: Float64) {
        
        let fileUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("chunk-\(chunkFileNumber).aac")!
        print("writing chunk to \(fileUrl)")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: 64000,
            AVNumberOfChannelsKey: numChannels,
            AVSampleRateKey: samplesPerSecond
        ]

        chunkFile = try! AVAudioFile(forWriting: fileUrl, settings: settings)

        chunkFileNumber += 1
        chunkFrames = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let input = engine.inputNode

        let bus = 0
        let inputFormat = input.inputFormat(forBus: bus)

        input.installTap(onBus: bus, bufferSize: 512, format: inputFormat) { (buffer, time) -> Void in
            DispatchQueue.main.async {
                self.writeBuffer(buffer)
            }
        }

        try! engine.start()
    }
}
