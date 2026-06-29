import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var vm: OilPriceViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section("自动刷新") {
                Picker("刷新频率", selection: $vm.refreshIntervalMinutes) {
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                    Text("60 分钟").tag(60)
                }
                .onChange(of: vm.refreshIntervalMinutes) { _, _ in
                    vm.updateTimerInterval()
                }
            }

            Section("启动") {
                Toggle("开机自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
            }

            Section("关于") {
                LabeledContent("版本", value: "1.0.0 (MVP)")
                LabeledContent("数据来源", value: "Yahoo Finance（延迟行情）")

                VStack(alignment: .leading, spacing: 4) {
                    Text("免责声明")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("本应用所展示的油价数据仅供个人参考，存在延迟，不构成任何投资或交易建议。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section {
                Button("退出 OilPulse") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 400)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }
        .onAppear { launchAtLogin = getLaunchAtLoginStatus() }
    }

    private func getLaunchAtLoginStatus() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[Settings] Launch at login error: \(error)")
            }
        }
    }
}
