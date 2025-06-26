# SnifLeaf – macOS Network Proxy & HTTP Inspector

**SnifLeaf** is a lightweight, native macOS app built with SwiftUI that captures and analyzes HTTP/HTTPS traffic in real time, powered by [mitmproxy](https://mitmproxy.org/). It's ideal for developers, testers, and network debuggers who want a fast, focused alternative to tools like Charles Proxy.

![Stars](https://img.shields.io/github/stars/hgq287/SnifLeaf?style=social)
![Forks](https://img.shields.io/github/forks/hgq287/SnifLeaf?style=social)
![Last Commit](https://img.shields.io/github/last-commit/hgq287/SnifLeaf)

---

## Features

- Log all HTTP/S traffic (incoming + outgoing)
- Inspect headers, status codes, and bodies
- Filter logs by host, method, status, etc.
- Click to view full request/response details
- macOS-native SwiftUI interface

---

## Screenshots

### 🟢 Real-Time Proxy Control  
![Proxy Control](assets/proxy-control.jpg)

### 🔍 Log Detail View  
![Log Details](assets/log-details.jpg)

### 📈 Live Traffic Viewer  
![Live Logs](assets/live-logs.jpg)

---

## Coming Soon

- Export logs to JSON, HAR, and more
- Generate QA tester reports
- Detect anomalies using ML
- Battery usage analysis
- Dev/test utility toolkit

---

## Use Cases

| Who?         | Why?                                               |
|--------------|----------------------------------------------------|
| Developers   | Debug REST APIs, inspect network calls             |
| QA Testers   | Verify API usage, generate reports                 |
| Security     | Detect anomalies in traffic                        |
| DevOps       | Lightweight alternative to Wireshark on macOS     |

---

## Quick Start

```bash
git clone https://github.com/hgq287/SnifLeaf.git
open SnifLeaf.xcodeproj
```

- Requires: macOS 15+, Xcode 16+

> `mitmdump` is already bundled and invoked via CLI by the app. No manual installation is needed.

---

## Setup Instructions

1. **Configure System Proxy**

   - System Settings → Network → Your Wi-Fi → Proxy → Enable Web Proxy (127.0.0.1:8080)

2. **Install SSL Certificate**

   - With the proxy running, visit http://mitm.it in your browser
   - Download the certificate and trust it via Keychain Access (macOS only)

> These steps are mandatory for HTTPS traffic interception due to macOS security restrictions.

---

## Contributing

Your contributions are welcome 🙌  
Feel free to:
- Submit issues and feature requests
- Create pull requests
- Improve docs and automation

---

## License

MIT License — see [LICENSE](LICENSE) for full details.

© 2025 [Hg Q.](https://hgq287.github.io)
