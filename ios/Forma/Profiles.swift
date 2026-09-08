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

    @State private var profiles: [ClientProfile] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isShowingAddProfile = false
    @State private var editingProfile: ClientProfile?

    private let apiClient = APIClient()

    var body: some View {
        ScrollView {
            profileContent
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
                addProfileButton
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
        // Sheets provide their own presentation feedback; keep haptics for errors only.
        .formaFeedback(FormaUIFeedback.error, trigger: errorMessage) { oldMessage, newMessage in
            oldMessage != newMessage && newMessage != nil
        }
    }

    private var addProfileButton: some View {
        Button {
            isShowingAddProfile = true
        } label: {
            Image(systemName: "plus")
                .font(FormaTypography.system(size: 15, weight: .semibold))
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Add Profile")
        .accessibilityIdentifier("profiles-add-button")
    }

    @ViewBuilder
    private var profileContent: some View {
        LazyVStack(spacing: FormaSpacing.md) {
            if let errorMessage, !profiles.isEmpty {
                inlineErrorBanner(errorMessage)
            }

            if let errorMessage, profiles.isEmpty {
                FormaStatusView(
                    title: "Couldn't Load Profiles",
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .formaNegative,
                    actionTitle: "Try Again",
                    actionTint: .sleekAccent
                ) {
                    Task {
                        await loadProfiles()
                    }
                }
            } else if isLoading && profiles.isEmpty {
                loadingProfilesView
            } else if profiles.isEmpty {
                FormaStatusView(
                    title: "No Profiles Yet",
                    message: "Create or connect a client profile to get started with tracking.",
                    systemImage: "person.2.crop.horizontal",
                    tint: .sleekAccent
                )
            } else {
                ForEach(profiles) { profile in
                    ProfileRow(profile: profile, onEdit: {
                        editProfile(profile)
                    })
                }
            }
        }
    }

    private var loadingProfilesView: some View {
        VStack(spacing: FormaSpacing.cardGap) {
            HStack(spacing: FormaSpacing.sm) {
                FormaLoadingIndicator()
                Text("Loading profiles")
                    .font(FormaTypography.supporting.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            ForEach(0..<3, id: \.self) { _ in
                SkeletonCardView()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading profiles")
        .accessibilityIdentifier("profiles-loading")
    }

    private func inlineErrorBanner(_ message: String) -> some View {
        HStack(spacing: FormaSpacing.sm) {
            FormaIconTile(systemImage: "exclamationmark.triangle.fill", tint: .formaNegative)

            Text(message)
                .font(FormaTypography.body)
                .foregroundStyle(.secondary)
                .lineLimit(nil)

            Spacer()

            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
            .accessibilityLabel("Dismiss")
        }
        .formaSurface(.card, padding: FormaSpacing.md, tint: .formaNegative)
    }

    private func editProfile(_ profile: ClientProfile) {
        editingProfile = profile
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
                    HStack(spacing: FormaSpacing.sm) {
                        FormaLoadingIndicator()
                        Text("Checking your profile")
                            .font(FormaTypography.supporting.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }

                    FormaSkeletonCard()
                    FormaSkeletonCard()
                    FormaSkeletonCard()
                }
                .padding(.horizontal, FormaSpacing.screenGutter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FormaBackground())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Checking your profile")
                .accessibilityIdentifier("primary-profile-loading")

            case .ready:
                SwiftUIView()

            case .requiresProfile:
                NavigationStack {
                    VStack(spacing: 0) {
                        VStack(spacing: FormaSpacing.xs) {
                            Text("Create Your Primary Profile")
                                .font(FormaTypography.sectionTitle)
                                .foregroundStyle(.primary)

                            Text("A primary profile is required before using Forma.")
                                .font(FormaTypography.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, FormaSpacing.xl)
                        .padding(.top, FormaSpacing.xl)
                        .padding(.bottom, FormaSpacing.xs)

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
                    tint: .formaNegative,
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
    @State private var muscularityGoal = ProfileMuscularityGoal.athletic
    @State private var profileImage = ""
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var saveSuccessNonce = 0
    @State private var saveErrorNonce = 0
    @State private var cancelFeedbackNonce = 0
    @State private var hasEditedName = false
    @FocusState private var focusedField: ProfileFormField?

    private enum ProfileFormField: Hashable {
        case name
        case profileImage
    }

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
        _muscularityGoal = State(
            initialValue: ProfileMuscularityGoal(rawValue: profile?.muscularityGoal ?? "") ?? .athletic
        )
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

    private var saveButtonTitle: String {
        isEditing ? "Save" : "Add"
    }

    private var saveAccessibilityLabel: String {
        if isSaving {
            return "Saving profile"
        }
        return isEditing ? "Save profile" : "Add profile"
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

    private var profileImageFooterMessage: String {
        profileImageError ?? "Body-fat preference personalizes targets. The profile image is optional."
    }

    private var profileImageFooterColor: Color {
        profileImageError == nil ? .secondary : .formaNegative
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
                    .formaFocusRing(isFocused: focusedField == .name, cornerRadius: FormaRadius.inset)
                    .onChange(of: name) { _, _ in
                        hasEditedName = true
                    }

                Toggle("Primary profile", isOn: $isPrimary)
                    .disabled(requiresPrimaryProfile)
            } header: {
                formSectionHeader("Profile")
            } footer: {
                Text(
                    hasEditedName && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "A profile name is required."
                        : "The primary profile receives new scale measurements by default."
                )
                .font(FormaTypography.supporting)
                .foregroundStyle(
                    hasEditedName && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.formaNegative
                        : Color.secondary
                )
            }
            .font(FormaTypography.body)
            .listRowBackground(Color.appSecondaryBackground)
            .listRowSeparatorTint(Color.appSeparator)

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
                formSectionHeader("Details")
            } footer: {
                Text(peopleType.guidance)
                    .font(FormaTypography.supporting)
            }
            .font(FormaTypography.body)
            .listRowBackground(Color.appSecondaryBackground)
            .listRowSeparatorTint(Color.appSeparator)

            Section {
                Stepper(value: $preferredBodyFatPct, in: 3...60, step: 1) {
                    HStack {
                        Text("Body Fat")
                        Spacer()
                        Text("\(Int(preferredBodyFatPct))%")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: FormaSpacing.sm) {
                    Text("How muscular would you like to become?")
                        .font(FormaTypography.body.weight(.semibold))

                    ForEach(ProfileMuscularityGoal.allCases) { goal in
                        Button {
                            muscularityGoal = goal
                        } label: {
                            HStack(alignment: .top, spacing: FormaSpacing.sm) {
                                Image(systemName: muscularityGoal == goal ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(muscularityGoal == goal ? Color.sleekAccent : Color.secondary)

                                VStack(alignment: .leading, spacing: FormaSpacing.xxs) {
                                    Text(goal.title)
                                        .foregroundStyle(.primary)
                                    Text(goal.guidance)
                                        .font(FormaTypography.supporting)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(goal.title)
                        .accessibilityHint(goal.guidance)
                        .accessibilityValue(muscularityGoal == goal ? "Selected" : "Not selected")
                    }
                }
                .padding(.vertical, FormaSpacing.xxs)

                TextField("Profile image URL", text: $profileImage)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .profileImage)
                    .formaFocusRing(isFocused: focusedField == .profileImage, cornerRadius: FormaRadius.inset)
            } header: {
                formSectionHeader("Preferences")
            } footer: {
                Text(profileImageFooterMessage)
                    .font(FormaTypography.supporting)
                    .foregroundStyle(profileImageFooterColor)
            }
            .font(FormaTypography.body)
            .listRowBackground(Color.appSecondaryBackground)
            .listRowSeparatorTint(Color.appSeparator)

            if let errorMessage {
                Section {
                    FormaCallout(
                        text: errorMessage,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .formaNegative
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, FormaSpacing.screenGutter, for: .scrollContent)
        .listSectionSpacing(FormaSpacing.lg)
        .background(FormaBackground())
        .tint(.sleekAccent)
        .navigationTitle(isEditing ? "Edit Profile" : "Add Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if allowsCancel {
                    Button("Cancel") {
                        cancelFeedbackNonce += 1
                        dismiss()
                    }
                    .disabled(isSaving)
                    .accessibilityIdentifier("profile-form-cancel-button")
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await saveProfile()
                    }
                } label: {
                    saveButtonLabel
                }
                .disabled(!canSave)
                .accessibilityLabel(saveAccessibilityLabel)
                .accessibilityValue(isSaving ? "In progress" : "")
                .accessibilityIdentifier("profile-form-save-button")
            }
        }
        .formaFeedback(FormaUIFeedback.softImpact, trigger: cancelFeedbackNonce)
        .formaFeedback(FormaUIFeedback.success, trigger: saveSuccessNonce)
        .formaFeedback(FormaUIFeedback.error, trigger: saveErrorNonce)
        .formaFeedback(FormaUIFeedback.selection, trigger: peopleType)
        .formaFeedback(FormaUIFeedback.selection, trigger: gender)
        .formaFeedback(FormaUIFeedback.selection, trigger: muscularityGoal)
        .formaFeedback(FormaUIFeedback.selection, trigger: isPrimary)
    }

    @ViewBuilder
    private var saveButtonLabel: some View {
        if isSaving {
            HStack(spacing: FormaSpacing.xs) {
                FormaLoadingIndicator()
                Text("Saving")
            }
            .accessibilityIdentifier("profile-save-loading")
        } else {
            Text(saveButtonTitle)
        }
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
                    preferredBodyFatPct: preferredBodyFatPct,
                    muscularityGoal: muscularityGoal.rawValue
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
                    preferredBodyFatPct: preferredBodyFatPct,
                    muscularityGoal: muscularityGoal.rawValue
                )

                let response = try await apiClient.send(CreateClientProfileRequest(body: requestBody))
                if response.isPrimary {
                    PrimaryProfileStore.primaryProfileId = response.profileId
                }
            }

            saveSuccessNonce += 1
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
    }

    private func formSectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(FormaTypography.eyebrow)
            .tracking(0.7)
            .foregroundStyle(Color.sleekAccent)
            .accessibilityLabel(title)
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

private enum ProfileMuscularityGoal: String, CaseIterable, Identifiable {
    case maintain
    case athletic
    case muscular
    case veryMuscular = "very_muscular"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maintain: "Maintain"
        case .athletic: "Athletic"
        case .muscular: "Muscular"
        case .veryMuscular: "Very muscular"
        }
    }

    var guidance: String {
        switch self {
        case .maintain: "Keep my current lean mass and focus on body fat."
        case .athletic: "Build a moderate amount of lean mass."
        case .muscular: "Aim for visibly greater muscle development."
        case .veryMuscular: "Pursue an advanced long-term muscularity target."
        }
    }
}

private struct ProfileRow: View {
    let profile: ClientProfile
    let onEdit: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var scaledAvatarSize: CGFloat = 60

    private var avatarSize: CGFloat {
        min(scaledAvatarSize, dynamicTypeSize.isAccessibilitySize ? 84 : 72)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.md) {
            profileHeader

            FormaDivider()

            if let peopleType = profile.peopleType, !peopleType.isEmpty {
                VStack(alignment: .leading, spacing: FormaSpacing.xxs) {
                    Text("Role")
                        .font(FormaTypography.supporting)
                        .foregroundStyle(.secondary)
                    Text(peopleType)
                        .font(FormaTypography.body)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            let hasStats = profile.heightCm != nil
                || profile.preferredBodyFatPct != nil
                || profile.muscularityGoal != nil
                || profile.gender != nil
                || profile.dateOfBirth != nil
            if hasStats {
                VStack(alignment: .leading, spacing: FormaSpacing.sm) {
                    if let height = profile.heightCm {
                        metadataRow(systemImage: "ruler", label: "Height", value: String(format: "%.0f cm", height))
                    }
                    if let fat = profile.preferredBodyFatPct {
                        metadataRow(systemImage: "percent", label: "Preferred Body Fat", value: String(format: "%.0f%%", fat))
                    }
                    if let goal = profile.muscularityGoal,
                       let muscularityGoal = ProfileMuscularityGoal(rawValue: goal) {
                        metadataRow(
                            systemImage: "figure.strengthtraining.traditional",
                            label: "Muscularity Goal",
                            value: muscularityGoal.title
                        )
                    }
                    if let dob = profile.dateOfBirth, !dob.isEmpty {
                        metadataRow(systemImage: "calendar", label: "Age", value: formatDOBOrAge(dob))
                    }
                    if let gender = profile.gender, !gender.isEmpty {
                        metadataRow(systemImage: "person.fill", label: "Gender", value: gender.capitalized)
                    }
                }
                .padding(.top, FormaSpacing.xxs)
            }
        }
        .formaSurface(
            .card,
            padding: FormaSpacing.cardInset,
            tint: profile.isPrimary ? .sleekAccent : nil
        )
        .accessibilityValue(profile.isPrimary ? "Primary profile" : "")
    }

    @ViewBuilder
    private var profileHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: FormaSpacing.sm) {
                avatarView
                profileIdentity
                editButton(expanded: true)
            }
        } else {
            HStack(alignment: .top, spacing: FormaSpacing.md) {
                avatarView
                profileIdentity
                Spacer(minLength: FormaSpacing.xs)
                editButton(expanded: false)
            }
        }
    }

    private var profileIdentity: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.xs) {
            Text(profile.displayName)
                .font(FormaTypography.cardTitle)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if profile.isPrimary {
                Label("Primary profile", systemImage: "checkmark.seal.fill")
                    .font(FormaTypography.supporting.weight(.semibold))
                    .foregroundStyle(Color.sleekAccent)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let imageUrlString = profile.profileImage, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        ZStack {
                            Circle()
                                .fill(Color.appTertiaryBackground)
                            FormaLoadingIndicator(tint: .sleekAccent)
                        }
                    case .failure:
                        initialsView(for: profile.displayName)
                    @unknown default:
                        initialsView(for: profile.displayName)
                    }
                }
            } else {
                initialsView(for: profile.displayName)
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(
                    profile.isPrimary ? Color.sleekAccent.opacity(0.28) : Color.appBorder,
                    lineWidth: 0.75
                )
        }
        .accessibilityHidden(true)
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
                    .font(FormaTypography.textStyle(.title3, weight: .bold))
                    .foregroundStyle(Color.sleekAccent)
                    .minimumScaleFactor(0.75)
            }
    }

    private func editButton(expanded: Bool) -> some View {
        Button(action: onEdit) {
            HStack(spacing: FormaSpacing.xs) {
                Image(systemName: "pencil")
                    .font(FormaTypography.action)
                if expanded {
                    Text("Edit Profile")
                        .font(FormaTypography.action)
                }
            }
            .foregroundStyle(Color.sleekAccent)
            .frame(maxWidth: expanded ? .infinity : nil)
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, expanded ? FormaSpacing.sm : 0)
            .background(
                Color.sleekAccent.opacity(0.12),
                in: expanded ? AnyShape(Capsule()) : AnyShape(Circle())
            )
        }
        .buttonStyle(FormaPressableButtonStyle())
        .accessibilityLabel("Edit \(profile.displayName)")
        .accessibilityIdentifier("profile-edit-\(profile.id)")
    }

    @ViewBuilder
    private func metadataRow(systemImage: String, label: String, value: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(alignment: .top, spacing: FormaSpacing.sm) {
                metadataIcon(systemImage)
                VStack(alignment: .leading, spacing: FormaSpacing.xxs) {
                    Text(label)
                        .font(FormaTypography.supporting)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(FormaTypography.sectionHeadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: FormaSpacing.xs) {
                metadataIcon(systemImage)
                Text(label + ":")
                    .font(FormaTypography.body)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(FormaTypography.sectionHeadline)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func metadataIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(FormaTypography.body)
            .foregroundStyle(Color.secondary)
            .frame(width: 20, alignment: .leading)
            .accessibilityHidden(true)
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

            VStack(alignment: .leading, spacing: FormaSpacing.xs) {
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
