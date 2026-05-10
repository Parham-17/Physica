import AVFoundation
import Observation

@Observable
final class AudioManager {
    enum SFX: String {
        case tap
        case lightOn = "light_on"
        case discoveryChime = "discovery_chime"
        case levelComplete = "level_complete"
        case starEarned = "star_earned"
        case lockedAttempt = "locked_attempt"
        case wireConnect = "wire_connect"
        case bulbLight = "bulb_light"
        case sparkWake = "spark_wake"
        case glitch = "glitch"
    }

    enum Ambient: String {
        case shadowCave = "ambient_shadow_cave"
        case voltCityHum = "ambient_volt_city"
        case none = ""
    }

    var isMuted: Bool = false
    var currentAmbient: Ambient = .none

    private var sfxPlayers: [AVAudioPlayer] = []
    private var ambientPlayer: AVAudioPlayer?

    func play(_ sfx: SFX) {
        guard !isMuted else { return }
        guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav") else {
            // W1 stub: assets land in W8. No-op by design.
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            sfxPlayers.append(player)
            sfxPlayers = sfxPlayers.filter { $0.isPlaying }
        } catch {
            return
        }
    }

    func startAmbient(_ ambient: Ambient) {
        guard ambient != currentAmbient else { return }
        stopAmbient()
        currentAmbient = ambient
        guard !isMuted, ambient != .none,
              let url = Bundle.main.url(forResource: ambient.rawValue, withExtension: "mp3") else {
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.6
            player.play()
            ambientPlayer = player
        } catch {
            return
        }
    }

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentAmbient = .none
    }
}
