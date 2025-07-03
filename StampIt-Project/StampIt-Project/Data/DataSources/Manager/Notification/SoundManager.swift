//
//  SoundManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/27/25.
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    func playNotificationSound() {
        guard let soundURL = Bundle.main.url(forResource: "notification_sound", withExtension: "mp3") else {
            // 기본 시스템 사운드 사용
            AudioServicesPlaySystemSound(SystemSoundID(1007))
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("사운드 재생 실패: \(error)")
            AudioServicesPlaySystemSound(SystemSoundID(1007))
        }
    }
}
