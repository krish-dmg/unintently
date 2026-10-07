# Unintently (v2.0)

> **Free, Open-Source AI-Powered Text-to-Handwriting & Assignment Generator**

Unintently converts typed text, essays, and homework questions into realistic handwritten assignments rendered on authentic paper textures (ruled sheets, practical files, assignment registers).

---

## What’s New in Version 2.0 (Open-Source Edition)

- **Zero-Cost Architecture:** Completely decoupled from paid Firebase infrastructure. Runs 100% free with no monthly bills.
- **No Sign-In / Account Needed:** Privacy-first, local-first storage. No forced logins, phone verifications, or passwords.
- **Paywall-Free:** Removed all in-app purchases and subscriptions. All 12 custom handwriting fonts and all paper styles are unlocked.
- **Zero Push Notifications:** No marketing spam or notification background services.
- **AI-Powered Assignments:** Built-in AI assistant powered by free serverless **Cloudflare Workers AI** (`@cf/meta/llama-3-8b-instruct`).
- **One-Click PDF Export:** Real-time generation of print-ready high-resolution PDFs formatted for standard A4 paper.

---

## Typography & Paper Textures

### Handwriting Fonts (All Unlocked)
1. **Intently Signature** (`intentlyR1`) - Natural cursive flow
2. **Intently Fast Hand** (`intentlyR2`) - Quick lecture notes
3. **Intently Clean** (`intentlyR8`) - Structured penmanship
4. **Intently Exam Pen** (`intentlyR11`) - Tight exam handwriting
5. **Intently Journal** (`intentlyR12`) - Ballpoint diary style
6. **Classic Script 1–3** (`Writing1`, `Writing2`, `Writing3`) - Ruled notebook cursive
7. **Gel Pen Quick** (`Writing4`) - Ballpoint school script
8. **Casual Student** (`Writing5`) - Classroom notes
9. **Practical Lab File** (`Writing7`) - Sharp technical script
10. **Homework Pen** (`Writing8`) - High-school assignment hand

### Paper Backgrounds
- Classic Ruled (`ruled.jpg`)
- College Ruled 1 & 2 (`ruled1.jpg`, `ruled2.jpg`)
- Wide Ruled 3 (`ruled3.jpg`)
- Margin Register 4 (`ruled4.jpg`)
- Heavy Paper 5 (`ruled5.jpg`)
- Assignment Sheet (`ruledAssignment.jpeg`)
- Blank White A4 & Natural Ivory
- Print-Ready Ruled (`printRuled1.png`)

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.13+)
- Android Studio / Xcode (for native deployment)

### Running the App
```bash
cd unintently_app
flutter pub get
flutter run
```

### Deploying the Cloudflare AI Worker
```bash
cd cloudflare_worker
npx wrangler deploy
```

---

## License
MIT License - Open-source and free for all students and developers worldwide.
