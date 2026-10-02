import Foundation

@MainActor
final class HoriiAuthManager: ObservableObject {
    @Published private(set) var deviceID: String?
    @Published private(set) var isAuthenticated = false

    private let keychain = KeychainStore()
    private let tokenKey = "horii.core.token"
    private let deviceIDKey = "horii.core.deviceID"

    init() {
        deviceID = try? keychain.get(deviceIDKey)
        isAuthenticated = (try? keychain.get(tokenKey)) != nil
    }

    func token() -> String? {
        try? keychain.get(tokenKey)
    }

    func save(_ credential: HoriiDeviceCredential) throws {
        try keychain.set(credential.token, for: tokenKey)
        try keychain.set(credential.deviceID, for: deviceIDKey)
        deviceID = credential.deviceID
        isAuthenticated = true
    }

    func signOut() throws {
        try keychain.remove(tokenKey)
        try keychain.remove(deviceIDKey)
        deviceID = nil
        isAuthenticated = false
    }
}
