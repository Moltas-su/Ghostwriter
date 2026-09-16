import SwiftUI
import AppKit

public struct OnboardingView: View {
    @State private var currentStep = 0
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "text.cursor")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(.accentColor)
                .padding(.top, 40)
                .padding(.bottom, 20)
            
            VStack {
                switch currentStep {
                case 0:
                    WelcomeStep(currentStep: $currentStep)
                case 1:
                    ShortcutsStep(currentStep: $currentStep)
                case 2:
                    LocalModelStep(currentStep: $currentStep)
                case 3:
                    FinishedStep()
                default:
                    EmptyView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut, value: currentStep)
            
            Spacer()
        }
        .frame(width: 500, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct WelcomeStep: View {
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to GhostWriter")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("GhostWriter is a powerful, system-wide writing assistant that lives in your menu bar. Simply highlight text in any app, right-click, and choose 'Proofread & Fix' or 'Rewrite' to instantly improve your writing.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 20)
            
            Button("Get Started") {
                currentStep += 1
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

struct ShortcutsStep: View {
    @Binding var currentStep: Int
    @State private var installed = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Apple Intelligence")
                .font(.title)
                .fontWeight(.bold)
            
            Text("GhostWriter defaults to using Apple Intelligence for completely private, on-device text refinement. To enable this, GhostWriter needs to install two Shortcuts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 10)
            
            Button("Install Shortcuts") {
                let missing = ShortcutManager.shared.getMissingShortcuts()
                if !missing.isEmpty {
                    ShortcutManager.shared.installBundledShortcuts(missing: missing)
                }
                installed = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if installed {
                Text("Shortcuts installed! You may need to click 'Add Shortcut' in the Shortcuts app.")
                    .font(.caption)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer().frame(height: 10)
            
            Button(installed ? "Continue" : "Skip") {
                currentStep += 1
            }
            .buttonStyle(.link)
        }
    }
}

struct LocalModelStep: View {
    @Binding var currentStep: Int
    @AppStorage("ActiveBackend") private var activeBackendRaw: String = BackendType.appleShortcuts.rawValue
    @AppStorage("LocalModelSize") private var modelSizeRaw: String = LocalModelSize.oneB.rawValue
    @ObservedObject private var downloader = ModelDownloader.shared
    
    @State private var wantsLocal = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Local AI Model")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Alternatively, you can run a private Gemma 3 AI model directly on your Mac. Would you like to set this up now?")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            if !wantsLocal {
                HStack(spacing: 20) {
                    Button("Not Now") {
                        currentStep += 1
                    }
                    .controlSize(.large)
                    
                    Button("Setup Local Model") {
                        wantsLocal = true
                        activeBackendRaw = BackendType.localModel.rawValue
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                VStack(spacing: 12) {
                    Picker("", selection: $modelSizeRaw) {
                        Text("Gemma 3 1B (~750MB)").tag(LocalModelSize.oneB.rawValue)
                        Text("Gemma 3 4B (~2.5GB)").tag(LocalModelSize.fourB.rawValue)
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: modelSizeRaw) { _, newValue in
                        if let size = LocalModelSize(rawValue: newValue) {
                            ConfigManager.shared.selectedModelSize = size
                        }
                    }
                    
                    if let size = LocalModelSize(rawValue: modelSizeRaw), let warning = size.warningText {
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 40)
                    }
                    
                    if downloader.isDownloading {
                        VStack(spacing: 4) {
                            ProgressView(value: downloader.progress)
                                .progressViewStyle(.linear)
                            Text("\(Int(downloader.progress * 100))%")
                                .font(.caption)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        if ConfigManager.shared.isGemmaModelDownloaded {
                            Text("Model downloaded and ready!")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        } else {
                            Button("Download Model") {
                                if let size = LocalModelSize(rawValue: modelSizeRaw) {
                                    downloader.download(size: size) { _ in }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Spacer().frame(height: 10)
                    
                    Button("Continue") {
                        currentStep += 1
                    }
                    .buttonStyle(.link)
                    .disabled(downloader.isDownloading)
                }
            }
        }
    }
}

struct FinishedStep: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("GhostWriter is now running quietly in your menu bar. \n\nSelect any text, right-click, and let GhostWriter do its magic. You can click the menu bar icon at any time to open Settings or quit the app.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer().frame(height: 20)
            
            Button("Start Writing") {
                ConfigManager.shared.hasCompletedOnboarding = true
                OnboardingWindowManager.shared.closeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
