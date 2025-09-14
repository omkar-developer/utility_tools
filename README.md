# Utility Tools

A comprehensive collection of text processing, AI-powered, and utility tools built with Flutter. Available as both desktop application and web app.

## 🚀 Features

### Core Categories
- **Text Processing** - Format, clean, sort, find & replace, extract data
- **AI-Powered Tools** - Summarization, translation, code analysis, image analysis  
- **Text Conversion** - Case transforms, separators, table conversion
- **Coding Utilities** - Encoding, hashing, encryption, regex tools
- **Text Generation** - UUID, passwords, fake text, QR codes
- **Image Tools** - PNG to ICO conversion, 9-patch UI generation, image editing
- **Dynamic JS Tools** - Runtime-loadable JavaScript tools library

### Key Tools

![Text Processing](https://img.shields.io/badge/Text-Processing-blue)
![AI Tools](https://img.shields.io/badge/AI-Powered-green)
![Coding](https://img.shields.io/badge/Coding-Utilities-orange)
![Image Tools](https://img.shields.io/badge/Image-Tools-purple)

**Text Processing & Formatting:**
- Advanced Find & Replace with regex support
- Text Statistics with readability scores
- Line operations (numbering, cleanup, sorting)
- Whitespace normalization and alignment
- Prefix/suffix operations with flexible patterns

**AI-Powered Features:**
- Text Summarizer with customizable length and style
- Multi-language Translator with tone control
- Code Explainer & Documentation Generator
- Image Analyzer for content extraction
- Writing Assistant for grammar and style enhancement

**Developer Tools:**
- Encoding Hub (Base64, Hex, URL, HTML entities, etc.)
- Hash & Crypto operations (SHA, MD5, HMAC, AES)
- Regex Builder with pattern explanations
- Code Converter between programming languages
- Universal Code Documenter

**Unique Features:**
- **Live Updates** - Most tools auto-process as you type
- **Markdown Support** - Full markdown input/output capability
- **Chain Processing** - Use splitters to process data in batches
- **Custom Settings** - Per-tool configuration with intuitive UI
- **JavaScript Library** - Add custom tools at runtime

## 📥 Installation

### Desktop Application
1. Download the latest release from the [Releases](../../releases) page
2. Extract the ZIP file
3. Run `utility_tools.exe` (Windows) or the appropriate executable for your platform

### Web Application
Access the web version directly in your browser - no installation required!

## 🎯 Usage

### Getting Started
1. **Select Category** - Choose from the main categories (Text Processing, AI Tools, etc.)
2. **Pick Tool** - Click on any tool badge to load it
3. **Enter Input** - Type or paste your text/data in the input area
4. **Process** - Click "Process" or let auto-processing handle it
5. **Get Results** - View the processed output

### Interface Features
- **Live Update Button** - Toggle real-time processing as you type
- **Settings Button** - Configure tool-specific options (gear icon)
- **Global Settings** - Access app-wide settings from the main toolbar
- **JS Tools Library** - Manage and add custom JavaScript tools

### Platform Differences
- **Desktop Version** - Full feature set including local AI model support (Ollama)
- **Web Version** - Cloud-based AI services, no local file access limitations

## 🔧 Configuration

### AI Services Setup
Configure AI providers in Global Settings:

- **Ollama** (Desktop only): `http://localhost:11434/v1`
- **OpenAI**: `https://api.openai.com/v1` 
- **Groq**: `https://api.groq.com/openai/v1`
- **Anthropic**: `https://api.anthropic.com/v1`
- **OpenRouter**: `https://openrouter.ai/api/v1`

### Customization
- **Theme**: Choose between Light, Dark, or System themes
- **JS Library**: Add custom JavaScript-powered tools

## 🛠 JavaScript Tools Library

The app includes a dynamic JavaScript tools system that allows you to:
- Add custom tools at runtime
- Share tools between users
- Extend functionality without rebuilding the app
- Create specialized processing tools for your workflows

Example JS tool structure:
```javascript
var name = "My Custom Tool";
var description = "Does something useful";
var icon = "extension";

function execute(input, settings) {
    return "Processed: " + input;
}
```

## 🏗 Built With

- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **JSF** - JavaScript runtime for custom tools
- **Various AI APIs** - OpenAI, Anthropic, Ollama, and more
- **Material 3** - Modern UI design system

## 📱 Platform Support

- ✅ Windows Desktop
- ✅ Linux Desktop  
- ✅ macOS Desktop
- ✅ Web Browser (Chrome, Firefox, Safari, Edge)
- 📱 Mobile support planned

## 🤝 Contributing

Contributions are welcome! This includes:
- Bug reports and feature requests
- JavaScript tools for the community library
- Code contributions and improvements
- Documentation enhancements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔮 Roadmap

- Mobile app versions (iOS/Android)

---

**Made with Flutter** | **Powered by AI** | **Open Source**