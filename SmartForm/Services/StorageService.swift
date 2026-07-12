import Foundation

/// 本地存储服务 — 使用 FileManager + JSON 编码
/// 生产环境可替换为 SwiftData / Core Data
final class StorageService {
    static let shared = StorageService()
    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var sessionsURL: URL {
        documentsURL.appendingPathComponent("sessions", isDirectory: true)
    }

    private var profileURL: URL {
        documentsURL.appendingPathComponent("profile.json")
    }

    init() {
        try? fileManager.createDirectory(at: sessionsURL, withIntermediateDirectories: true)
    }

    // MARK: - Sessions

    func saveSession(_ session: FormSession) throws {
        let url = sessionsURL.appendingPathComponent("\(session.id).json")
        let data = try JSONEncoder().encode(session)
        try data.write(to: url, options: .atomic)
    }

    func loadAllSessions() -> [FormSession] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: sessionsURL, includingPropertiesForKeys: nil
        ) else { return [] }

        return files.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let session = try? JSONDecoder().decode(FormSession.self, from: data)
            else { return nil }
            return session
        }.sorted { $0.lastSavedAt > $1.lastSavedAt }
    }

    func deleteSession(_ session: FormSession) throws {
        let url = sessionsURL.appendingPathComponent("\(session.id).json")
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - User Profile

    func saveProfile(_ profile: UserProfile) throws {
        let data = try JSONEncoder().encode(profile)
        try data.write(to: profileURL, options: .atomic)
    }

    func loadProfile() -> UserProfile? {
        guard let data = try? Data(contentsOf: profileURL),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }
        return profile
    }
}
