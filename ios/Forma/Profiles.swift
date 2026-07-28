//
//  Profiles.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import SwiftUI
import ClerkKit

struct Profiles: View {
    @Environment(Clerk.self) private var clerk
    @EnvironmentObject private var soundPlayer: FormaSoundPlayer

    @State private var profiles: [ClientProfile] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isShowingAddProfile = false
    @State private var editingProfile: ClientProfile?

    private let apiClient = APIClient()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let errorMessage, !profiles.isEmpty {
                    // Inline warning banner
                    HStack(spacing: FormaSpacing.sm) {
                        FormaIconTile(systemImage: "exclamationmark.triangle.fill", tint: .formaCoral)

                        Text(errorMessage)
                            .font(FormaTypography.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)

                        Spacer()

                        Button {
                            self.errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .accessibilityLabel("Dismiss")
                    }
                    .formaSurface(.card, padding: FormaSpacing.md, tint: .formaCoral)
                }

                if let errorMessage, profiles.isEmpty {
                    FormaStatusView(
                        title: "Couldn't Load Profiles",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .formaCoral,
                        actionTitle: "Try Again",
                        actionTint: .sleekAccent
                    ) {
                        soundPlayer.play(FormaUIFeedback.softImpact)
                        Task {
                            await loadProfiles()
                        }
                    }
                } else if isLoading && profiles.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonCardView()
                        }
                    }
                } else if profiles.isEmpty {
                    FormaStatusView(
                        title: "No Profiles Yet",
                        message: "Create or connect a client profile to get started with tracking.",
                        systemImage: "person.2.crop.horizontal",
                        tint: .sleekAccent
                    )
                } else {
                    ForEach(profiles) { profile in
                        ProfileRow(profile: profile) {
                            editingProfile = profile
                        }
                    }
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, FormaSpacing.screenGutter)
            .padding(.vertical, FormaSpacing.lg)
        }
        .background(FormaBackground())
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    soundPlayer.play(FormaUIFeedback.softImpact)
                    isShowingAddProfile = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Add Profile")
                .sensoryFeedback(FormaUIFeedback.softImpact.sensoryFeedback, trigger: isShowingAddProfile) { _, shown in
                    shown
                }
            }
        }
        .sheet(isPresented: $isShowingAddProfile) {
            NavigationStack {
                ProfileFormView(apiClient: apiClient, profile: nil) {
                    await loadProfiles()
                }
            }
        }
        .sheet(item: $editingProfile) { profile in
            NavigationStack {
                ProfileFormView(apiClient: apiClient, profile: profile) {
                    await loadProfiles()
                }
            }
        }
        .refreshable {
            await loadProfiles()
        }
        .task {
            await loadProfiles()
        }
        .sensoryFeedback(FormaUIFeedback.error.sensoryFeedback, trigger: errorMessage) { _, message in
            message != nil
        }
    }

    private func loadProfiles() async {
        guard clerk.user != nil else {
            profiles = []
            errorMessage = "Sign in to load profiles."
            return
        }

        // Only set isLoading to true if profiles are empty, preventing rebuild of the ScrollView
        // when pull-to-refresh runs, which avoids task cancellation issues.
        let shouldShowLoading = profiles.isEmpty
        if shouldShowLoading {
            isLoading = true
        }
        errorMessage = nil

        defer {
            if shouldShowLoading {
                isLoading = false
            }
        }

        do {
            let response = try await apiClient.send(GetClientProfilesRequest())
            profiles = response.users
            PrimaryProfileStore.sync(from: response.users)
        } catch APIError.missingAuthToken {
            if profiles.isEmpty {
                profiles = []
            }
            errorMessage = "Missing auth token."
        } catch APIError.serverError(let statusCode, _) {
            if profiles.isEmpty {
                profiles = []
            }
            errorMessage = "Server returned \(statusCode)."
        } catch {
            // Check for task cancellation (very common during pull-to-refresh bounces) and ignore
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }
            if profiles.isEmpty {
                profiles = []
            }
            errorMessage = "Failed to load profiles."
        }
    }
}

struct PrimaryProfileGate: View {
    private enum LoadState {
        case checking
        case ready
        case requiresProfile
        case failed(String)
    }

    @State private var loadState = LoadState.checking

    private let apiClient = APIClient()

    var body: some View {
        Group {
            switch loadState {
            case .checking:
                VStack(spacing: FormaSpacing.cardGap) {
                    FormaSkeletonCard()
                    FormaSkeletonCard()
                    FormaSkeletonCard()
                }
                .padding(.horizontal, FormaSpacing.screenGutter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FormaBackground())

            case .ready:
                SwiftUIView()

            case .requiresProfile:
                NavigationStack {
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("Create Your Primary Profile")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)

                            Text("A primary profile is required before using Forma.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                        ProfileFormView(
                            apiClient: apiClient,
                            profile: nil,
                            requiresPrimaryProfile: true,
                            allowsCancel: false
                        ) {
                            await ensurePrimaryProfile()
                        }
                    }
                    .background(Color.appBackground.ignoresSafeArea())
                }

            case .failed(let message):
                FormaStatusView(
                    title: "Couldn't Load Profiles",
                    message: message,
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .formaCoral,
                    actionTitle: "Try Again",
                    actionTint: .sleekAccent
                ) {
                    Task {
                        await ensurePrimaryProfile()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground.ignoresSafeArea())
            }
        }
        .task {
            await ensurePrimaryProfile()
        }
    }

    private func ensurePrimaryProfile() async {
        if PrimaryProfileStore.primaryProfileId != nil {
            loadState = .ready
            return
        }

        loadState = .checking

        do {
            let response = try await apiClient.send(GetClientProfilesRequest())
            if PrimaryProfileStore.sync(from: response.users) != nil {
                loadState = .ready
            } else {
                loadState = .requiresProfile
            }
        } catch APIError.missingAuthToken {
            loadState = .failed("Missing auth token.")
        } catch APIError.serverError(let statusCode, _) {
            loadState = .failed("Server returned \(statusCode).")
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }

            loadState = .failed("Failed to load profiles.")
        }
    }
}

private struct ProfileFormView: View {
    @Environment(\.dismiss) private var dismiss

    let apiClient: APIClient
    let profile: ClientProfile?
    let onProfileSaved: () async -> Void
    let requiresPrimaryProfile: Bool
    let allowsCancel: Bool

    @State private var name = ""
    @State private var isPrimary = false
    @State private var heightCm = 175.0
    @State private var dateOfBirth = Date()
    @State private var peopleType = ProfilePeopleType.standard
    @State private var gender = ProfileGender.male
    @State private var preferredBodyFatPct = 18.0
    @State private var profileImage = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var saveSuccessNonce = 0
    @State private var saveErrorNonce = 0
    @State private var hasEditedName = false
    @EnvironmentObject private var soundPlayer: FormaSoundPlayer

    init(
        apiClient: APIClient,
        profile: ClientProfile?,
        requiresPrimaryProfile: Bool = false,
        allowsCancel: Bool = true,
        onProfileSaved: @escaping () async -> Void
    ) {
        self.apiClient = apiClient
        self.profile = profile
        self.onProfileSaved = onProfileSaved
        self.requiresPrimaryProfile = requiresPrimaryProfile
        self.allowsCancel = allowsCancel

        _name = State(initialValue: profile?.name ?? "")
        _isPrimary = State(initialValue: requiresPrimaryProfile ? true : profile?.isPrimary ?? false)
        _heightCm = State(initialValue: profile?.heightCm ?? 175.0)
        _dateOfBirth = State(initialValue: Self.parseDate(profile?.dateOfBirth) ?? Date())
        _peopleType = State(initialValue: ProfilePeopleType(rawValue: profile?.peopleType ?? "") ?? .standard)
        _gender = State(initialValue: ProfileGender(rawValue: profile?.gender ?? "") ?? .male)
        _preferredBodyFatPct = State(initialValue: profile?.preferredBodyFatPct ?? 18.0)
        _profileImage = State(initialValue: profile?.profileImage ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && profileImageError == nil
            && !isSaving
    }

    private var isEditing: Bool {
        profile != nil
    }

    private var profileImageError: String? {
        let trimmed = profileImage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return "Enter a complete http or https image URL."
        }
        return nil
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .onChange(of: name) { _, _ in
                        hasEditedName = true
                    }

                Toggle("Primary profile", isOn: $isPrimary)
                    .disabled(requiresPrimaryProfile)
            } header: {
                Text("Profile")
            } footer: {
                Text(
                    hasEditedName && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "A profile name is required."
                        : "The primary profile receives new scale measurements by default."
                )
                .foregroundStyle(
                    hasEditedName && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.formaCoral
                        : Color.secondary
                )
            }

            Section {
                Stepper(value: $heightCm, in: 80...260, step: 1) {
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(Int(heightCm)) cm")
                            .foregroundStyle(.secondary)
                    }
                }

                DatePicker(
                    "Date of Birth",
                    selection: $dateOfBirth,
                    in: ...Date(),
                    displayedComponents: .date
                )

                Picker("Type", selection: $peopleType) {
                    ForEach(ProfilePeopleType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }

                Picker("Gender", selection: $gender) {
                    ForEach(ProfileGender.allCases) { gender in
                        Text(gender.title).tag(gender)
                    }
                }
            } header: {
                Text("Details")
            } footer: {
                Text(peopleType.guidance)
            }

            Section {
                Stepper(value: $preferredBodyFatPct, in: 3...60, step: 1) {
                    HStack {
                        Text("Body Fat")
                        Spacer()
                        Text("\(Int(preferredBodyFatPct))%")
                            .foregroundStyle(.secondary)
                    }
                }

                TextField("Profile image URL", text: $profileImage)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Preferences")
            } footer: {
                Text(profileImageError ?? "Body-fat preference personalizes targets. The profile image is optional.")
                    .foregroundStyle(profileImageError == nil ? Color.secondary : Color.formaCoral)
            }

            if let errorMessage {
                Section {
                    FormaCallout(
                        text: errorMessage,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .formaCoral
                    )
                }
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .background(FormaBackground())
        .tint(.sleekAccent)
        .navigationTitle(isEditing ? "Edit Profile" : "Add Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if allowsCancel {
                    Button("Cancel") {
                        soundPlayer.play(FormaUIFeedback.softImpact)
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await saveProfile()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text(isEditing ? "Save" : "Add")
                    }
                }
                .disabled(!canSave)
            }
        }
        .sensoryFeedback(FormaUIFeedback.success.sensoryFeedback, trigger: saveSuccessNonce)
        .sensoryFeedback(FormaUIFeedback.error.sensoryFeedback, trigger: saveErrorNonce)
        .sensoryFeedback(FormaUIFeedback.selection.sensoryFeedback, trigger: peopleType)
        .sensoryFeedback(FormaUIFeedback.selection.sensoryFeedback, trigger: gender)
        .sensoryFeedback(FormaUIFeedback.selection.sensoryFeedback, trigger: isPrimary)
    }

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        let trimmedImage = profileImage.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let formattedDateOfBirth = Self.dateFormatter.string(from: dateOfBirth)

        do {
            if let profile {
                let requestBody = UpdateClientProfileBody(
                    name: trimmedName,
                    isPrimary: requiresPrimaryProfile ? true : isPrimary,
                    heightCm: heightCm,
                    dateOfBirth: formattedDateOfBirth,
                    peopleType: peopleType.rawValue,
                    gender: gender.rawValue,
                    profileImage: trimmedImage.isEmpty ? nil : trimmedImage,
                    preferredBodyFatPct: preferredBodyFatPct
                )

                let response = try await apiClient.send(UpdateClientProfileRequest(profileId: profile.id, body: requestBody))
                if response.isPrimary == true {
                    PrimaryProfileStore.primaryProfileId = response.profileId ?? profile.id
                }
            } else {
                let requestBody = CreateClientProfileBody(
                    name: trimmedName,
                    isPrimary: requiresPrimaryProfile ? true : isPrimary,
                    heightCm: heightCm,
                    dateOfBirth: formattedDateOfBirth,
                    peopleType: peopleType.rawValue,
                    gender: gender.rawValue,
                    profileImage: trimmedImage.isEmpty ? nil : trimmedImage,
                    preferredBodyFatPct: preferredBodyFatPct
                )

                let response = try await apiClient.send(CreateClientProfileRequest(body: requestBody))
                if response.isPrimary {
                    PrimaryProfileStore.primaryProfileId = response.profileId
                }
            }

            saveSuccessNonce += 1
            soundPlayer.play(FormaUIFeedback.success)
            await onProfileSaved()
            dismiss()
        } catch APIError.missingAuthToken {
            errorMessage = "Missing auth token."
            registerSaveError()
        } catch APIError.serverError(let statusCode, _) {
            if statusCode == 404 {
                errorMessage = "Profile not found for this account."
            } else {
                errorMessage = "Server returned \(statusCode)."
            }
            registerSaveError()
        } catch {
            errorMessage = isEditing ? "Failed to update profile." : "Failed to add profile."
            registerSaveError()
        }
    }

    private func registerSaveError() {
        saveErrorNonce += 1
        soundPlayer.play(FormaUIFeedback.error)
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }

        if let date = dateFormatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private enum ProfilePeopleType: String, CaseIterable, Identifiable {
    case standard
    case athlete

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var guidance: String {
        switch self {
        case .standard:
            return "Standard uses general body-composition ranges."
        case .athlete:
            return "Athlete is intended for consistently high-volume training and adjusts body-composition interpretation."
        }
    }
}

private enum ProfileGender: String, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

private struct ProfileRow: View {
    let profile: ClientProfile
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // Avatar
                if let imageUrlString = profile.profileImage, let url = URL(string: imageUrlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.appTertiaryBackground)
                            .shimmering()
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    initialsView(for: profile.displayName)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.displayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if profile.isPrimary {
                        Label("Primary profile", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.sleekAccent)
                    }
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.sleekAccent)
                        .frame(width: 44, height: 44)
                        .background(Color.sleekAccent.opacity(0.12), in: Circle())
                }
                .buttonStyle(FormaPressableButtonStyle())
                .accessibilityLabel("Edit \(profile.displayName)")
            }

            FormaDivider()

            // Role / Category Field
            if let peopleType = profile.peopleType, !peopleType.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Role")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(peopleType)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Stats / Metrics Fields
            let hasStats = profile.heightCm != nil || profile.preferredBodyFatPct != nil || profile.gender != nil || profile.dateOfBirth != nil
            if hasStats {
                VStack(alignment: .leading, spacing: 8) {
                    if let height = profile.heightCm {
                        metadataRow(systemImage: "ruler", label: "Height", value: String(format: "%.0f cm", height))
                    }
                    if let fat = profile.preferredBodyFatPct {
                        metadataRow(systemImage: "percent", label: "Preferred Body Fat", value: String(format: "%.0f%%", fat))
                    }
                    if let dob = profile.dateOfBirth, !dob.isEmpty {
                        metadataRow(systemImage: "calendar", label: "Age", value: formatDOBOrAge(dob))
                    }
                    if let gender = profile.gender, !gender.isEmpty {
                        metadataRow(systemImage: "person.fill", label: "Gender", value: gender.capitalized)
                    }
                }
                .padding(.top, 4)
            }
        }
        .formaSurface(
            .card,
            padding: FormaSpacing.cardInset,
            tint: profile.isPrimary ? .sleekAccent : nil
        )
        .accessibilityValue(profile.isPrimary ? "Primary profile" : "")
    }

    private func initialsView(for name: String) -> some View {
        let initials = name.split(separator: " ")
            .prefix(2)
            .map { String($0.prefix(1)) }
            .joined()
            .uppercased()

        return Circle()
            .fill(Color.sleekAccent.opacity(0.12))
            .overlay {
                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.sleekAccent)
            }
            .frame(width: 60, height: 60)
    }

    private func metadataRow(systemImage: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(Color.sleekAccent)
                .frame(width: 20, alignment: .leading)

            Text(label + ":")
                .font(.body)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func age(from dobString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dobString) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
            return ageComponents.year
        }
        // Try ISO format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dobString) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
            return ageComponents.year
        }
        return nil
    }

    private func formatDOBOrAge(_ dobString: String) -> String {
        if let age = age(from: dobString) {
            return "\(age) yrs"
        }

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        if let date = inputFormatter.date(from: dobString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }
        return dobString
    }
}

private struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.md) {
            HStack(spacing: FormaSpacing.md) {
                Circle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                    FormaSkeletonBlock(width: 140, height: 18, opacity: 0.14)
                    FormaSkeletonBlock(width: 70, height: 22, radius: 11, opacity: 0.10)
                }
                Spacer()
            }

            FormaDivider()

            VStack(alignment: .leading, spacing: 6) {
                FormaSkeletonBlock(width: 100, height: 12, opacity: 0.08)
                FormaSkeletonBlock(width: 200, height: 16, opacity: 0.10)
            }

            VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: FormaSpacing.xs) {
                        FormaSkeletonBlock(width: 16, height: 16, radius: 5, opacity: 0.10)
                        FormaSkeletonBlock(width: 120, height: 14, opacity: 0.08)
                    }
                }
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
        .shimmering()
    }
}

#Preview {
    NavigationStack {
        Profiles()
            .environment(Clerk.shared)
            .environmentObject(FormaSoundPlayer())
    }
}
