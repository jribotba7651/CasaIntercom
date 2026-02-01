import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var languageManager: LanguageManager
    @State private var deviceName: String = UIDevice.current.name

    var body: some View {
        NavigationStack {
            Form {
                // Device Section
                Section(header: Text(languageManager.myDevice)) {
                    TextField(languageManager.deviceName, text: $deviceName)
                        .font(.body)

                    Text(languageManager.deviceNameDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Language Section
                Section(header: Text(languageManager.language)) {
                    Picker(languageManager.language, selection: $languageManager.currentLanguage) {
                        ForEach(LanguageManager.Language.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Connected Devices Section
                Section(header: Text(languageManager.connectedDevices)) {
                    Text(languageManager.searchingDevices)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // About Section
                Section(header: Text(languageManager.about)) {
                    HStack {
                        Text(languageManager.version)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(languageManager.developedBy)
                        Spacer()
                        Text("Juan C")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(languageManager.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(languageManager: LanguageManager.shared)
}
