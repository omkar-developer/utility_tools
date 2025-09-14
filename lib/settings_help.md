# Settings Hints Documentation

Settings hints provide metadata for the `SettingsEditor` to render appropriate UI controls and validation. They're optional but enable rich, type-specific editing experiences.

## Basic Structure

```dart
settingsHints: {
  'setting_key': {
    'type': 'control_type',
    'label': 'Display Name',
    'help': 'Help text shown below control',
    // type-specific options...
  },
}
```

## Simple Hints (String)

For basic help text without custom controls:

```dart
settingsHints: {
  'trim_ends': 'Remove spaces from start and end of lines',
  'preserve_indentation': 'Keep leading spaces for indentation',
}
```

## Control Types

### Boolean (`bool`)
```dart
'enable_feature': {
  'type': 'bool',
  'label': 'Enable Feature',
  'help': 'Toggles the feature on/off',
  'inline_label': 'Show inline text next to toggle', // optional
}
```

### Number (`number`)
```dart
'max_count': {
  'type': 'number',
  'label': 'Maximum Count',
  'help': 'Number of items to process',
  'min': 1,           // minimum value
  'max': 100,         // maximum value  
  'decimal': false,   // true for double, false for int
  'placeholder': 'Enter number...',
}
```

### Text (`text`)
```dart
'api_key': {
  'type': 'text',
  'label': 'API Key',
  'help': 'Your secret API key',
  'placeholder': 'Enter key...',
  'obscure': true,    // hide text (password field)
  'pattern': r'^\w+$', // regex validation (optional)
}
```

### Multiline Text (`multiline`)
```dart
'template': {
  'type': 'multiline',
  'label': 'Template',
  'help': 'Multi-line template text',
  'placeholder': 'Enter template...',
  'min_lines': 3,     // minimum visible lines
  'max_lines': 10,    // maximum lines (null = unlimited)
}
```

### Dropdown (`dropdown`)
```dart
'output_format': {
  'type': 'dropdown',
  'label': 'Output Format',
  'help': 'Choose output format',
  'placeholder': 'Select format...',
  'options': [
    'json',
    'xml', 
    {'label': 'YAML Format', 'value': 'yaml'}, // custom display
  ],
}
```

### Slider (`slider`)
```dart
'quality': {
  'type': 'slider',
  'label': 'Quality',
  'help': 'Image quality setting',
  'min': 0.0,
  'max': 100.0,
  'integer': false,        // true for int values
  'divisions': 10,         // snap points (optional)
  'show_value': true,      // display current value
  'show_range': true,      // show min/max labels
}
```

### Color (`color`)
```dart
'theme_color': {
  'type': 'color',
  'label': 'Theme Color',
  'help': 'Primary theme color',
}
```

### File Path (`file`)
```dart
'input_file': {
  'type': 'file',
  'label': 'Input File',
  'help': 'Select input file path',
  'placeholder': 'Choose file...',
  'readonly': false,       // allow manual typing
}
```

## Auto-Detection Fallbacks

Without hints, the editor auto-detects control types:
- `bool` → ToggleSwitch
- `int` → NumberBox<int>
- `double` → NumberBox<double>
- `String` → TextBox

## Complete Example

```dart
class MyTool extends Tool {
  MyTool() : super(
    name: 'Text Processor',
    description: 'Process text with various options',
    icon: FluentIcons.text_field,
    settings: {
      'enabled': true,
      'max_length': 100,
      'output_format': 'json',
      'template': 'Hello {name}!',
      'quality': 80.0,
    },
    settingsHints: {
      'enabled': {
        'type': 'bool',
        'label': 'Enable Processing',
        'help': 'Turn processing on or off',
      },
      'max_length': {
        'type': 'number',
        'label': 'Maximum Length',
        'help': 'Maximum characters to process',
        'min': 1,
        'max': 1000,
      },
      'output_format': {
        'type': 'dropdown',
        'label': 'Output Format',
        'options': ['json', 'xml', 'yaml'],
      },
      'template': {
        'type': 'multiline',
        'label': 'Text Template',
        'min_lines': 2,
        'max_lines': 5,
      },
      'quality': {
        'type': 'slider',
        'label': 'Quality',
        'min': 0.0,
        'max': 100.0,
        'show_value': true,
      },
    },
  );
}
```

## Tips

- **Keep it simple:** Use string hints for basic help text
- **Progressive enhancement:** Start without hints, add them as needed
- **Consistent labels:** Use clear, descriptive labels
- **Helpful text:** Provide context in help text
- **Validation:** Use `min`/`max`/`pattern` for input validation
- **Fallbacks work:** Editor handles missing hints gracefully