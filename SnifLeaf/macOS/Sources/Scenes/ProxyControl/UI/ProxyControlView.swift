//
//  ProxyControlView.swift
//  SnifLeaf-macOS
//
//  Created by Hg Q. on 12/6/25.
//


import SwiftUI
import Shared
import SnifLeafCore

struct ProxyControlView: View {
    @EnvironmentObject var mitmProcessManager: MitmProcessManager

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // MARK: - Proxy Status Card
                CardView {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "power")
                                .font(.title)
                                .foregroundColor(mitmProcessManager.isProxyRunning ? .green : .red)
                            Text("Proxy Status")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Circle()
                                .fill(mitmProcessManager.isProxyRunning ? .green : .red)
                                .frame(width: 20, height: 20)
                        }
                        
                        Text(mitmProcessManager.isProxyRunning ? "Active" : "Inactive")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(mitmProcessManager.isProxyRunning ? .green : .red)
                        
                        Button {
                            if mitmProcessManager.isProxyRunning {
                                mitmProcessManager.stopExistingMitmdump {}
                            } else {
                                mitmProcessManager.startProxy()
                            }
                        } label: {
                            Label(mitmProcessManager.isProxyRunning ? "Stop Proxy" : "Start Proxy",
                                  systemImage: mitmProcessManager.isProxyRunning ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(mitmProcessManager.isProxyRunning ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }

                // MARK: - mitmproxy Console Output Card
                CardView(title: "Console Output", icon: "terminal.fill") {
                    Text(mitmProcessManager.latestMitmLog)
                        .font(.caption2)
                        .monospaced()
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                }

                // MARK: - Setup Instructions Card
                CardView(title: "Setup Instructions", icon: "text.book.closed.fill") {
                    VStack(alignment: .leading, spacing: 15) {
                        SetupStepView(
                            stepNumber: 1,
                            title: "Install mitmproxy",
                            description: "Open Terminal and run: \n` /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"`\nThen: `brew install python mitmproxy`"
                        )
                        
                        SetupStepView(
                            stepNumber: 2,
                            title: "Configure System Proxy",
                            description: "Go to System Settings > Network > (Your Wi-Fi/Ethernet) > Details... > Proxies. Turn on 'Web Proxy (HTTP)' and 'Secure Web Proxy (HTTPS)'. Set Server: `127.0.0.1`, Port: `8080`. Click OK."
                        )
                        
                        SetupStepView(
                            stepNumber: 3,
                            title: "Install SSL Certificate",
                            description: "With proxy running, open your browser and navigate to `http://mitm.it`. Download and install the `mitmproxy-ca-cert.pem` certificate. For macOS, add it to Keychain Access and **trust it**."
                        )

                        Text("Important: These steps are mandatory for interception. SnifLeaf cannot automate them due to system security restrictions.")
                            .font(.callout)
                            .foregroundColor(.orange)
                            .padding(.vertical, 5)
                            .padding(.horizontal)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Proxy Control")
    }
}

// MARK: - Preview
struct ProxyControlView_Previews: PreviewProvider {
    static var previews: some View {
        ProxyControlView()
            .environmentObject(MitmProcessManager.shared)
            .previewDisplayName("Proxy Control View")
    }
}
