//
//  AudioManager.swift
//  chatXMPPdemo
//
//  Created by Smith Huamani on 5/03/18.
//  Copyright © 2018 Smith Huamani. All rights reserved.
//

import Foundation
import AVFoundation

class AudioManager {
    
    static let sharedInstance = AudioManager()
    
    var audioRecorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    
    func setup() {
        
        let audioRecordingSession = AVAudioSession.sharedInstance()
        
        do {
            
            try audioRecordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try audioRecordingSession.setActive(true)
            
            audioRecordingSession.requestRecordPermission { (allowed) in
                
                DispatchQueue.main.async {
                    if allowed {
                        print("Se acepto los permisos de Audio")
                    }else {
                        print("Se rechazo los permisos de Audio")
                    }
                }
            }
            
        } catch let error {
            
            print(error.localizedDescription)
            finishRecording()
        }
    }
    
    func startRecording(fileName: String) {
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 2,
                        AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
        } catch let error {
            finishRecording()
            fatalError(error.localizedDescription)
        }
        
    }
    
    private func getDocumentsDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first!
    }
    
    public func searchDocumentsDirectory() -> String {
        let paths: [Any] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths.last! as! String
    }
    
    func finishRecording()  {
        
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    public func playAudio(url: URL) {
        
        do {
            let sound = try AVAudioPlayer(contentsOf: url)
            player = sound
            
            sound.prepareToPlay()
            sound.play()
            sound.volume = 1.0
            
        } catch {
            print("error loading file")
        }
        
    }
    
}
