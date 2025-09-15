## Tool Creation Template

### Regular Tool (extends Tool)

For standard processing tools that don't need AI assistance.

```dart
class ExampleTool extends Tool {
  ExampleTool() : super(
    name: 'Tool Name',
    description: 'What this tool does',
    icon: Icons.icon_name,
    allowEmptyInput: false, // true if no text input needed
    isOutputMarkdown: true, // if Output is markdown
    settings: {
      'setting1': defaultValue,
    },
    settingsHints: {
      'setting1': {'type': 'bool', 'label': 'Label'},
    },
  );

  @override
  Future<ToolResult> execute(String input) async {
    // Process input using settings['key']
    return ToolResult(output: result, status: 'success');
  }
}
```

### AI Tool (extends BaseAITool)

For tools that use AI assistance.

```dart
class AiExampleTool extends BaseAITool {
  AiExampleTool({Map<String, dynamic>? settings}) : super(
    settings: settings ?? {'setting1': defaultValue},
    name: 'AI Tool Name',
    description: 'What this AI tool does',
    icon: Icons.icon_name,
    allowEmptyInput: false,
    settingsHints: {
      'setting1': {'type': 'bool', 'label': 'Label'},
    },
  );

  @override
  String buildAISystemPrompt(String input) {
    return AIService.buildSystemPrompt(
      role: 'expert role description',
      context: 'context information',
      instructions: ['instruction1', 'instruction2'],
    );
  }

  @override
  List<ChatMessage> buildAIMessages(String input, String systemPrompt) {
    return [
      ChatMessage(role: 'system', content: systemPrompt),
      ChatMessage(role: 'user', content: input),
    ];
  }
}
```

## Setting Types

### Basic Controls

- **bool**: `{'type': 'bool', 'label': 'Enable Feature', 'help': 'Toggle this on/off'}`
- **text**: `{'type': 'text', 'label': 'Input Text', 'placeholder': 'Enter text...', 'help': 'Help text'}`
- **multiline**: `{'type': 'multiline', 'label': 'Description', 'rows': 3, 'placeholder': 'Enter...'}`

### Number Controls

- **number**: `{'type': 'number', 'label': 'Count', 'min': 0, 'max': 100, 'decimal': false}`
- **spinner**: `{'type': 'spinner', 'label': 'Count', 'min': 0, 'max': 100, 'step': 1, 'decimal': false}`
- **slider**: `{'type': 'slider', 'label': 'Quality', 'min': 0, 'max': 100, 'divisions': 10, 'show_range': true}`

### Selection Controls

- **dropdown**: `{'type': 'dropdown', 'label': 'Choose Option', 'options': ['opt1', 'opt2']}`
- **multiselect**: `{'type': 'multiselect', 'label': 'Choose Multiple', 'options': ['opt1', 'opt2'], 'min_selections': 1, 'max_selections': 3}`

### Advanced Controls

- **color**: `{'type': 'color', 'label': 'Theme Color', 'help': 'Pick color', 'alpha': true, 'presets': true}`
- **date**: `{'type': 'date', 'label': 'Select Date', 'min_date': '2020-01-01', 'max_date': '2030-12-31'}`
- **time**: `{'type': 'time', 'label': 'Select Time', 'format': '24h'}`
- **range**: `{'type': 'range', 'label': 'Range', 'min': 0, 'max': 100, 'default_start': 20, 'default_end': 80}`
- **file**: `{'type': 'file', 'label': 'Choose File', 'accept': ['.txt', '.json'], 'multiple': false}`

## Default Values

### Setting Defaults

```dart
settings: {
  'text_value': 'default text',
  'number_value': 42,
  'bool_value': true,
  'multiselect_value': ['option1', 'option2'], // List<String>
  'color_value': '#3498db', // Hex color string
  'date_value': '2024-01-01', // YYYY-MM-DD format
  'time_value': '09:00', // HH:MM format
  'range_value': {'start': 20, 'end': 80}, // Map with start/end
}
```

## Visual Output

### SVG Output

```dart
String svg = '<svg width="100" height="100">...</svg>';
return ToolResult(output: '```svg\\n$svg\\n```', status: 'success');
```

### Base64 Image Output

```dart
String base64 = 'data:image/png;base64,iVBORw0KGgoAAAANS...';
return ToolResult(output: '```png\\n$base64\\n```', status: 'success');
```

## Key Properties

### allowEmptyInput

- **true**: Tool doesn't need text input from user (hides input box)
    - Use for: password generators, calculators, image generators, utilities
- **false**: Tool processes user text input
    - Use for: text formatters, converters, analyzers

### Icons

Common icon suggestions:

- Text tools: `Icons.edit`, `Icons.format_paint`, `Icons.text_fields`
- Generators: `Icons.build`, `Icons.casino`, `Icons.password`
- Converters: `Icons.transform`, `Icons.code`, `Icons.functions`
- Visual: `Icons.image`, `Icons.palette`, `Icons.color_lens`
- Time: `Icons.schedule`, `Icons.calendar_today`, `Icons.access_time`

## Accessing Settings

```dart
@override
Future<ToolResult> execute(String input) async {
  // Access settings with bracket notation
  String textSetting = settings['text_setting'];
  int numberSetting = settings['number_setting'];
  bool boolSetting = settings['bool_setting'];
  List<String> multiselect = settings['multiselect_setting'];
  String color = settings['color_setting'];
  Map rangeValue = settings['range_setting'];
  double startValue = rangeValue['start'];
  double endValue = rangeValue['end'];
  
  // Process and return result
  return ToolResult(output: processedResult, status: 'success');
}
```

## Complete Example

```dart
class ColorPaletteGenerator extends Tool {
  ColorPaletteGenerator() : super(
    name: 'Color Palette Generator',
    description: 'Generate color palettes from a base color',
    icon: Icons.palette,
    allowEmptyInput: true, // No text input needed
    settings: {
      'base_color': '#3498db',
      'count': 5,
      'saturation': 80.0,
      'formats': ['hex'],
    },
    settingsHints: {
      'base_color': {
        'type': 'color',
        'label': 'Base Color',
        'help': 'Starting color for palette generation',
        'presets': true,
      },
      'count': {
        'type': 'spinner',
        'label': 'Color Count',
        'min': 2,
        'max': 10,
        'step': 1,
      },
      'saturation': {
        'type': 'slider',
        'label': 'Saturation',
        'min': 0.0,
        'max': 100.0,
        'divisions': 20,
      },
      'formats': {
        'type': 'multiselect',
        'label': 'Output Formats',
        'options': ['hex', 'rgb', 'hsl'],
        'min_selections': 1,
      },
    },
  );

  @override
  Future<ToolResult> execute(String input) async {
    String baseColor = settings['base_color'];
    int count = settings['count'];
    double saturation = settings['saturation'];
    List<String> formats = settings['formats'];
    
    // Generate palette logic here
    String result = generatePalette(baseColor, count, saturation, formats);
    
    return ToolResult(output: result, status: 'success');
  }
}
```

## Usage Tips

1. **Choose appropriate allowEmptyInput**: true for generators/utilities, false for text processors
2. **Use descriptive labels and help text** for better UX
3. **Set reasonable min/max values** for number controls
4. **Provide sensible defaults** for all settings
5. **Use visual output** (SVG/images) when appropriate
6. **Consider multiselect** for feature toggles
7. **Use range controls** for min/max selections
8. **Add date/time pickers** for scheduling tools