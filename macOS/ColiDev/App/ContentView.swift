import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var selection: AppSection? = .today

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Label { Text(L10n.text("nav.today", store.language)) } icon: { Image(systemName: "sparkles") }
                        .tag(AppSection.today)
                    Label { Text(L10n.text("nav.subjects", store.language)) } icon: { Image(systemName: "square.grid.2x2") }
                        .tag(AppSection.subjects)
                } header: {
                    Text(L10n.text("nav.yourLearning", store.language))
                }

                Section {
                    ForEach(Subject.allCases) { subject in
                        Label { Text(subject.title(in: store.language)) } icon: { Image(systemName: subject.symbol) }
                            .tag(AppSection.subject(subject))
                    }
                } header: {
                    Text(L10n.text("nav.subjects", store.language))
                }

                Section {
                    Label { Text(L10n.text("nav.settings", store.language)) } icon: { Image(systemName: "gearshape") }
                        .tag(AppSection.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ColiDev")
        } detail: {
            Group {
                switch selection ?? .today {
                case .today:
                    TodayView(open: open)
                case .subjects:
                    SubjectCatalogView(open: open)
                case .subject(let subject):
                    LessonSessionView(subject: subject)
                case .settings:
                    SettingsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker(selection: $store.language, label: Text(L10n.text("settings.language", store.language))) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.shortLabel).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 112)
                    .accessibilityLabel(Text(L10n.text("settings.language", store.language)))
                }
            }
        }
    }

    private func open(_ subject: Subject) {
        selection = .subject(subject)
    }
}

private struct TodayView: View {
    @EnvironmentObject private var store: LearningStore
    let open: (Subject) -> Void

    private let columns = [GridItem(.adaptive(minimum: 210), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.text("home.eyebrow", store.language))
                        .font(.caption.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                    Text(L10n.text("home.title", store.language))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.text("home.subtitle", store.language))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 28)

                progressCard

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("home.catalog", store.language))
                            .font(.title2.weight(.semibold))
                        Text(L10n.text("home.catalogHint", store.language))
                            .foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                        ForEach(Subject.allCases) { subject in
                            SubjectCard(subject: subject, complete: store.isComplete(subject)) {
                                open(subject)
                            }
                        }
                    }
                }

                Label { Text(L10n.text("home.offline", store.language)) } icon: { Image(systemName: "wifi.slash") }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var progressCard: some View {
        HStack(spacing: 22) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(store.completedSubjectCount) / CGFloat(Subject.allCases.count))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(store.completedSubjectCount)/6")
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("home.progress", store.language))
                    .font(.caption.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text("\(store.completedSubjectCount) \(L10n.text("home.completed", store.language))")
                    .font(.headline)
                Text(L10n.text("home.subjectCount", store.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button {
                let next = Subject.allCases.first(where: { !store.isComplete($0) }) ?? .mathematics
                open(next)
            } label: {
                Label { Text(L10n.text("home.continue", store.language)) } icon: { Image(systemName: "arrow.right") }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct SubjectCatalogView: View {
    @EnvironmentObject private var store: LearningStore
    let open: (Subject) -> Void
    private let columns = [GridItem(.adaptive(minimum: 210), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(Subject.allCases) { subject in
                    SubjectCard(subject: subject, complete: store.isComplete(subject)) { open(subject) }
                }
            }
            .padding(28)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(Text(L10n.text("nav.subjects", store.language)))
    }
}

private struct SubjectCard: View {
    @EnvironmentObject private var store: LearningStore
    let subject: Subject
    let complete: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: subject.symbol)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(subject.tint)
                        .frame(width: 44, height: 44)
                        .background(subject.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                    Spacer()
                    if complete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title(in: store.language))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subject.subtitle(in: store.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Text(complete ? L10n.text("home.done", store.language) : L10n.text("home.foundation", store.language))
                    Image(systemName: "arrow.right")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(subject.tint)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.quaternary, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        Form {
            Section {
                Picker(selection: $store.language, label: Text(L10n.text("settings.languages", store.language))) {
                    Text("Русский").tag(AppLanguage.ru)
                    Text("English").tag(AppLanguage.en)
                }
                .pickerStyle(.segmented)
            }
            Section {
                Label { Text(L10n.text("settings.localBody", store.language)) } icon: { Image(systemName: "internaldrive") }
                    .foregroundStyle(.secondary)
            } header: {
                Text(L10n.text("settings.local", store.language))
            }
            Section {
                LabeledContent { Text(L10n.text("settings.preview", store.language)) } label: { Text(L10n.text("settings.version", store.language)) }
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(Text(L10n.text("settings.title", store.language)))
    }
}
