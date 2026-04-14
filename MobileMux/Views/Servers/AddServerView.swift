import SwiftUI
import SwiftData

struct AddServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nickname = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var authMethod: AuthMethod = .key
    @State private var password = ""
    @State private var showingKeyPicker = false
    @State private var selectedKeyData: Data?
    @State private var keyFilename: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Nickname", text: $nickname)
                        .textContentType(.nickname)
                    TextField("Host", text: $host)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }

                Section("Authentication") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)

                    Picker("Method", selection: $authMethod) {
                        Text("SSH Key").tag(AuthMethod.key)
                        Text("Password").tag(AuthMethod.password)
                    }

                    if authMethod == .password {
                        SecureField("Password", text: $password)
                    } else {
                        Button {
                            showingKeyPicker = true
                        } label: {
                            HStack {
                                Text(keyFilename ?? "Select Key File")
                                Spacer()
                                if selectedKeyData != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .fileImporter(
                isPresented: $showingKeyPicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        selectedKeyData = try? Data(contentsOf: url)
                        keyFilename = url.lastPathComponent
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        !nickname.isEmpty && !host.isEmpty && !username.isEmpty && (
            authMethod == .password ? !password.isEmpty : selectedKeyData != nil
        )
    }

    private func save() {
        let server = ServerConnection(
            nickname: nickname,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            authMethod: authMethod
        )
        modelContext.insert(server)

        // Store credential in Keychain
        do {
            if authMethod == .password {
                try KeychainService.shared.savePassword(password, for: server)
            } else if let keyData = selectedKeyData {
                try KeychainService.shared.savePrivateKey(keyData, for: server)
            }
        } catch {
            // Credential save failed — server is saved but will need credential re-entry
        }

        dismiss()
    }
}
