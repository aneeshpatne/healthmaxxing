import SwiftUI
import Charts
import Combine

@MainActor
private final class FoodStore: ObservableObject {
    @Published var dashboard: FoodDashboardResponse?
    @Published var savedFoods: [FoodNutrition] = []
    @Published var messages: [FoodChatMessage] = []
    @Published var proposal: FoodNutrition?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let api = APIClient()

    func load() async {
        guard let profileId = PrimaryProfileStore.primaryProfileId, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let dashboard = api.send(GetFoodDashboardRequest(profileId: profileId))
            async let saved = api.send(GetSavedFoodsRequest(profileId: profileId))
            self.dashboard = try await dashboard
            self.savedFoods = try await saved.foods
            errorMessage = nil
        } catch { errorMessage = "Couldn’t load your food log." }
    }

    func analyze(_ text: String) async {
        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            errorMessage = "Create a primary profile before logging food."
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }
        messages.append(FoodChatMessage(role: "user", content: trimmed))
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await api.send(AnalyzeFoodRequest(profileId: profileId, messages: messages))
            messages.append(FoodChatMessage(role: "assistant", content: result.message))
            proposal = result.food
            errorMessage = nil
        } catch { errorMessage = "Couldn’t analyze that meal. Try again." }
    }

    func prepare(_ food: FoodNutrition) { proposal = food; errorMessage = nil }

    func discardProposal() { proposal = nil; errorMessage = nil }

    func confirm() async -> Bool {
        guard let profileId = PrimaryProfileStore.primaryProfileId, let proposal, !isLoading else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await api.send(ConfirmFoodRequest(profileId: profileId, food: proposal))
            self.proposal = nil
            dashboard = try await api.send(GetFoodDashboardRequest(profileId: profileId))
            savedFoods = try await api.send(GetSavedFoodsRequest(profileId: profileId)).foods
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Couldn’t save this food."
            return false
        }
    }

    func startAISession() { messages = []; proposal = nil; errorMessage = nil }
}

struct FoodView: View {
    @StateObject private var store = FoodStore()
    @State private var input = ""
    @State private var isAISheetPresented = false
    @FocusState private var inputFocused: Bool

    private var suggestions: [FoodNutrition] { FoodSearch.matches(input, in: store.savedFoods, limit: 5) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: FormaSpacing.sectionGap) {
                nutritionOverview
                foodComposer
                if let proposal = store.proposal { confirmationCard(proposal) }
                if !store.savedFoods.isEmpty && input.isEmpty { recentFoodsCard }
                if let error = store.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(FormaTypography.body).foregroundStyle(Color.formaNegative)
                }
            }
            .frame(maxWidth: 760).frame(maxWidth: .infinity)
            .padding(.horizontal, FormaSpacing.screenGutter).padding(.bottom, FormaSpacing.xxl)
        }
        .contentMargins(.top, FormaLayout.topOverlayClearance, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { inputFocused = false }
        .background(FormaBackground())
        .task { await store.load() }
        .refreshable { await store.load() }
        .fullScreenCover(isPresented: $isAISheetPresented) {
            FoodAIChatView(store: store)
        }
    }

    private var nutritionOverview: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.lg) {
            FormaCardHeader("Today", subtitle: "Nutrition against your daily targets")
            let totals = dailyTotals
            let goals = store.dashboard?.goals
            HStack(spacing: FormaSpacing.sm) {
                nutrientGauge("Calories", value: totals.calories, goal: goals?.calories ?? 0, unit: "kcal")
                nutrientGauge("Protein", value: totals.protein, goal: goals?.proteinG ?? 0, unit: "g")
                nutrientGauge("Carbs", value: totals.carbs, goal: goals?.carbsG ?? 0, unit: "g")
                nutrientGauge("Fat", value: totals.fat, goal: goals?.fatG ?? 0, unit: "g")
            }
            if let trends = store.dashboard?.trends, !trends.isEmpty {
                FormaDivider()
                Text("14-day intake").font(FormaTypography.action)
                Chart(trends) { trend in
                    LineMark(x: .value("Date", trend.dateValue), y: .value("Calories", trend.calories))
                        .interpolationMethod(.catmullRom).foregroundStyle(Color.sleekAccent)
                    AreaMark(x: .value("Date", trend.dateValue), y: .value("Calories", trend.calories))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(colors: [Color.sleekAccent.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                }
                .chartLegend(.hidden).chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 170).transaction { $0.animation = nil }
            }
            if let entries = store.dashboard?.entries, !entries.isEmpty {
                FormaDivider()
                ForEach(entries.prefix(4)) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.name).font(FormaTypography.action)
                            Text("\(entry.servings, specifier: "%.2g") × \(entry.servingDescription) · \(entry.meal.title)")
                                .font(FormaTypography.supporting).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(entry.calories, specifier: "%.0f") kcal").font(FormaTypography.supporting).monospacedDigit().foregroundStyle(.secondary)
                    }
                }
            }
        }.formaSurface(.card)
    }

    private var foodComposer: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.md) {
            FormaCardHeader("Add food", subtitle: "Search your saved food library")
            HStack(spacing: FormaSpacing.sm) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Food, brand, or meal…", text: $input, axis: .vertical)
                    .textFieldStyle(.plain).focused($inputFocused).submitLabel(.done)
                    .onSubmit { if let first = suggestions.first { select(first) } }
                if !input.isEmpty {
                    Button { input = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).foregroundStyle(.secondary)
                }
            }
            .padding(12).background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: FormaRadius.inset))
            if !input.isEmpty && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions) { food in
                        Button { select(food) } label: { foodRow(food) }.buttonStyle(.plain)
                        if food.id != suggestions.last?.id { FormaDivider() }
                    }
                }
                .padding(.horizontal, FormaSpacing.sm)
                .background(Color.appElevatedBackground, in: RoundedRectangle(cornerRadius: FormaRadius.inset))
            } else if !input.isEmpty {
                Text("No saved food matches this search.")
                    .font(FormaTypography.supporting).foregroundStyle(.secondary)
            }
            Button {
                store.startAISession()
                isAISheetPresented = true
            } label: {
                Label("Add new food with AI", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.sleekAccent)
        }.formaSurface(.card)
    }

    private func confirmationCard(_ food: FoodNutrition) -> some View {
        VStack(alignment: .leading, spacing: FormaSpacing.md) {
            FormaCardHeader(food.name, subtitle: "Review before adding") {
                Button {
                    store.discardProposal()
                } label: {
                    Image(systemName: "xmark")
                        .font(FormaTypography.system(size: 13, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.appTertiaryBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Discard pending food")
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Database portion").font(FormaTypography.supporting).foregroundStyle(.secondary)
                    Text(food.servingDescription).font(FormaTypography.action)
                }
                Spacer()
                Stepper(value: proposalServings, in: 0.25...20, step: 0.25) {
                    Text("\(food.servings, specifier: "%.2g")×").font(FormaTypography.action).monospacedDigit()
                }.fixedSize()
            }
            Picker("Meal", selection: proposalMeal) {
                ForEach(FoodMeal.allCases) { meal in Text(meal.title).tag(meal) }
            }.pickerStyle(.segmented)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: FormaSpacing.sm) {
                macroTile("Calories", food.calories * food.servings, "kcal")
                macroTile("Protein", food.proteinG * food.servings, "g")
                macroTile("Carbohydrate", food.carbsG * food.servings, "g")
                macroTile("Total fat", food.fatG * food.servings, "g")
            }
            DisclosureGroup("Full nutrition") {
                VStack(spacing: FormaSpacing.sm) {
                    nutritionLine("Fiber", food.fiberG * food.servings, "g")
                    nutritionLine("Sugar", food.sugarG * food.servings, "g")
                    nutritionLine("Added sugar", food.addedSugarG * food.servings, "g")
                    nutritionLine("Saturated fat", food.saturatedFatG * food.servings, "g")
                    nutritionLine("Trans fat", food.transFatG * food.servings, "g")
                    nutritionLine("Monounsaturated fat", food.monounsaturatedFatG * food.servings, "g")
                    nutritionLine("Polyunsaturated fat", food.polyunsaturatedFatG * food.servings, "g")
                    nutritionLine("Sodium", food.sodiumMg * food.servings, "mg")
                    nutritionLine("Cholesterol", food.cholesterolMg * food.servings, "mg")
                }.padding(.top, FormaSpacing.sm)
            }.font(FormaTypography.action)
            HStack(spacing: FormaSpacing.sm) {
                Button("Cancel") { store.discardProposal() }
                    .buttonStyle(.bordered).tint(.secondary)
                Button("Add to \(food.meal.title)") { Task { _ = await store.confirm() } }
                    .buttonStyle(.borderedProminent).tint(.actionInk).frame(maxWidth: .infinity)
            }
        }.formaSurface(.hero)
    }

    private var recentFoodsCard: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.sm) {
            FormaCardHeader("Recent foods", subtitle: "Uses the saved portion and skips AI")
            ForEach(Array(store.savedFoods.prefix(8))) { food in
                Button { select(food) } label: { foodRow(food) }.buttonStyle(.plain)
                if food.id != store.savedFoods.prefix(8).last?.id { FormaDivider() }
            }
        }.formaSurface(.card)
    }

    private func foodRow(_ food: FoodNutrition) -> some View {
        HStack(spacing: FormaSpacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text(food.name).font(FormaTypography.action).foregroundStyle(.primary)
                Text(food.servingDescription).font(FormaTypography.supporting).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(food.calories, specifier: "%.0f") kcal").font(FormaTypography.supporting).monospacedDigit().foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(FormaTypography.micro).foregroundStyle(.tertiary)
        }.padding(.vertical, FormaSpacing.sm)
    }

    private func nutrientGauge(_ title: String, value: Double, goal: Double, unit: String) -> some View {
        let progress = goal > 0 ? min(value / goal, 1) : 0
        return VStack(spacing: FormaSpacing.xs) {
            ZStack {
                Circle().stroke(Color.appTertiaryBackground, lineWidth: 7)
                Circle().trim(from: 0, to: progress).stroke(Color.sleekAccent, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%").font(FormaTypography.micro).monospacedDigit()
            }.frame(width: 58, height: 58)
            Text(title).font(FormaTypography.micro).foregroundStyle(.secondary)
            Text("\(value, specifier: "%.0f") \(unit)").font(FormaTypography.supporting).monospacedDigit()
        }.frame(maxWidth: .infinity)
    }

    private func macroTile(_ title: String, _ value: Double, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(FormaTypography.supporting).foregroundStyle(.secondary)
            Text("\(value, specifier: "%.0f") \(unit)").font(FormaTypography.metricSmall).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading).padding(FormaSpacing.md)
            .background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: FormaRadius.inset))
    }

    private func nutritionLine(_ title: String, _ value: Double, _ unit: String) -> some View {
        HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text("\(value, specifier: "%.1f") \(unit)").monospacedDigit() }.font(FormaTypography.supporting)
    }

    private var dailyTotals: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        store.dashboard?.entries.reduce(into: (0, 0, 0, 0)) {
            $0.0 += $1.calories; $0.1 += $1.proteinG; $0.2 += $1.carbsG; $0.3 += $1.fatG
        } ?? (0, 0, 0, 0)
    }

    private func select(_ food: FoodNutrition) { input = ""; inputFocused = false; store.prepare(food) }
    private var proposalServings: Binding<Double> { Binding(get: { store.proposal?.servings ?? 1 }, set: { store.proposal?.servings = $0 }) }
    private var proposalMeal: Binding<FoodMeal> { Binding(get: { store.proposal?.meal ?? .snack }, set: { store.proposal?.meal = $0 }) }
}

private struct FoodAIChatView: View {
    @ObservedObject var store: FoodStore
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: FormaSpacing.md) {
                        Text("Describe the food, amount, brand, and preparation. I’ll ask one question only if it materially changes the estimate.")
                            .font(FormaTypography.body).foregroundStyle(.secondary)

                        ForEach(store.messages) { message in
                            Text(message.content)
                                .font(FormaTypography.body).padding(12)
                                .background(message.role == "user" ? Color.appInverseSurface : Color.appTertiaryBackground,
                                            in: RoundedRectangle(cornerRadius: FormaRadius.inset))
                                .foregroundStyle(message.role == "user" ? Color.appBackground : Color.primary)
                                .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
                                .id(message.id)
                        }

                        if store.isLoading {
                            FoodThinkingIndicator(label: store.proposal == nil ? "Thinking" : "Saving food")
                                .id("thinking")
                        }

                        if let food = store.proposal { proposal(food) }
                        if let error = store.errorMessage {
                            Label(error, systemImage: "exclamationmark.circle.fill")
                                .font(FormaTypography.supporting).foregroundStyle(Color.formaNegative)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(FormaSpacing.screenGutter)
                }
                .onChange(of: store.messages.count) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                .onChange(of: store.isLoading) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { inputFocused = false }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: FormaSpacing.sm) {
                    TextField("e.g. two fried eggs in butter", text: $input, axis: .vertical)
                        .textFieldStyle(.plain).focused($inputFocused).submitLabel(.send).onSubmit(send)
                    Button(action: send) { Image(systemName: "arrow.up").frame(width: 38, height: 38) }
                        .buttonStyle(.borderedProminent).tint(.actionInk)
                        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoading)
                }
                .padding(FormaSpacing.md)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Add new food with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { inputFocused = false }
                }
            }
            .background(FormaBackground())
        }
    }

    private func proposal(_ food: FoodNutrition) -> some View {
        VStack(alignment: .leading, spacing: FormaSpacing.md) {
            FormaCardHeader(food.name, subtitle: food.servingDescription)
            Stepper(value: servings, in: 0.25...20, step: 0.25) {
                Text("Portions: \(food.servings, specifier: "%.2g")").font(FormaTypography.action)
            }
            Picker("Meal", selection: meal) {
                ForEach(FoodMeal.allCases) { meal in Text(meal.title).tag(meal) }
            }.pickerStyle(.segmented)
            HStack {
                value("Calories", food.calories * food.servings, "kcal")
                value("Protein", food.proteinG * food.servings, "g")
                value("Carbs", food.carbsG * food.servings, "g")
                value("Fat", food.fatG * food.servings, "g")
            }
            HStack(spacing: FormaSpacing.sm) {
                Button("Change details") {
                    store.discardProposal()
                    inputFocused = true
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button("Accept and add") {
                    Task { if await store.confirm() { dismiss() } }
                }
                .buttonStyle(.borderedProminent)
                .tint(.actionInk)
                .frame(maxWidth: .infinity)
                .disabled(store.isLoading)
            }
        }.formaSurface(.hero)
    }

    private func value(_ title: String, _ amount: Double, _ unit: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(FormaTypography.micro).foregroundStyle(.secondary)
            Text("\(amount, specifier: "%.0f") \(unit)").font(FormaTypography.supporting).monospacedDigit()
        }.frame(maxWidth: .infinity)
    }

    private func send() {
        let text = input
        input = ""
        inputFocused = false
        Task { await store.analyze(text) }
    }

    private var servings: Binding<Double> {
        Binding(get: { store.proposal?.servings ?? 1 }, set: { store.proposal?.servings = $0 })
    }

    private var meal: Binding<FoodMeal> {
        Binding(get: { store.proposal?.meal ?? .snack }, set: { store.proposal?.meal = $0 })
    }
}

private struct FoodThinkingIndicator: View {
    let label: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: FormaSpacing.sm) {
            Text(label).font(FormaTypography.supporting).foregroundStyle(.secondary)
            if reduceMotion {
                ProgressView().controlSize(.small).tint(.sleekAccent)
            } else {
                TimelineView(.animation(minimumInterval: 0.22)) { timeline in
                    let phase = Int(timeline.date.timeIntervalSinceReferenceDate / 0.22) % 3
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.sleekAccent)
                                .frame(width: 6, height: 6)
                                .scaleEffect(index == phase ? 1 : 0.58)
                                .opacity(index == phase ? 1 : 0.42)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, FormaSpacing.md)
        .padding(.vertical, FormaSpacing.sm)
        .background(Color.appTertiaryBackground, in: Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
