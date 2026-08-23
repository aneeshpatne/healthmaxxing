//
//  PrimaryProfileStore.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation

enum PrimaryProfileStore {
    private static let key = "primaryProfileId"

    static var primaryProfileId: UUID? {
        get {
            guard let value = UserDefaults.standard.string(forKey: key) else {
                return nil
            }

            return UUID(uuidString: value)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    @discardableResult
    static func sync(from profiles: [ClientProfile]) -> UUID? {
        guard let primaryProfileId = profiles.first(where: \.isPrimary)?.id else {
            self.primaryProfileId = nil
            return nil
        }

        self.primaryProfileId = primaryProfileId
        return primaryProfileId
    }
}
