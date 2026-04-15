import SwiftUI

struct DeploymentRow: View {
    let deployment: Deployment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StatusDot(status: deployment.status)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(deployment.projectName)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)

                    if let provider = ServiceRegistry.shared.provider(withID: deployment.providerID) {
                        Image(systemName: provider.iconSymbol)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Text(deployment.relativeTime)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }

                HStack(spacing: 6) {
                    Text(deployment.status.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor(deployment.status))

                    if let branch = deployment.branch {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(branch)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                if let commit = deployment.commitMessage, !commit.isEmpty {
                    Text(commit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func statusColor(_ status: Deployment.Status) -> Color {
        switch status {
        case .success:   return .green
        case .failed:    return .red
        case .building:  return .orange
        case .queued:    return .gray
        case .cancelled: return .gray
        case .reviewing: return .blue
        case .unknown:   return .gray
        }
    }
}

struct StatusDot: View {
    let status: Deployment.Status

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
            )
    }

    private var color: Color {
        switch status {
        case .success:   return .green
        case .failed:    return .red
        case .building:  return .orange
        case .queued:    return .gray
        case .cancelled: return .gray
        case .reviewing: return .blue
        case .unknown:   return .gray
        }
    }
}
