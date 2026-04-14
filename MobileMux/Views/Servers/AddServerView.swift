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
                Section {
                    TextField("Nickname", text: $nickname)
                        .textContentType(.nickname)
                    TextField("Host or IP address", text: $host)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Server")
                } footer: {
                    Text("Give your server a memorable name")
                }

                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("Method", selection: $authMethod) {
                        Label("SSH Key", systemImage: "key.fill")
                            .tag(AuthMethod.key)
                        Label("Password", systemImage: "lock.fill")
                            .tag(AuthMethod.password)
                    }
                    .pickerStyle(.segmented)

                    if authMethod == .password {
                        SecureField("Password", text: $password)
                    } else {
                        Button {
                            showingKeyPicker = true
                        } label: {
                            HStack {
                                Label(
                                    keyFilename ?? "Select private key",
                                    systemImage: selectedKeyData != nil
                                        ? "checkmark.circle.fill"
                                        : "doc.badge.plus"
                                )
                                .foregroundStyle(
                                    selectedKeyData != nil
                                        ? MMColors.online
                                        : Color.accentColor
                                )
                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Authentication")
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
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

        do {
            if authMethod == .password {
                try KeychainService.shared.savePassword(password, for: server)
            } else if let keyData = selectedKeyData {
                try KeychainService.shared.savePrivateKey(keyData, for: server)
            }
        } catch {
            // Credential save failed — server saved, credential re-entry needed on connect
        }

        dismiss()
    }
}

#Preview {
    AddServerView()
        .modelContainer(for: ServerConnection.self, inMemory: true)
        .preferredColorScheme(.dark)
        .tint(MMColors.teal)
}
