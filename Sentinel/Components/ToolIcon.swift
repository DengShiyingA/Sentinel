import SwiftUI

struct ToolIcon: View {
    let toolName: String
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.5))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(iconColor, in: RoundedRectangle(cornerRadius: size * 0.22))
    }

    private var symbolName: String {
        let name = toolName.lowercased()
        if name.contains("write") || name.contains("edit") {
            return "doc.badge.plus"
        } else if name.contains("bash") || name.contains("terminal") || name.contains("exec") {
            return "terminal"
        } else if name.contains("read") || name.contains("cat") {
            return "doc.text"
        } else if name.contains("glob") || name.contains("find") || name.contains("grep") || name.contains("search") {
            return "magnifyingglass"
        } else if name.contains("delete") || name.contains("rm") {
            return "trash"
        } else if name.contains("git") {
            return "arrow.triangle.branch"
        } else {
            return "gearshape"
        }
    }

    private var iconColor: Color {
        let name = toolName.lowercased()
        if name.contains("delete") || name.contains("rm") {
            return .red
        } else if name.contains("bash") || name.contains("terminal") || name.contains("exec") {
            return .orange
        } else if name.contains("write") || name.contains("edit") {
            return .blue
        } else if name.contains("read") || name.contains("cat") {
            return .green
        } else {
            return .secondary
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ToolIcon(toolName: "Write")
        ToolIcon(toolName: "Bash")
        ToolIcon(toolName: "Read")
        ToolIcon(toolName: "Grep")
        ToolIcon(toolName: "Delete")
        ToolIcon(toolName: "Unknown")
    }
}
