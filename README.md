# Utility Tools

A comprehensive collection of text processing, AI-powered, and utility tools built with Flutter. Available as both desktop application and web app.

**🌐 Try it now:** [utility-tools.web.app](https://omkar-developer.github.io/utility_tools/)

## 🚀 Features

### Text Processing & Formatting
- Advanced Find & Replace with regex support
- Text Statistics with readability scores
- Line operations (numbering, cleanup, sorting)
- Whitespace normalization and alignment
- Case transforms and separator conversion

### AI-Powered Tools
- Text Summarizer with customizable length and style
- Multi-language Translator with tone control
- Code Explainer & Documentation Generator
- Image Analyzer for content extraction
- Writing Assistant for grammar enhancement

### Developer Utilities
- Encoding Hub (Base64, Hex, URL, HTML entities)
- Hash & Crypto operations (SHA, MD5, HMAC, AES)
- Regex Builder with pattern explanations
- Code Converter between programming languages
- Text Generation (UUID, passwords, fake data, QR codes)

### Image Tools
- PNG to ICO conversion
- 9-patch UI generation
- Basic image editing

### Unique Features
- **Live Updates** - Auto-process as you type
- **JavaScript Library** - Add custom tools at runtime
- **Chain Processing** - Process data in batches with splitters
- **Markdown Support** - Full markdown input/output capability

## 📥 Installation

### Web Application (Recommended)
Access directly at: **[omkar-developer.github.io/utility_tools/](https://omkar-developer.github.io/utility_tools/)**

No installation required - works in any modern browser!

### Desktop Application
1. Download from [Releases](../../releases) page
2. Extract ZIP file
3. Run executable for your platform

## 🎯 Getting Started

### Basic Usage
1. **Select a Tool**: Use the category dropdown to browse tools, then click any tool badge
2. **Configure Settings**: Click the settings button (⚙️) next to the selected tool to customize options
3. **Enter Input**: Type or paste your data in the input area
4. **Process**: Click "Process" or enable live updates for real-time processing

### Tool Settings
Each tool has customizable settings accessible via the settings button (⚙️):
- Click the settings button that appears after selecting a tool
- Adjust parameters like output format, processing options, etc.
- Settings are applied immediately with live updates enabled
- Some tools have advanced options for fine-tuning behavior

### Live Updates
Toggle the "Live Update" button to automatically process text as you type:
- Enable for real-time results while editing
- Disable for manual processing of large texts
- Available for most text processing tools

### Chain Mode
Create multi-step processing workflows:
1. Click the chain button (🔗) in the toolbar
2. Add multiple tools to create a processing sequence
3. Tools execute in order, passing output to the next tool
4. Save and load chains for repeated workflows

## 🔧 AI Configuration

### Required Setup for AI Tools
1. Click **Settings** in the toolbar or sidebar
2. Configure your AI provider:

| Setting | Description | Example |
|---------|-------------|---------|
| **Base URL** | AI service endpoint | `https://api.openai.com/v1` |
| **API Key** | Your service API key | `sk-...` (required for cloud services) |
| **Model** | AI model to use | `gpt-3.5-turbo` or `qwen2.5-coder:7b` |
| **Temperature** | Response creativity (0-1) | `0.7` |
| **Max Tokens** | Response length limit | `2048` |

### 🔑 API Key Storage

Your AI API keys are stored **locally on your device** using [Hive](https://pub.dev/packages/hive), which maps to **IndexedDB** in the browser and a local storage file on desktop.  

- Keys never leave your machine unless you explicitly use them for API calls.  
- Other websites cannot access them due to browser **same-origin policies**.  
- You can clear keys anytime by removing site data from your browser or resetting the app settings.  

### Supported Providers

#### Cloud Services (Web + Desktop)
- **OpenAI**: `https://api.openai.com/v1`
- **Groq**: `https://api.groq.com/openai/v1`
- **Anthropic**: `https://api.anthropic.com/v1`
- **OpenRouter**: `https://openrouter.ai/api/v1`

#### Local Services (Desktop Only)
- **Ollama**: `http://localhost:11434/v1` (no API key needed)

### Setup Examples

#### OpenAI Setup
1. Get API key from [OpenAI Platform](https://platform.openai.com)
2. Base URL: `https://api.openai.com/v1`
3. Model: `gpt-3.5-turbo` or `gpt-4`
4. Add your API key

#### Ollama Setup (Desktop)
1. Install [Ollama](https://ollama.ai) locally
2. Run: `ollama pull qwen2.5-coder:7b`
3. Base URL: `http://localhost:11434/v1`
4. Model: `qwen2.5-coder:7b`
5. Leave API key empty

## 🛠 JavaScript Tools Library

Extend functionality with custom JavaScript tools:

### Adding Custom Tools
1. Click **Library** button in toolbar
2. Create new tool or import existing
3. Tools load automatically without restart

### Example Tool Structure
```javascript
var name = "Tool Name";
var description = "Brief description of what the tool does";
var icon = "edit"; // See icon list below
var isOutputMarkdown = true;
var isInputMarkdown = false;
var canAcceptMarkdown = false;
var supportsLiveUpdate = true;
var allowEmptyInput = false; // Set true for generators/calculators

var settings = {
  "setting1": "default_value",
  "number_setting": 10,
  "boolean_setting": true
};

var settingsHints = {
  "setting1": {
    "type": "dropdown",
    "label": "Setting Label",
    "help": "Helpful description",
    "options": [
      {"value": "val1", "label": "Option 1"},
      {"value": "val2", "label": "Option 2"}
    ]
  }
};

function execute(input, settings) {
  // Process input using settings
  // Access settings: settings.setting1
  var result = processInput(input, settings);
  return result;
}
```

### Features
- Runtime tool loading
- Community tool sharing
- Specialized workflow tools
- No app rebuild required

## 💡 Usage Tips

### Mobile/Tablet Interface
- Categories and tools stack vertically on smaller screens
- Chain panel opens as modal drawer
- Settings panels adapt to screen size
- Touch-friendly controls throughout

### Keyboard Shortcuts
- **F11**: Toggle fullscreen (web)
- **Ctrl+R**: Refresh page (web)
- Live updates work with copy/paste workflows

### Performance
- Large texts: Disable live updates for better performance
- Streaming: AI tools show real-time output with cancel option
- Memory: Tools process data locally when possible

## 📱 Platform Support

| Platform | Status | Features |
|----------|--------|----------|
| **Web Browser** | ✅ Full | Cloud AI, all tools |
| **Windows** | ✅ Full | Local AI support |
| **Linux** | ✅ Full | Local AI support |
| **macOS** | ✅ Full | Local AI support |
| **Mobile** | 📱 Planned | Touch-optimized UI |

## 🛠 Building & Development

### Building for Windows
```bash
# Install dependencies
flutter pub get

# Build release version
flutter build windows --release

# Output location: build/windows/runner/Release/
```

### Building for Android
```bash
# Build APK for sideloading
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### Building for Web
```bash
# Build for web deployment
flutter build web --release

# Deploy to GitHub Pages or any web server
```

### Creating Custom Tools
For developers interested in creating new tools, see our [Tool Development Guide](docs/tool_template.md).
Javascript tool template: [Tool Development Guide](docs/js_tool_template.md).

## 🤝 Contributing

We welcome contributions:
- Bug reports and feature requests
- JavaScript tools for the community library
- Code improvements and documentation
- Translation and accessibility enhancements

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔮 Roadmap

- Adding more useful tools.

---

**Built with Flutter** | **Powered by AI** | **Open Source**