//
//  InsightReportJobStore.swift
//  Forma
//
//  Created by Codex on 30/06/26.
//

import Foundation

enum InsightReportJobStore {
    private static func key(for profileId: UUID) -> String {
        "pendingInsightReportJobIds.\(profileId.uuidString)"
    }

    static func jobIds(for profileId: UUID) -> [UUID] {
        (UserDefaults.standard.stringArray(forKey: key(for: profileId)) ?? []).compactMap(UUID.init(uuidString:))
    }

    static func add(_ jobId: UUID, for profileId: UUID) {
        var jobIds = jobIds(for: profileId)

        if !jobIds.contains(jobId) {
            jobIds.insert(jobId, at: 0)
        }

        UserDefaults.standard.set(jobIds.map(\.uuidString), forKey: key(for: profileId))
    }

    static func remove(_ jobId: UUID, for profileId: UUID) {
        let remainingJobIds = jobIds(for: profileId).filter { $0 != jobId }
        UserDefaults.standard.set(remainingJobIds.map(\.uuidString), forKey: key(for: profileId))
    }
}
