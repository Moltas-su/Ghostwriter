import SwiftUI
import AppKit

public struct SettingsView: View {
    @AppStorage("ActiveBackend") private var activeBackendRaw: String = BackendType.appleShortcuts.rawValue
    @AppStorage("LocalModelSize") private var modelSizeRaw: String = LocalModelSize.oneB.rawValue
    
    @ObservedObject private var downloader = ModelDownloader.shared
    
    @State private var isOneBDownloaded = false
    @State private var isFourBDownloaded = false
    
    private var activeBackend: BackendType {
        get { BackendType(rawValue: activeBackendRaw) ?? .appleShortcuts }
    }
    
    private var selectedModelSize: LocalModelSize {
        get { LocalModelSize(rawValue: modelSizeRaw) ?? .oneB }
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: "text.cursor")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GhostWriter")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Writing Tools Preferences")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            Form {
                // MARK: - Backend Selection
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Active Engine", selection: $activeBackendRaw) {
                            Text("Apple Intelligence (Shortcuts)").tag(BackendType.appleShortcuts.rawValue)
                            Text("Local AI Model").tag(BackendType.localModel.rawValue)
                        }
                        .pickerStyle(.radioGroup)
                        .onChange(of: activeBackendRaw) { _, newValue in
                            // Sync ConfigManager when the picker changes
                            if let backend = BackendType(rawValue: newValue) {
                                ConfigManager.shared.activeBackend = backend
                            }
                        }
                        
                        Text(activeBackend.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Local Model Settings (only shown when local backend is active)
                if activeBackend == .localModel {
                    Section("Model Selection") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Model", selection: $modelSizeRaw) {
                                ForEach(LocalModelSize.allCases) { size in
                                    VStack(alignment: .leading) {
                                        Text(size.displayName)
                                    }
                                    .tag(size.rawValue)
                                }
                            }
                            .pickerStyle(.radioGroup)
                            .onChange(of: modelSizeRaw) { _, newValue in
                                if let size = LocalModelSize(rawValue: newValue) {
                                    ConfigManager.shared.selectedModelSize = size
                                }
                                refreshModelStatus()
                            }
                            
                            Text(selectedModelSize.sizeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let warning = selectedModelSize.warningText {
                                Text(warning)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Section("Model Status") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Status indicator
                            HStack {
                                Text(selectedModelSize.displayName)
                                Spacer()
                                if isModelDownloaded(selectedModelSize) {
                                    Label("Ready", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Label("Not Installed", systemImage: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            // Download progress
                            if downloader.isDownloading {
                                VStack(alignment: .leading, spacing: 6) {
                                    ProgressView(value: downloader.progress)
                                        .progressViewStyle(.linear)
                                    
                                    HStack {
                                        Text(formatBytes(downloader.downloadedBytes))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if downloader.totalBytes > 0 {
                                            Text("of \(formatBytes(downloader.totalBytes))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("\(Int(downloader.progress * 100))%")
                                            .font(.caption)
                                            .monospacedDigit()
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button("Cancel") {
                                        downloader.cancel()
                                    }
                                    .controlSize(.small)
                                }
                            }
                            
                            // Error message
                            if let error = downloader.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            // Action buttons
                            if !downloader.isDownloading {
                                HStack {
                                    if !isModelDownloaded(selectedModelSize) {
                                        Button("Download Model") {
                                            downloader.download(size: selectedModelSize) { success in
                                                refreshModelStatus()
                                            }
                                        }
                                        .controlSize(.regular)
                                    }
                                    
                                    Spacer()
                                    
                                    if isModelDownloaded(selectedModelSize) {
                                        Button("Delete Model") {
                                            let _ = ConfigManager.shared.deleteModel(size: selectedModelSize)
                                            refreshModelStatus()
                                        }
                                        .controlSize(.small)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(20)
            .formStyle(.grouped)
        }
        .frame(width: 480, height: activeBackend == .localModel ? 520 : 300)
        .onAppear {
            refreshModelStatus()
        }
    }
    
    // MARK: - Helpers
    
    private func isModelDownloaded(_ size: LocalModelSize) -> Bool {
        switch size {
        case .oneB: return isOneBDownloaded
        case .fourB: return isFourBDownloaded
        }
    }
    
    private func refreshModelStatus() {
        isOneBDownloaded = ConfigManager.shared.isModelDownloaded(size: .oneB)
        isFourBDownloaded = ConfigManager.shared.isModelDownloaded(size: .fourB)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
