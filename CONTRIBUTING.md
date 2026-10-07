# Contributing to Unintently

Thank you for your interest in contributing to **Unintently**! This project is dedicated to providing students, teachers, and developers with a completely free, open-source tool for generating handwritten assignments without paywalls, subscriptions, or invasive tracking.

---

## Code of Conduct

We are committed to providing a welcoming, inclusive, and harassment-free environment for everyone. Please be respectful and considerate in all communications, issues, and pull requests.

---

## How Can You Contribute?

### 1. Adding New Handwriting Fonts
We want Unintently to support more natural, diverse, and authentic handwriting styles from students around the world.
- Place your `.ttf` or `.otf` file inside `unintently_app/assets/fonts/`.
- Ensure font licenses permit open redistribution.
- Register the font family in `pubspec.yaml` and add an entry to `HandwritingFontOption.allFonts` in `unintently_app/lib/models/preset_options.dart`.

### 2. Adding Paper Backgrounds
- High-resolution unruled, quad-ruled (graph paper), isometric, lab record, or ledger templates.
- Add optimized images (`.jpg` / `.png`) to `unintently_app/assets/images/`.
- Register the template in `PaperTemplateOption.allPapers` in `unintently_app/lib/models/preset_options.dart`.

### 3. Improving the Rendering Engine
- Introducing natural letter jitter, baseline variance, word-wrap improvements, and margin alignment.
- Adding multi-page assignment pagination with auto-flowing text.

### 4. Cloudflare Worker AI Improvements
- Enhancing system prompts for assignment formatting in `cloudflare_worker/src/index.js`.
- Adding support for alternative open-source LLM backends (e.g., DeepSeek, Mistral).

---

## Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/krish-dmg/unintently.git
   cd unintently/unintently_app
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Code Analysis:**
   ```bash
   flutter analyze
   ```

4. **Run the Application:**
   ```bash
   flutter run
   ```

---

## Pull Request Guidelines

- Create a feature branch with a descriptive name (`git checkout -b feat/add-graph-paper`).
- Follow clear, conventional commit messages (`feat: ...`, `fix: ...`, `docs: ...`).
- Run `flutter analyze` before committing to ensure there are no lints or warnings.
- Open a Pull Request on GitHub with a description of the changes made and screenshots if applicable.
