import SwiftUI

/// Modal editor that lets the user modify a pending approval's tool arguments
/// before allowing. When the user taps "Allow with edit" the modified input
/// flows up to ApprovalStore and is sent to the CLI as `modifiedInput`,
/// which the hook handler converts to Claude Code's `updatedInput` response
/// so the tool runs with the edited args instead of the original.
///
/// The editor has two modes:
///   - Field mode: known keys (command, file_path, content, pattern, ...)
///     get dedicated labeled TextEditor fields for friendly editing.
///   - Raw JSON mode: the whole toolInput as one JSON blob for edge cases
///     (unknown tools, array fields, deeply nested objects).
struct ArgEditorSheet: View {
    let request: ApprovalRequest
    let onAllowEdited: ([String: Any]) -> Void

    @Environment(\.dismiss) private var dismiss

    /// Each known string-ish field gets its own editable @State keyed by
    /// field name. We initialize from request.toolInput when the sheet opens.
    @State private var fieldValues: [String: String] = [:]
    @State private var rawJSON: String = ""
    @State private var showRaw = false
    @State private var parseError: String?

    /// The keys we recognize and render in "field mode", in display order.
    /// Anything else (nested objects, arrays) forces the user into raw mode.
    private static let knownStringKeys: [String] = [
        "command",
        "file_path",
        "path",
        "pattern",
        "old_string",
        "new_string",
        "content",
        "description",
        "url",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(request.toolName)
                        .font(.headline)
                    if let ctx = request.contextSummary, !ctx.isEmpty {
                        Text(ctx)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(String(localized: "工具"))
                }

                if showRaw || !allFieldsAreKnown {
                    rawJSONSection
                } else {
                    fieldSection
                    toggleSection
                }

                if let err = parseError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(String(localized: "编辑参数"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "取消")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "允许（已编辑）")) {
                        commit()
                    }
                    .fontWeight(.semibold)
                    .disabled(parseError != nil)
                }
            }
            .onAppear { hydrate() }
        }
    }

    // MARK: - Field mode

    private var fieldSection: some View {
        Section {
            ForEach(orderedKnownKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 4) {
                    Text(key)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    TextEditor(text: Binding(
                        get: { fieldValues[key] ?? "" },
                        set: { fieldValues[key] = $0; parseError = nil }
                    ))
                    .font(.body.monospaced())
                    .frame(minHeight: 60, maxHeight: 200)
                    .scrollContentBackground(.hidden)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text(String(localized: "参数"))
        } footer: {
            Text(String(localized: "修改参数后点\"允许（已编辑）\"按钮，Claude 会用你编辑后的参数执行工具。"))
                .font(.caption2)
        }
    }

    private var toggleSection: some View {
        Section {
            Button {
                // Switching into raw mode: serialize current field state as JSON.
                rawJSON = serializeCurrent()
                showRaw = true
            } label: {
                Label(String(localized: "切换到 JSON 模式"), systemImage: "curlybraces")
            }
        }
    }

    // MARK: - Raw JSON mode

    private var rawJSONSection: some View {
        Section {
            TextEditor(text: $rawJSON)
                .font(.footnote.monospaced())
                .frame(minHeight: 200, maxHeight: 400)
                .scrollContentBackground(.hidden)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
                .onChange(of: rawJSON) { _, _ in
                    // Validate as the user types so the button state is honest.
                    parseError = validateJSON(rawJSON) == nil
                        ? String(localized: "JSON 格式错误")
                        : nil
                }
            if allFieldsAreKnown {
                Button {
                    // Switching back to field mode: parse current JSON into fields.
                    if let dict = validateJSON(rawJSON) {
                        hydrate(from: dict)
                        showRaw = false
                    }
                } label: {
                    Label(String(localized: "回到字段模式"), systemImage: "list.bullet.rectangle")
                }
            }
        } header: {
            Text(String(localized: "原始 JSON"))
        } footer: {
            Text(String(localized: "直接编辑 JSON。适合嵌套结构或数组参数。"))
                .font(.caption2)
        }
    }

    // MARK: - State derivation

    /// Ordered list of keys we'll show as dedicated fields. Starts with the
    /// known-keys order, then appends any remaining string keys from the input
    /// so we don't silently lose information.
    private var orderedKnownKeys: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for k in Self.knownStringKeys where request.toolInput[k] != nil && !seen.contains(k) {
            result.append(k)
            seen.insert(k)
        }
        // Append remaining string-valued keys in sorted order.
        for (k, v) in request.toolInput.sorted(by: { $0.key < $1.key }) {
            if seen.contains(k) { continue }
            if v.value is String { result.append(k); seen.insert(k) }
        }
        return result
    }

    /// Whether the toolInput is entirely string-valued. If it has nested
    /// dicts / arrays we refuse field mode and force raw JSON, since the
    /// field editor can't represent them.
    private var allFieldsAreKnown: Bool {
        for (_, v) in request.toolInput {
            if !(v.value is String) && !(v.value is Int) && !(v.value is Double) && !(v.value is Bool) {
                return false
            }
        }
        return true
    }

    // MARK: - Serialization

    private func hydrate() {
        var values: [String: String] = [:]
        for (k, v) in request.toolInput {
            switch v.value {
            case let s as String: values[k] = s
            case let i as Int: values[k] = String(i)
            case let d as Double: values[k] = String(d)
            case let b as Bool: values[k] = String(b)
            default: break
            }
        }
        fieldValues = values

        // Seed the raw JSON view too so switching between modes is lossless.
        rawJSON = request.toolInput.prettyJSONString
    }

    private func hydrate(from dict: [String: Any]) {
        var values: [String: String] = [:]
        for (k, v) in dict {
            switch v {
            case let s as String: values[k] = s
            case let i as Int: values[k] = String(i)
            case let d as Double: values[k] = String(d)
            case let b as Bool: values[k] = String(b)
            default: break
            }
        }
        fieldValues = values
    }

    /// Build the wire JSON dict from the current editor state.
    /// - Raw mode: parses the user's JSON text.
    /// - Field mode: walks fieldValues, preserving the original type for
    ///   numeric/bool fields when possible (so e.g. an Int field stays Int).
    private func buildFinalInput() -> [String: Any]? {
        if showRaw {
            return validateJSON(rawJSON)
        }
        var result: [String: Any] = [:]
        for (k, raw) in fieldValues {
            // If the original field was non-string, try to preserve its type.
            if let orig = request.toolInput[k]?.value {
                switch orig {
                case is Int:
                    if let i = Int(raw) { result[k] = i } else { result[k] = raw }
                case is Double:
                    if let d = Double(raw) { result[k] = d } else { result[k] = raw }
                case is Bool:
                    if let b = Bool(raw) { result[k] = b } else { result[k] = raw }
                default:
                    result[k] = raw
                }
            } else {
                // New field the user added — keep as string.
                result[k] = raw
            }
        }
        return result
    }

    private func validateJSON(_ text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj
    }

    private func serializeCurrent() -> String {
        guard let input = buildFinalInput() else { return "{}" }
        guard let data = try? JSONSerialization.data(
            withJSONObject: input,
            options: [.prettyPrinted, .sortedKeys]
        ),
        let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    // MARK: - Commit

    private func commit() {
        guard let final = buildFinalInput() else {
            parseError = String(localized: "JSON 格式错误")
            return
        }
        dismiss()
        onAllowEdited(final)
    }
}

// MARK: - Helper on AnyCodable dict

private extension Dictionary where Key == String, Value == AnyCodable {
    var prettyJSONString: String {
        let plain = self.mapValues(\.value)
        guard let data = try? JSONSerialization.data(
            withJSONObject: plain,
            options: [.prettyPrinted, .sortedKeys]
        ),
        let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
