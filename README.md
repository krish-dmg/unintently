<div align="center">

  <img src="unintently_app/assets/branding/unintently_logo.png" alt="Unintently Logo" width="128" height="128" />

  <h1>Unintently (v2.0)</h1>

  <p><strong>Free, Open-Source AI-Powered Text-to-Handwriting & Assignment Generator</strong></p>

  <p>
    <a href="https://github.com/krish-dmg/unintently/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT License" /></a>
    <a href="https://github.com/krish-dmg/unintently/actions/workflows/ci.yml"><img src="https://img.shields.io/badge/Build-Passing-brightgreen.svg" alt="Build Status" /></a>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.47+-02569B.svg?logo=flutter" alt="Flutter" /></a>
    <a href="https://workers.cloudflare.com"><img src="https://img.shields.io/badge/Cloudflare_Workers_AI-Llama_3-F38020.svg?logo=cloudflare" alt="Cloudflare Workers" /></a>
    <a href="https://github.com/krish-dmg/unintently/stargazers"><img src="https://img.shields.io/github/stars/krish-dmg/unintently?style=social" alt="GitHub Stars" /></a>
  </p>

  <p>
    Turn any digital text, notes, lab practical reports, or AI answers into authentic, realistic handwriting rendered directly onto ruled notebook sheets, college loose-leafs, and assignment paper.
  </p>

</div>

---

## Origin & Philosophy: Why Unintently Exists

Unintently is an independent, completely free, and open-source recreation of the original Intently (I-N-T-E-N-T-L-Y) handwriting project.

The original application offered helpful handwriting capabilities, but gated critical features behind paywalls, subscription models, coins, and artificial usage restrictions. When attempts were made to contribute code, feature enhancements, and fixes directly to the original Intently project, the original project owner declined external contributions.

Rather than accepting paywalls and artificial restrictions for students needing to prepare assignments and lecture notes, Unintently was created. The application was reverse-engineered from the ground up, rebuilt with modern Flutter architecture, and liberated from:
- All paywalls, subscriptions, and artificial coin systems
- All intrusive advertisements and promotional banners
- All tracking, third-party analytics, and user surveillance
- All mandatory logins, emails, and cloud account barriers

Every feature in Unintently is fully unlocked, open-source, local-first, and free forever.

---

## Highlights & Features

- **100% Free & Open-Source:** No paywalls, subscriptions, coins, or feature gates. Everything is unlocked.
- **Privacy-First & Local-First:** No accounts, no email logins, and no tracking. All documents live safely on your device.
- **ChatGPT Companion Extension:** Convert any ChatGPT conversation into a handwritten assignment in seconds via QR scan or instant link.
- **12 Handcrafted Handwriting Fonts:** From natural student cursive to clean exam script and informal gel-pen notes.
- **Authentic Paper Backgrounds:** High-resolution ruled notebook pages, assignment registers, college ruled sheets, and blank A4 styles.
- **Built-in AI Assistant:** Powered by free, serverless **Cloudflare Workers AI** running open-weight Meta Llama 3 models.
- **Print-Ready PDF Generation:** Export standard A4 vector PDFs ready for printing or classroom submission.
- **Zero Notifications:** No push marketing, tracking daemons, or unsolicited alerts.

---

## ChatGPT Chrome Extension

The Unintently browser extension connects desktop AI workflows directly to your mobile handwritten notes.

### Capabilities
- **Dual-Layer Extraction Engine**: Directly queries the official ChatGPT Session API (`/backend-api/conversation/:id`) with automatic fallback to high-fidelity DOM parsing. Fully immune to DOM virtualization, dynamic layout changes, and missing turns.
- **Strict Q&A Separation**: User prompts are automatically organized as questions, and assistant replies are populated as answers, ready for ruled page rendering.
- **Instant QR Code & Deep Link**: Generates a high-contrast QR code and Cloudflare Worker sync link that opens straight into the Unintently editor on your phone.
- **On-Screen Preview**: Verify your extracted questions and answers in real-time before scanning.

### Extension Installation
1. Download `unintently-chatgpt-extension-v2.3.0.zip` from the [Releases](https://github.com/krish-dmg/unintently/releases) section and extract it (or use the `browser extention/1.2_0` directory from this repository).
2. Open your Chromium browser (Google Chrome, Brave, Edge, Arc) and go to `chrome://extensions`.
3. Enable **Developer mode** using the toggle in the upper right corner.
4. Click **Load unpacked** and select the unzipped `1.2_0` directory.

### How to Use the Extension
1. Open any dialogue on [ChatGPT](https://chatgpt.com).
2. Click the **Convert To Assignment** button in the composer bar.
3. Review your extracted questions and answers in the dialog preview.
4. In the Unintently mobile app, open the drawer menu, select **Scan ChatGPT Assignment QR**, and scan the QR code.
5. The assignment will load instantly with your selected handwriting font and ruled paper background, ready for preview and PDF export.

---

## Restored Typography Showcase

| Font Family | Style Name | Characteristics |
| :--- | :--- | :--- |
| `intentlyR1` | **Intently Signature** | Natural, flowing cursive student penmanship |
| `intentlyR2` | **Intently Fast Hand** | Quick, fluid lecture note-taking style |
| `intentlyR8` | **Intently Clean** | Neat, structured cursive lettering |
| `intentlyR11` | **Intently Exam Pen** | Tight, compact exam-room handwriting |
| `intentlyR12` | **Intently Journal** | Relaxed ballpoint diary script |
| `Writing1` | **Classic Script 1** | Standard blue ruled notebook script |
| `Writing2` | **Classic Script 2** | Smooth, flowing ink lines |
| `Writing3` | **Classic Script 3** | Calligraphic flourished penmanship |
| `Writing4` | **Gel Pen Quick** | Everyday ballpoint pen handwriting |
| `Writing5` | **Casual Student** | Informal classroom scribble notes |
| `Writing7` | **Practical Lab File** | Sharp technical lab record script |
| `Writing8` | **Homework Pen** | High-school assignment cursive hand |

---

## Paper Templates

- **Classic Ruled** (`ruled.jpg`): Standard blue notebook lines with margin.
- **College Ruled 1 & 2** (`ruled1.jpg`, `ruled2.jpg`): Narrow spacing with authentic micro-grain paper textures.
- **Wide Ruled 3** (`ruled3.jpg`): Wide-spaced lines for structured readability.
- **Notebook Margin 4** (`ruled4.jpg`): Red vertical rule margin register sheet.
- **Heavy Paper 5** (`ruled5.jpg`): Parchment-toned register page.
- **Assignment Sheet** (`ruledAssignment.jpeg`): Formal assignment header sheet.
- **Blank White A4 & Natural Ivory**: Clean unruled paper formats.
- **Print-Ready Ruled** (`printRuled1.png`): High-contrast layout for laser & inkjet printing.

---

## Quickstart

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.13 or higher)
- Android Studio / Command Line Tools (for Android compilation)

### Clone & Run
```bash
# Clone the repository
git clone https://github.com/krish-dmg/unintently.git

# Enter project directory
cd unintently/unintently_app

# Fetch dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Build APK
```bash
flutter build apk --release
```

---

## Architecture

```
unintently/
├── unintently_app/                # Flutter application
│   ├── assets/
│   │   ├── fonts/                 # 12 recovered handwriting TTF/OTF fonts
│   │   ├── images/                # Authentic ruled paper backgrounds
│   │   └── branding/              # Modern minimalist vector logo
│   └── lib/
│       ├── models/                # Local document & preset definitions
│       ├── services/              # Offline storage, Cloudflare AI, PDF engine
│       ├── theme/                 # Clean ink palette & modern themes
│       └── screens/               # Interactive canvas editor & document gallery
├── cloudflare_worker/             # Serverless Cloudflare AI backend (Llama 3)
├── .github/
│   ├── workflows/ci.yml           # Automated build verification
│   └── ISSUE_TEMPLATE/            # Community issue templates
├── CONTRIBUTING.md                # Community contribution guidelines
├── CODE_OF_CONDUCT.md             # Contributor covenant standards
├── SECURITY.md                    # Privacy & vulnerability disclosure policy
└── LICENSE                        # MIT License
```

---

## Roadmap

- [x] Restore and decode all original handwriting typography and textures
- [x] Local-first offline storage without accounts or logins
- [x] Multi-line live handwriting editor with customizable ink color, size, and spacing
- [x] Serverless Cloudflare Workers AI integration for assignment generation
- [x] High-resolution A4 PDF export with embedded textures
- [ ] Multi-page pagination with automatic text reflow
- [ ] Diagram & image insertion overlay directly on notebook sheets
- [ ] Web PWA deployment via Cloudflare Pages

---

## Contributing

We welcome contributions from everyone! Please review our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting pull requests.

---

## License

This project is licensed under the [MIT License](LICENSE). Built for students, by students.
