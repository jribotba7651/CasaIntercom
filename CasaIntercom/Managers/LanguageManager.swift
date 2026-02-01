import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            }
        }
    }

    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.currentLanguage = Language(rawValue: saved) ?? .english
    }

    // MARK: - Localized Strings

    var appTitle: String {
        currentLanguage == .english ? "🏠 Casa Intercom" : "🏠 Casa Intercom"
    }

    var tapToTalk: String {
        currentLanguage == .english ? "Tap a device to talk" : "Toca un dispositivo para hablar"
    }

    var noDevicesFound: String {
        currentLanguage == .english ? "No devices found" : "No se encontraron dispositivos"
    }

    var searchingDevices: String {
        currentLanguage == .english ? "Searching for devices..." : "Buscando dispositivos..."
    }

    var talkToAll: String {
        currentLanguage == .english ? "TALK TO ALL" : "HABLAR A TODOS"
    }

    var holdToTalk: String {
        currentLanguage == .english ? "Hold to talk" : "Mantener presionado"
    }

    var transmitting: String {
        currentLanguage == .english ? "Transmitting..." : "Transmitiendo..."
    }

    var talkingTo: String {
        currentLanguage == .english ? "Talking to" : "Hablando a"
    }

    var broadcastingToAll: String {
        currentLanguage == .english ? "📢 Broadcasting to all..." : "📢 Transmitiendo a todos..."
    }

    // Settings
    var settings: String {
        currentLanguage == .english ? "Settings" : "Configuración"
    }

    var myDevice: String {
        currentLanguage == .english ? "My Device" : "Mi Dispositivo"
    }

    var deviceName: String {
        currentLanguage == .english ? "Name" : "Nombre"
    }

    var deviceNameDescription: String {
        currentLanguage == .english ? "This name will appear on other devices." : "Este nombre aparecerá en otros dispositivos."
    }

    var language: String {
        currentLanguage == .english ? "Language" : "Idioma"
    }

    var about: String {
        currentLanguage == .english ? "About" : "Acerca de"
    }

    var version: String {
        currentLanguage == .english ? "Version" : "Versión"
    }

    var developedBy: String {
        currentLanguage == .english ? "Developed by" : "Desarrollado por"
    }

    var done: String {
        currentLanguage == .english ? "Done" : "Listo"
    }

    var connectedDevices: String {
        currentLanguage == .english ? "Connected Devices" : "Dispositivos Conectados"
    }
}
