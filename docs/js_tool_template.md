# Tool Development Guide

This guide explains how to create custom tools for the Utility Tools application. You can create tools in both JavaScript (for runtime loading) and Dart (for compiled integration).

## Quick Start

### Using AI to Generate Tools
The app includes an AI-powered **Tool Generator** that can create complete tools from natural language descriptions. its in AI Text Processing -> Tool Generator

**Manual Prompt Template for AI Generation usign chat bots:**
```
Create a [JavaScript/Dart] tool for [category] that [description of functionality].

Tool requirements:
- Name: [Tool Name]
- Purpose: [What it does]
- Input: [What input it expects, or "none" for generators]
- Settings: [What should be configurable]
- Output: [What it produces]

Example: "Create a JavaScript tool for Text Processing that converts text to alternating caps (LiKe ThIs). It should have settings for starting with uppercase/lowercase and preserving spaces."
```

### Manual Creation
You can also create tools manually using the templates below.

## JavaScript Tools

JavaScript tools are loaded at runtime and can be added through the Tools Library interface.

### Basic Tool Structure

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

### AI Tool Structure

```javascript
var name = "AI Tool Name";
var description = "AI-powered tool description";
var icon = "auto_awesome";
var isOutputMarkdown = true; // AI tools often output markdown
var isInputMarkdown = false;
var canAcceptMarkdown = true;
var supportsLiveUpdate = false; // AI tools are usually slower
var allowEmptyInput = false;

var settings = {
  "style": "professional",
  "length": "medium"
};

var settingsHints = {
  "style": {
    "type": "dropdown",
    "label": "Writing Style",
    "help": "Choose the output style",
    "options": [
      {"value": "professional", "label": "Professional"},
      {"value": "casual", "label": "Casual"},
      {"value": "creative", "label": "Creative"}
    ]
  }
};

function buildAISystemPrompt(input, settings) {
  return "You are an expert assistant. Style: " + settings.style + 
         ". Process the following text according to the requirements...";
}

function buildAIMessages(input, systemPrompt, settings) {
  return [
    {"role": "system", "content": systemPrompt},
    {"role": "user", "content": input}
  ];
}
```

## Setting Types Reference

### Basic Types
```javascript
// Boolean checkbox
"enabled": {
  "type": "bool",
  "label": "Enable Feature",
  "help": "Toggle this feature on/off"
}

// Text input
"prefix": {
  "type": "text",
  "label": "Prefix Text",
  "help": "Text to add at the beginning",
  "placeholder": "Enter prefix..."
}

// Multi-line text
"template": {
  "type": "multiline",
  "label": "Template",
  "help": "Multi-line template text",
  "rows": 3,
  "placeholder": "Enter template..."
}
```

### Numeric Types
```javascript
// Simple number input
"count": {
  "type": "number",
  "label": "Count",
  "min": 1,
  "max": 100,
  "decimal": false // true for float values
}

// Spinner with +/- buttons
"iterations": {
  "type": "spinner",
  "label": "Iterations",
  "min": 1,
  "max": 50,
  "step": 1,
  "decimal": false,
  "decimals": 1 // decimal places when decimal=true
}

// Visual slider
"strength": {
  "type": "slider",
  "label": "Strength",
  "min": 0.0,
  "max": 1.0,
  "divisions": 10,
  "show_range": true
}
```

### Selection Types
```javascript
// Dropdown selection
"format": {
  "type": "dropdown",
  "label": "Output Format",
  "help": "Choose output format",
  "options": [
    {"value": "json", "label": "JSON"},
    {"value": "csv", "label": "CSV"},
    {"value": "xml", "label": "XML"}
  ]
}

// Multiple selection
"features": {
  "type": "multiselect",
  "label": "Features",
  "help": "Select features to include",
  "options": [
    {"value": "feat1", "label": "Feature 1"},
    {"value": "feat2", "label": "Feature 2"}
  ],
  "min_selections": 1,
  "max_selections": 3
}
```

### Visual Types
```javascript
// Color picker
"theme_color": {
  "type": "color",
  "label": "Theme Color",
  "help": "Choose the theme color",
  "alpha": true, // Allow opacity
  "presets": true // Show color presets
}
```

## Icon Names

### Regular Tool Icons
- `edit` - Text editing
- `transform` - Data transformation  
- `code` - Programming/code
- `format_paint` - Formatting
- `functions` - Mathematical functions
- `build` - Construction/building
- `filter_list` - Filtering/sorting
- `password` - Security/passwords
- `calculate` - Calculator
- `casino` - Random/dice
- `image` - Image processing
- `qr_code` - QR codes
- `color_lens` - Colors
- `tune` - Settings/tuning

### AI Tool Icons
- `auto_awesome` - AI magic
- `psychology` - AI thinking
- `smart_toy` - AI assistant
- `lightbulb` - Ideas/insights
- `translate` - Translation
- `summarize` - Summarization
- `chat` - Conversation
- `image` - Image AI
- `brush` - Creative AI
- `palette` - Design AI

## Important Properties

### allowEmptyInput
Controls whether the tool needs text input from the user:

```javascript
// Tools that DON'T need user text input
allowEmptyInput = true;
// Examples: password generators, calculators, random generators, 
// QR code generators, image creators

// Tools that DO need user text input  
allowEmptyInput = false;
// Examples: text formatters, translators, analyzers, converters
```

### Output Formats
Tools can return various output formats:

```javascript
// Regular text
return "Plain text result";

// Markdown text
return "# Markdown Result\n\nWith **formatting**";

// SVG image
return "```svg\n<svg>...</svg>\n```";

// Base64 image
return "```png\ndata:image/png;base64,iVBORw0K...\n```";
```

## Examples

### Text Processing Tool
```javascript
var name = "Alternating Caps";
var description = "Converts text to alternating uppercase/lowercase";
var icon = "format_paint";
var allowEmptyInput = false; // Needs text input
var supportsLiveUpdate = true;

var settings = {
  "start_upper": true,
  "preserve_spaces": true
};

var settingsHints = {
  "start_upper": {
    "type": "bool", 
    "label": "Start with Uppercase",
    "help": "Whether to start with an uppercase letter"
  },
  "preserve_spaces": {
    "type": "bool",
    "label": "Preserve Spaces", 
    "help": "Keep original spacing"
  }
};

function execute(input, settings) {
  var result = "";
  var shouldBeUpper = settings.start_upper;
  
  for (var i = 0; i < input.length; i++) {
    var char = input[i];
    if (char === " " && settings.preserve_spaces) {
      result += char;
      continue;
    }
    
    result += shouldBeUpper ? char.toUpperCase() : char.toLowerCase();
    shouldBeUpper = !shouldBeUpper;
  }
  
  return result;
}
```

### Password Generator
```javascript
var name = "Password Generator";
var description = "Generate secure random passwords";
var icon = "password";
var allowEmptyInput = true; // No text input needed
var supportsLiveUpdate = false;

var settings = {
  "length": 12,
  "include_symbols": true,
  "include_numbers": true,
  "include_uppercase": true
};

var settingsHints = {
  "length": {
    "type": "spinner",
    "label": "Password Length",
    "min": 4,
    "max": 64,
    "step": 1
  },
  "include_symbols": {
    "type": "bool",
    "label": "Include Symbols",
    "help": "Include special characters (!@#$%^&*)"
  },
  "include_numbers": {
    "type": "bool", 
    "label": "Include Numbers"
  },
  "include_uppercase": {
    "type": "bool",
    "label": "Include Uppercase"
  }
};

function execute(input, settings) {
  var chars = "abcdefghijklmnopqrstuvwxyz";
  if (settings.include_uppercase) chars += "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  if (settings.include_numbers) chars += "0123456789";
  if (settings.include_symbols) chars += "!@#$%^&*()_+-=[]{}|;:,.<>?";
  
  var password = "";
  for (var i = 0; i < settings.length; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  return password;
}
```

## Best Practices

1. **Clear Naming**: Use descriptive names and descriptions
2. **Appropriate Settings**: Only add settings that users actually need to configure
3. **Input Validation**: Handle edge cases and invalid inputs gracefully
4. **Performance**: For live updates, keep processing fast
5. **Error Handling**: Return helpful error messages when things go wrong
6. **Testing**: Test with various inputs and setting combinations

## Adding Tools to the App

### JavaScript Tools
1. Open the Tools Library in the app
2. Click "Add New Tool"  
3. Paste your JavaScript code
4. Set category and metadata
5. Save - the tool is immediately available

### Dart Tools (Advanced)
For Dart tools integrated into the main application:
1. Create your tool class following the templates
2. Add to the appropriate category file
3. Export in the category's getter function
4. Rebuild the application

## AI Prompt for Tool Generation

Use this prompt with the built-in Tool Generator or external AI:

```
Create a [JavaScript/Dart] tool for the Utility Tools app with these specifications:

**Tool Details:**
- Category: [Text Processing/AI Tools/Developer Tools/etc.]
- Name: [Tool Name]
- Description: [What it does]
- Input Type: [Text input required / No input needed (generator)]

**Functionality:**
[Detailed description of what the tool should do]

**Settings Required:**
[List the configurable options users should have]

**Example Usage:**
Input: [Example input]
Expected Output: [Expected result]

Please follow the framework structure exactly and include appropriate setting types, icons, and the allowEmptyInput property based on whether the tool needs text input.
```

This template provides everything needed to create custom tools for your application!