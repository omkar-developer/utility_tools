import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math';
import 'package:utility_tools/models/tool.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

class PngToIcoTool extends Tool {
  PngToIcoTool()
    : super(
        name: 'PNG to ICO Converter',
        description: 'Convert PNG images to ICO format with multiple sizes',
        icon: Icons.image_outlined,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: false, // Expensive operation
        supportsStreaming: false,
        settings: {
          'sizes': '16,32,48,256',
          'quality': 90,
          'filename': 'favicon.ico',
        },
        settingsHints: {
          'sizes': {
            'type': 'text',
            'label': 'Icon Sizes',
            'help': 'Comma-separated list of icon sizes (e.g., 16,32,48,256)',
            'placeholder': '16,32,48,256',
          },
          'quality': {
            'type': 'slider',
            'label': 'Quality',
            'help':
                'Compression quality (higher = better quality, larger file)',
            'min': 10.0,
            'max': 100.0,
            'divisions': 90,
            'show_value': true,
          },
          'filename': {
            'type': 'text',
            'label': 'Output Filename',
            'help': 'Name for the generated ICO file',
            'placeholder': 'favicon.ico',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      // Extract base64 image data
      String base64Data = _extractBase64(input);
      if (base64Data.isEmpty) {
        return ToolResult(
          output:
              '❌ **Error**: No valid base64 image data found in input.\n\nPlease provide a base64-encoded PNG image.',
          status: 'error',
        );
      }

      // Decode base64 to bytes
      Uint8List pngBytes;
      try {
        pngBytes = base64Decode(base64Data);
      } catch (e) {
        return ToolResult(
          output: '❌ **Error**: Invalid base64 data - $e',
          status: 'error',
        );
      }

      // Parse sizes
      List<int> iconSizes = _parseSizes(settings['sizes']);
      if (iconSizes.isEmpty) {
        return ToolResult(
          output:
              '❌ **Error**: Invalid sizes format. Use comma-separated numbers like "16,32,48,256"',
          status: 'error',
        );
      }

      // Convert PNG to ICO
      Uint8List icoBytes = await _convertPngToIco(pngBytes, iconSizes);
      String icoBase64 = base64Encode(icoBytes);

      String filename = settings['filename'] ?? 'favicon.ico';
      if (!filename.toLowerCase().endsWith('.ico')) {
        filename += '.ico';
      }

      // Generate markdown output
      String output = _generateMarkdownOutput(
        icoBase64,
        filename,
        iconSizes,
        icoBytes.length,
      );

      return ToolResult(output: output, status: 'success');
    } catch (e) {
      return ToolResult(
        output: '❌ **Error**: Failed to convert PNG to ICO - $e',
        status: 'error',
      );
    }
  }

  String _extractBase64(String input) {
    // Remove data URL prefix if present
    if (input.contains('data:image/png;base64,')) {
      return input.split('data:image/png;base64,')[1].trim();
    }

    // Remove common prefixes and whitespace
    return input
        .replaceAll('data:image/', '')
        .replaceAll('base64,', '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  List<int> _parseSizes(String sizesStr) {
    try {
      return sizesStr
          .split(',')
          .map((s) => int.parse(s.trim()))
          .where((size) => size > 0 && size <= 256)
          .toSet() // Remove duplicates
          .toList()
        ..sort(); // Sort ascending
    } catch (e) {
      return [];
    }
  }

  Future<Uint8List> _convertPngToIco(
    Uint8List pngBytes,
    List<int> sizes,
  ) async {
    // Decode the PNG image
    ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ui.Image originalImage = frameInfo.image;

    List<Uint8List> iconEntries = [];

    // Generate each size
    for (int size in sizes) {
      // Resize image
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);

      // Scale and draw the image
      double scale = size / originalImage.width.toDouble();
      canvas.scale(scale, scale);
      canvas.drawImage(originalImage, Offset.zero, Paint());

      ui.Picture picture = recorder.endRecording();
      ui.Image resizedImage = await picture.toImage(size, size);

      // Convert to PNG bytes
      ByteData? byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        iconEntries.add(byteData.buffer.asUint8List());
      }
    }

    originalImage.dispose();

    // Build ICO file
    return _buildIcoFile(iconEntries, sizes);
  }

  Uint8List _buildIcoFile(List<Uint8List> iconEntries, List<int> sizes) {
    BytesBuilder builder = BytesBuilder();

    // ICO Header (6 bytes)
    builder.add([0, 0]); // Reserved (must be 0)
    builder.add([1, 0]); // Image type (1 = ICO)
    builder.add([
      iconEntries.length & 0xFF,
      (iconEntries.length >> 8) & 0xFF,
    ]); // Number of images

    int dataOffset =
        6 + (iconEntries.length * 16); // Header + directory entries

    // Directory entries (16 bytes each)
    for (int i = 0; i < iconEntries.length; i++) {
      int size = sizes[i];
      int dataSize = iconEntries[i].length;

      builder.addByte(size == 256 ? 0 : size); // Width (0 means 256)
      builder.addByte(size == 256 ? 0 : size); // Height (0 means 256)
      builder.addByte(0); // Color palette size (0 for PNG)
      builder.addByte(0); // Reserved
      builder.add([1, 0]); // Color planes
      builder.add([32, 0]); // Bits per pixel (32 for PNG)

      // Data size (little endian)
      builder.add([
        dataSize & 0xFF,
        (dataSize >> 8) & 0xFF,
        (dataSize >> 16) & 0xFF,
        (dataSize >> 24) & 0xFF,
      ]);

      // Data offset (little endian)
      builder.add([
        dataOffset & 0xFF,
        (dataOffset >> 8) & 0xFF,
        (dataOffset >> 16) & 0xFF,
        (dataOffset >> 24) & 0xFF,
      ]);

      dataOffset += dataSize;
    }

    // Add image data
    for (Uint8List imageData in iconEntries) {
      builder.add(imageData);
    }

    return builder.toBytes();
  }

  String _generateMarkdownOutput(
    String icoBase64,
    String filename,
    List<int> sizes,
    int fileSize,
  ) {
    // Also generate a preview using the largest size PNG
    return '''# 🎯 PNG to ICO Conversion Complete

## 🖼️ **Preview**
```ico
$icoBase64
```

## 📊 **Conversion Details**
- **Filename**: `$filename`
- **Icon Sizes**: ${sizes.join(', ')} pixels
- **File Size**: ${(fileSize / 1024).toStringAsFixed(1)} KB
- **Format**: Microsoft ICO (Windows Icon)

## 💾 **Download Your ICO File**

**Method 1: Direct Download Link**
```html
<a href="data:image/x-icon;base64,$icoBase64" download="$filename">Download $filename</a>
```

**Method 2: Base64 Data** (Copy and save as .ico file)
```
$icoBase64
```

**Method 3: Data URL** (Use in HTML or CSS)
```
data:image/x-icon;base64,$icoBase64
```

## 🔧 **Usage Examples**

**HTML Favicon**
```html
<link rel="icon" type="image/x-icon" href="$filename">
<link rel="shortcut icon" type="image/x-icon" href="$filename">
```

**CSS Background**
```css
.icon {
    background-image: url('data:image/x-icon;base64,$icoBase64');
}
```

## ℹ️ **Technical Info**
- Contains ${sizes.length} embedded icon${sizes.length > 1 ? 's' : ''} at different resolutions
- Compatible with Windows, web browsers, and most applications
- 32-bit RGBA PNG data preserved for transparency support

---
*Generated with PNG to ICO Converter Tool*''';
  }

  @override
  Future<String> executeGetText(String input) async {
    ToolResult result = await execute(input);
    if (result.status == 'success') {
      return 'ICO file generated successfully. File size: ${_getFileSizeFromOutput(result.output)}';
    } else {
      return result.output.replaceAll(RegExp(r'\*\*|❌|#'), '').trim();
    }
  }

  String _getFileSizeFromOutput(String output) {
    RegExp sizeRegex = RegExp(r'File Size\*\*: ([^\n]+)');
    Match? match = sizeRegex.firstMatch(output);
    return match?.group(1) ?? 'Unknown';
  }
}

class ColorPaletteGenerator extends Tool {
  ColorPaletteGenerator()
    : super(
        name: 'Color Palette Generator',
        description:
            'Generate harmonious color palettes with live previews and export formats',
        icon: Icons.palette,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        supportsStreaming: false,
        allowEmptyInput: true,
        settings: {
          'base_color': '#3498db',
          'palette_type': 'Complementary',
          'color_count': 5,
          'include_preview': true,
          'export_format': 'All Formats',
          'brightness_variation': 20,
          'saturation_variation': 15,
          'include_shades': true,
          'color_space': 'HSL',
        },
        settingsHints: {
          'base_color': {
            'type': 'color',
            'label': 'Base Color',
            'help': 'Starting color for palette generation',
            'alpha': false,
            'presets': true,
          },
          'palette_type': {
            'type': 'dropdown',
            'label': 'Palette Type',
            'help': 'Color harmony scheme to generate',
            'options': [
              'Monochromatic',
              'Analogous',
              'Complementary',
              'Triadic',
              'Tetradic',
              'Split-Complementary',
              'Custom Harmony',
            ],
          },
          'color_count': {
            'type': 'spinner',
            'label': 'Number of Colors',
            'help': 'How many colors to generate',
            'min': 2,
            'max': 12,
            'step': 1,
          },
          'include_preview': {
            'type': 'bool',
            'label': 'Visual Preview',
            'help': 'Show color swatches using SVG',
          },
          'export_format': {
            'type': 'dropdown',
            'label': 'Export Formats',
            'help': 'Which color formats to include',
            'options': [
              'All Formats',
              'Hex Only',
              'RGB Only',
              'HSL Only',
              'CSS Variables',
              'Design Tokens',
            ],
          },
          'brightness_variation': {
            'type': 'slider',
            'label': 'Brightness Variation',
            'help': 'How much to vary lightness (0-50%)',
            'min': 0.0,
            'max': 50.0,
            'divisions': 50,
            'show_value': true,
          },
          'saturation_variation': {
            'type': 'slider',
            'label': 'Saturation Variation',
            'help': 'How much to vary saturation (0-30%)',
            'min': 0.0,
            'max': 30.0,
            'divisions': 30,
            'show_value': true,
          },
          'include_shades': {
            'type': 'bool',
            'label': 'Include Shades & Tints',
            'help': 'Generate lighter and darker variations',
          },
          'color_space': {
            'type': 'dropdown',
            'label': 'Color Space',
            'help': 'Color space for calculations',
            'options': ['HSL', 'HSV', 'LAB'],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      final baseColor = input.trim().isEmpty
          ? (settings['base_color'] as String)
          : input.trim();

      final palette = await _generatePalette(baseColor);
      final output = _formatOutput(palette);

      return ToolResult(output: output, status: 'success');
    } catch (e) {
      return ToolResult(
        output: 'Error generating palette: $e',
        status: 'error',
      );
    }
  }

  Future<ColorPalette> _generatePalette(String baseColor) async {
    final hsl = _parseColor(baseColor);
    final paletteType = settings['palette_type'] as String;
    final colorCount = settings['color_count'] as int;
    final brightnessVar =
        (settings['brightness_variation'] as num).toDouble() / 100.0;
    final saturationVar =
        (settings['saturation_variation'] as num).toDouble() / 100.0;
    final includeShades = settings['include_shades'] as bool;

    List<HSLColor> colors = [];

    switch (paletteType) {
      case 'Monochromatic':
        colors = _generateMonochromatic(hsl, colorCount, brightnessVar);
        break;
      case 'Analogous':
        colors = _generateAnalogous(hsl, colorCount, saturationVar);
        break;
      case 'Complementary':
        colors = _generateComplementary(hsl, colorCount);
        break;
      case 'Triadic':
        colors = _generateTriadic(hsl);
        break;
      case 'Tetradic':
        colors = _generateTetradic(hsl);
        break;
      case 'Split-Complementary':
        colors = _generateSplitComplementary(hsl);
        break;
      case 'Custom Harmony':
        colors = _generateCustomHarmony(hsl, colorCount);
        break;
    }

    if (includeShades && colors.isNotEmpty) {
      colors = _addShadesAndTints(colors);
    }

    return ColorPalette(baseColor: hsl, colors: colors, type: paletteType);
  }

  HSLColor _parseColor(String colorStr) {
    colorStr = colorStr.trim().toLowerCase();

    // Handle hex colors
    if (colorStr.startsWith('#')) {
      return _hexToHSL(colorStr);
    }

    // Handle rgb colors
    if (colorStr.startsWith('rgb')) {
      return _rgbToHSL(colorStr);
    }

    // Handle hsl colors
    if (colorStr.startsWith('hsl')) {
      return _parseHSL(colorStr);
    }

    // Handle named colors
    final namedColors = {
      'red': '#ff0000',
      'green': '#008000',
      'blue': '#0000ff',
      'yellow': '#ffff00',
      'cyan': '#00ffff',
      'magenta': '#ff00ff',
      'orange': '#ffa500',
      'purple': '#800080',
      'pink': '#ffc0cb',
      'brown': '#a52a2a',
      'black': '#000000',
      'white': '#ffffff',
      'gray': '#808080',
      'grey': '#808080',
    };

    if (namedColors.containsKey(colorStr)) {
      return _hexToHSL(namedColors[colorStr]!);
    }

    // Default fallback
    return _hexToHSL('#3498db');
  }

  HSLColor _hexToHSL(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((c) => c + c).join('');
    }

    final r = int.parse(hex.substring(0, 2), radix: 16) / 255;
    final g = int.parse(hex.substring(2, 4), radix: 16) / 255;
    final b = int.parse(hex.substring(4, 6), radix: 16) / 255;

    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final diff = max - min;
    final sum = max + min;

    final l = sum / 2;

    if (diff == 0) {
      return HSLColor(0, 0, l);
    }

    final s = l < 0.5 ? diff / sum : diff / (2 - sum);

    double h = 0;
    if (max == r) {
      h = ((g - b) / diff) + (g < b ? 6 : 0);
    } else if (max == g) {
      h = (b - r) / diff + 2;
    } else {
      h = (r - g) / diff + 4;
    }
    h /= 6;

    return HSLColor(h, s, l);
  }

  HSLColor _rgbToHSL(String rgb) {
    final match = RegExp(
      r'rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)',
    ).firstMatch(rgb);
    if (match != null) {
      final r = int.parse(match.group(1)!) / 255;
      final g = int.parse(match.group(2)!) / 255;
      final b = int.parse(match.group(3)!) / 255;
      return _hexToHSL(
        '#${((r * 255).round().toRadixString(16).padLeft(2, '0'))}'
        '${((g * 255).round().toRadixString(16).padLeft(2, '0'))}'
        '${((b * 255).round().toRadixString(16).padLeft(2, '0'))}',
      );
    }
    return _hexToHSL('#3498db');
  }

  HSLColor _parseHSL(String hsl) {
    final match = RegExp(
      r'hsl\s*\(\s*(\d+)\s*,\s*(\d+)%?\s*,\s*(\d+)%?\s*\)',
    ).firstMatch(hsl);
    if (match != null) {
      final h = int.parse(match.group(1)!) / 360;
      final s = int.parse(match.group(2)!) / 100;
      final l = int.parse(match.group(3)!) / 100;
      return HSLColor(h, s, l);
    }
    return _hexToHSL('#3498db');
  }

  List<HSLColor> _generateMonochromatic(
    HSLColor base,
    int count,
    double variation,
  ) {
    List<HSLColor> colors = [base];

    for (int i = 1; i < count; i++) {
      final factor = (i / (count - 1) - 0.5) * 2; // -1 to 1
      final newL = (base.l + factor * variation).clamp(0.1, 0.9);
      colors.add(HSLColor(base.h, base.s, newL));
    }

    return colors;
  }

  List<HSLColor> _generateAnalogous(
    HSLColor base,
    int count,
    double variation,
  ) {
    List<HSLColor> colors = [base];
    final step = 30 / 360; // 30 degrees

    for (int i = 1; i < count; i++) {
      final angle = i % 2 == 1 ? step * ((i + 1) ~/ 2) : -step * (i ~/ 2);
      final newH = (base.h + angle) % 1;
      final newS = (base.s + (math.Random().nextDouble() - 0.5) * variation)
          .clamp(0.2, 1.0);
      colors.add(HSLColor(newH, newS, base.l));
    }

    return colors;
  }

  List<HSLColor> _generateComplementary(HSLColor base, int count) {
    List<HSLColor> colors = [base];

    // Add complementary color
    final compH = (base.h + 0.5) % 1;
    colors.add(HSLColor(compH, base.s, base.l));

    // Fill remaining with variations
    for (int i = 2; i < count; i++) {
      final useBase = i % 2 == 0;
      final sourceH = useBase ? base.h : compH;
      final variation = (i ~/ 2) * 0.1;
      final newL = useBase
          ? (base.l + variation).clamp(0.1, 0.9)
          : (base.l - variation).clamp(0.1, 0.9);
      colors.add(HSLColor(sourceH, base.s, newL));
    }

    return colors;
  }

  List<HSLColor> _generateTriadic(HSLColor base) {
    return [
      base,
      HSLColor((base.h + 1 / 3) % 1, base.s, base.l),
      HSLColor((base.h + 2 / 3) % 1, base.s, base.l),
    ];
  }

  List<HSLColor> _generateTetradic(HSLColor base) {
    return [
      base,
      HSLColor((base.h + 0.25) % 1, base.s, base.l),
      HSLColor((base.h + 0.5) % 1, base.s, base.l),
      HSLColor((base.h + 0.75) % 1, base.s, base.l),
    ];
  }

  List<HSLColor> _generateSplitComplementary(HSLColor base) {
    return [
      base,
      HSLColor((base.h + 5 / 12) % 1, base.s, base.l), // 150 degrees
      HSLColor((base.h + 7 / 12) % 1, base.s, base.l), // 210 degrees
    ];
  }

  List<HSLColor> _generateCustomHarmony(HSLColor base, int count) {
    List<HSLColor> colors = [base];
    final goldenRatio = (1 + math.sqrt(5)) / 2;

    for (int i = 1; i < count; i++) {
      final newH = (base.h + i / goldenRatio) % 1;
      final newS = (base.s + math.sin(i * math.pi / 4) * 0.2).clamp(0.2, 1.0);
      final newL = (base.l + math.cos(i * math.pi / 3) * 0.2).clamp(0.2, 0.8);
      colors.add(HSLColor(newH, newS, newL));
    }

    return colors;
  }

  List<HSLColor> _addShadesAndTints(List<HSLColor> baseColors) {
    List<HSLColor> extended = [];

    for (final color in baseColors) {
      // Add tint (lighter)
      extended.add(HSLColor(color.h, color.s, math.min(0.9, color.l + 0.2)));
      // Add original
      extended.add(color);
      // Add shade (darker)
      extended.add(HSLColor(color.h, color.s, math.max(0.1, color.l - 0.2)));
    }

    return extended;
  }

  String _formatOutput(ColorPalette palette) {
    final buffer = StringBuffer();
    final includePreview = settings['include_preview'] as bool;
    final exportFormat = settings['export_format'] as String;

    // Title
    buffer.writeln('# ${palette.type} Color Palette');
    buffer.writeln();

    // Add palette type description
    switch (palette.type) {
      case 'Monochromatic':
        buffer.writeln(
          'A monochromatic color scheme uses variations of a single color, creating a cohesive and sophisticated look. This palette works well for minimalist designs and helps establish visual hierarchy through varying shades and tints.',
        );
        break;
      case 'Analogous':
        buffer.writeln(
          'Analogous colors are next to each other on the color wheel. This harmony creates a serene and comfortable design that works well for natural-looking interfaces and designs that need to maintain low tension.',
        );
        break;
      case 'Complementary':
        buffer.writeln(
          'Complementary colors are opposite each other on the color wheel. This creates a high-contrast, vibrant look that\'s perfect for making specific elements stand out. Use sparingly to avoid overwhelming the design.',
        );
        break;
      case 'Triadic':
        buffer.writeln(
          'Triadic color schemes use three colors equally spaced around the color wheel. This creates a balanced and harmonious look while maintaining a high degree of contrast. Perfect for playful and dynamic designs.',
        );
        break;
      case 'Tetradic':
        buffer.writeln(
          'Tetradic (double complementary) schemes use four colors arranged into two complementary pairs. This rich color scheme offers many possibilities but can be overwhelming if not balanced properly.',
        );
        break;
      case 'Split-Complementary':
        buffer.writeln(
          'Split-complementary schemes use a base color and two colors adjacent to its complement. This provides high contrast while being more versatile than complementary schemes and easier to balance.',
        );
        break;
      case 'Custom Harmony':
        buffer.writeln(
          'A custom harmony uses mathematical relationships to create unique and interesting color combinations. This can result in unexpected but visually pleasing color relationships.',
        );
        break;
    }
    buffer.writeln();

    // Visual preview
    if (includePreview) {
      buffer.writeln(_generateSVGPreview(palette.colors));
      buffer.writeln();
    }

    // Base color info
    buffer.writeln('**Base Color:** ${_hslToHex(palette.baseColor)}');
    buffer.writeln('**Palette Type:** ${palette.type}');
    buffer.writeln('**Colors Generated:** ${palette.colors.length}');
    buffer.writeln();

    // Color list
    buffer.writeln('## Color Values');
    buffer.writeln();

    for (int i = 0; i < palette.colors.length; i++) {
      final color = palette.colors[i];
      buffer.writeln('### Color ${i + 1}');

      if (exportFormat == 'All Formats' || exportFormat == 'Hex Only') {
        buffer.writeln('- **Hex:** `${_hslToHex(color)}`');
      }

      if (exportFormat == 'All Formats' || exportFormat == 'RGB Only') {
        final rgb = _hslToRGB(color);
        buffer.writeln('- **RGB:** `rgb(${rgb[0]}, ${rgb[1]}, ${rgb[2]})`');
      }

      if (exportFormat == 'All Formats' || exportFormat == 'HSL Only') {
        buffer.writeln(
          '- **HSL:** `hsl(${(color.h * 360).round()}, ${(color.s * 100).round()}%, ${(color.l * 100).round()}%)`',
        );
      }

      if (exportFormat == 'CSS Variables') {
        buffer.writeln('- **CSS:** `--color-${i + 1}: ${_hslToHex(color)};`');
      }

      if (exportFormat == 'Design Tokens') {
        buffer.writeln('```json');
        buffer.writeln('"color-${i + 1}": {');
        buffer.writeln('  "value": "${_hslToHex(color)}",');
        buffer.writeln('  "type": "color"');
        buffer.writeln('}');
        buffer.writeln('```');
      }

      buffer.writeln();
    }

    // Usage suggestions
    buffer.writeln('## Usage Suggestions');
    buffer.writeln();
    _addUsageSuggestions(buffer, palette);

    return buffer.toString();
  }

  String _generateSVGPreview(List<HSLColor> colors) {
    final swatchWidth = math.max(60, 600 ~/ colors.length);
    final width = colors.length * swatchWidth;

    final buffer = StringBuffer();
    buffer.writeln('```svg');
    buffer.writeln(
      '<svg width="$width" height="80" xmlns="http://www.w3.org/2000/svg">',
    );

    for (int i = 0; i < colors.length; i++) {
      final x = i * swatchWidth;
      final hex = _hslToHex(colors[i]);

      // Color swatch
      buffer.writeln(
        '  <rect x="$x" y="0" width="$swatchWidth" height="60" fill="$hex" stroke="#ddd" stroke-width="1"/>',
      );

      // Color label
      final textColor = colors[i].l > 0.5 ? '#000000' : '#ffffff';
      buffer.writeln(
        '  <text x="${x + swatchWidth / 2}" y="75" text-anchor="middle" font-family="monospace" font-size="10" fill="#333">${hex.toUpperCase()}</text>',
      );
    }

    buffer.writeln('</svg>');
    buffer.writeln('```');

    return buffer.toString();
  }

  void _addUsageSuggestions(StringBuffer buffer, ColorPalette palette) {
    switch (palette.type) {
      case 'Monochromatic':
        buffer.writeln('- Perfect for minimalist designs and creating depth');
        buffer.writeln('- Use lighter shades for backgrounds, darker for text');
        buffer.writeln('- Great for professional and elegant interfaces');
        break;
      case 'Complementary':
        buffer.writeln(
          '- High contrast - excellent for call-to-action buttons',
        );
        buffer.writeln('- Use sparingly to avoid visual tension');
        buffer.writeln('- Perfect for highlighting important elements');
        break;
      case 'Analogous':
        buffer.writeln('- Harmonious and pleasing to the eye');
        buffer.writeln('- Great for natural and organic designs');
        buffer.writeln('- Use one as dominant, others as accents');
        break;
      case 'Triadic':
        buffer.writeln('- Vibrant and balanced color scheme');
        buffer.writeln('- Use one as primary, others as accents');
        buffer.writeln('- Perfect for playful and energetic designs');
        break;
      default:
        buffer.writeln('- Experiment with different combinations');
        buffer.writeln('- Test contrast ratios for accessibility');
        buffer.writeln('- Consider your brand and target audience');
    }
  }

  String _hslToHex(HSLColor hsl) {
    final rgb = _hslToRGB(hsl);
    return '#${rgb[0].toRadixString(16).padLeft(2, '0')}'
        '${rgb[1].toRadixString(16).padLeft(2, '0')}'
        '${rgb[2].toRadixString(16).padLeft(2, '0')}';
  }

  List<int> _hslToRGB(HSLColor hsl) {
    final h = hsl.h;
    final s = hsl.s;
    final l = hsl.l;

    double r, g, b;

    if (s == 0) {
      r = g = b = l; // achromatic
    } else {
      final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      final p = 2 * l - q;
      r = _hue2rgb(p, q, h + 1 / 3);
      g = _hue2rgb(p, q, h);
      b = _hue2rgb(p, q, h - 1 / 3);
    }

    return [(r * 255).round(), (g * 255).round(), (b * 255).round()];
  }

  double _hue2rgb(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }
}

class ColorPalette {
  final HSLColor baseColor;
  final List<HSLColor> colors;
  final String type;

  ColorPalette({
    required this.baseColor,
    required this.colors,
    required this.type,
  });
}

class HSLColor {
  final double h; // 0-1
  final double s; // 0-1
  final double l; // 0-1

  HSLColor(this.h, this.s, this.l);
}

class NinePatchUITool extends Tool {
  NinePatchUITool()
    : super(
        name: '9-Patch UI Generator',
        description:
            'Generate styled 9-patch frames, buttons, panels and UI elements with beautiful color schemes and effects',
        icon: Icons.widgets,
        isOutputMarkdown: true,
        isInputMarkdown: false,
        canAcceptMarkdown: false,
        supportsLiveUpdate: true,
        allowEmptyInput: true, // Hide input box, use settings only
        settings: {
          'element_type': 'Button',
          'width': 200,
          'height': 60,
          'corner_radius': 12,
          'border_width': 2,
          'palette_type': 'Complementary',
          'base_color': '#3498db',
          'style': 'Modern',
          'add_text': true,
          'text_content': 'Click Me',
          'add_shadow': true,
          'add_gradient': true,
          'add_border': true,
          'shadow_blur': 4,
          'shadow_offset': 3,
          'patch_size': 20,
          'inner_padding': 10,
        },
        settingsHints: {
          'element_type': {
            'type': 'dropdown',
            'label': 'Element Type',
            'help': 'Type of UI element to generate',
            'options': [
              'Button',
              'Panel',
              'Frame',
              'Dialog Box',
              'Progress Bar',
              'Input Field',
              'Card',
              'Badge',
              'Tab',
            ],
          },
          'width': {
            'type': 'spinner',
            'label': 'Width',
            'help': 'Element width in pixels',
            'min': 50,
            'max': 500,
            'step': 10,
          },
          'height': {
            'type': 'spinner',
            'label': 'Height',
            'help': 'Element height in pixels',
            'min': 20,
            'max': 300,
            'step': 10,
          },
          'corner_radius': {
            'type': 'spinner',
            'label': 'Corner Radius',
            'help': 'Rounded corner radius',
            'min': 0,
            'max': 50,
            'step': 2,
          },
          'border_width': {
            'type': 'spinner',
            'label': 'Border Width',
            'help': 'Border thickness in pixels',
            'min': 0,
            'max': 10,
            'step': 1,
          },
          'palette_type': {
            'type': 'dropdown',
            'label': 'Color Palette',
            'help': 'Color harmony scheme for the element',
            'options': [
              'Monochromatic',
              'Analogous',
              'Complementary',
              'Triadic',
              'Material Design',
              'Pastel',
              'Dark Theme',
              'Gaming',
            ],
          },
          'base_color': {
            'type': 'color',
            'label': 'Base Color',
            'help': 'Primary color for the element',
            'alpha': false,
            'presets': true,
          },
          'style': {
            'type': 'dropdown',
            'label': 'Style',
            'help': 'Visual style theme',
            'options': [
              'Modern',
              'Flat',
              'Raised',
              'Inset',
              'Outlined',
              'Glass',
              'Neon',
              'Retro',
            ],
          },
          'add_text': {
            'type': 'bool',
            'label': 'Add Text',
            'help': 'Include text content in the element',
          },
          'text_content': {
            'type': 'text',
            'label': 'Text Content',
            'help': 'Text to display in the element',
            'placeholder': 'Enter text...',
          },
          'add_shadow': {
            'type': 'bool',
            'label': 'Drop Shadow',
            'help': 'Add drop shadow effect',
          },
          'shadow_blur': {
            'type': 'spinner',
            'label': 'Shadow Blur',
            'help': 'Shadow blur radius',
            'min': 1,
            'max': 20,
            'step': 1,
          },
          'shadow_offset': {
            'type': 'spinner',
            'label': 'Shadow Offset',
            'help': 'Shadow offset distance',
            'min': 0,
            'max': 20,
            'step': 1,
          },
          'add_gradient': {
            'type': 'bool',
            'label': 'Gradient Fill',
            'help': 'Use gradient instead of solid color',
          },
          'add_border': {
            'type': 'bool',
            'label': 'Border',
            'help': 'Add border around element',
          },
          'patch_size': {
            'type': 'spinner',
            'label': '9-Patch Size',
            'help': 'Size of corner patches for 9-patch scaling',
            'min': 10,
            'max': 50,
            'step': 2,
          },
          'inner_padding': {
            'type': 'spinner',
            'label': 'Inner Padding',
            'help': 'Internal padding for content',
            'min': 5,
            'max': 30,
            'step': 5,
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    final elementType = settings['element_type'] as String;
    final width = settings['width'] as int;
    final height = settings['height'] as int;
    final cornerRadius = settings['corner_radius'] as int;
    final borderWidth = settings['border_width'] as int;
    final paletteType = settings['palette_type'] as String;
    final baseColor = settings['base_color'] as String;
    final style = settings['style'] as String;
    final addText = settings['add_text'] as bool;
    final textContent = settings['text_content'] as String;
    final addShadow = settings['add_shadow'] as bool;
    final shadowBlur = settings['shadow_blur'] as int;
    final shadowOffset = settings['shadow_offset'] as int;
    final addGradient = settings['add_gradient'] as bool;
    final addBorder = settings['add_border'] as bool;
    final patchSize = settings['patch_size'] as int;
    final innerPadding = settings['inner_padding'] as int;

    // Generate color palette
    final palette = generateColorPalette(baseColor, paletteType);

    // Generate SVG based on element type and style
    final svg = generateUIElementSVG(
      elementType: elementType,
      width: width,
      height: height,
      cornerRadius: cornerRadius,
      borderWidth: borderWidth,
      palette: palette,
      style: style,
      addText: addText,
      textContent: textContent,
      addShadow: addShadow,
      shadowBlur: shadowBlur,
      shadowOffset: shadowOffset,
      addGradient: addGradient,
      addBorder: addBorder,
      patchSize: patchSize,
      innerPadding: innerPadding,
    );

    final result =
        '''# $elementType - $style Style

**Dimensions:** ${width}x${height}px  
**Style:** $style  
**Palette:** $paletteType  
**Effects:** ${_getActiveEffects(addGradient, addShadow, addBorder, style)}

## Generated UI Element

```svg
$svg
```

## Color Palette Used
${palette.entries.map((e) => '- **${e.key}:** `${e.value}`').join('\n')}

## 9-Patch Information
- **Patch Size:** ${patchSize}px corners
- **Scalable Area:** Center region stretches
- **Fixed Regions:** Corners maintain aspect ratio
- **Content Padding:** ${innerPadding}px

## Usage Notes
- Red lines indicate 9-patch boundaries
- Corners (${patchSize}x${patchSize}px) stay fixed when scaling
- Center area stretches for responsive layouts
- Content area has ${innerPadding}px padding for text/elements
''';

    return ToolResult(output: result, status: 'success');
  }

  String _getActiveEffects(
    bool gradient,
    bool shadow,
    bool border,
    String style,
  ) {
    List<String> effects = [];
    if (gradient) effects.add('Gradient');
    if (shadow) effects.add('Shadow');
    if (border) effects.add('Border');
    if (style == 'Glass') effects.add('Glass');
    if (style == 'Neon') effects.add('Neon');
    if (style == 'Raised') effects.add('3D Raised');
    if (style == 'Inset') effects.add('3D Inset');
    return effects.isEmpty ? 'None' : effects.join(', ');
  }

  Map<String, String> generateColorPalette(
    String baseColor,
    String paletteType,
  ) {
    final base = hexToHsl(baseColor);
    Map<String, String> palette = {};

    switch (paletteType) {
      case 'Monochromatic':
        palette = {
          'primary': baseColor,
          'light': hslToHex(base[0], base[1] * 0.7, min(base[2] + 0.3, 0.95)),
          'dark': hslToHex(base[0], base[1], max(base[2] - 0.3, 0.1)),
          'accent': hslToHex(base[0], base[1] * 1.2, base[2]),
          'surface': '#ffffff',
          'text': '#333333',
        };
        break;

      case 'Complementary':
        palette = {
          'primary': baseColor,
          'secondary': hslToHex((base[0] + 180) % 360, base[1], base[2]),
          'light': hslToHex(base[0], base[1] * 0.6, min(base[2] + 0.4, 0.95)),
          'dark': hslToHex(base[0], base[1], max(base[2] - 0.4, 0.1)),
          'surface': '#ffffff',
          'text': base[2] > 0.5 ? '#ffffff' : '#333333',
        };
        break;

      case 'Material Design':
        palette = {
          'primary': baseColor,
          'primaryLight': hslToHex(
            base[0],
            base[1] * 0.8,
            min(base[2] + 0.2, 0.9),
          ),
          'primaryDark': hslToHex(base[0], base[1], max(base[2] - 0.2, 0.1)),
          'surface': '#ffffff',
          'background': '#fafafa',
          'text': '#212121',
        };
        break;

      case 'Dark Theme':
        palette = {
          'primary': baseColor,
          'surface': '#2e2e2e',
          'background': '#1a1a1a',
          'light': hslToHex(base[0], base[1], min(base[2] + 0.2, 0.8)),
          'dark': hslToHex(base[0], base[1], max(base[2] - 0.2, 0.2)),
          'text': '#ffffff',
        };
        break;

      case 'Gaming':
        palette = {
          'primary': baseColor,
          'neon': hslToHex(base[0], 1.0, 0.6),
          'glow': hslToHex(base[0], 0.8, 0.8),
          'dark': '#0a0a0a',
          'surface': '#1a1a1a',
          'text': '#00ff00',
        };
        break;

      case 'Pastel':
        palette = {
          'primary': hslToHex(base[0], base[1] * 0.5, min(base[2] + 0.3, 0.85)),
          'light': hslToHex(base[0], base[1] * 0.3, min(base[2] + 0.4, 0.95)),
          'surface': '#fefefe',
          'background': '#f8f8f8',
          'text': '#555555',
          'accent': hslToHex((base[0] + 30) % 360, base[1] * 0.4, 0.8),
        };
        break;

      default: // Analogous, Triadic
        palette = {
          'primary': baseColor,
          'secondary': hslToHex((base[0] + 60) % 360, base[1], base[2]),
          'tertiary': hslToHex((base[0] - 60 + 360) % 360, base[1], base[2]),
          'light': hslToHex(base[0], base[1] * 0.7, min(base[2] + 0.3, 0.9)),
          'dark': hslToHex(base[0], base[1], max(base[2] - 0.3, 0.1)),
          'text': base[2] > 0.5 ? '#ffffff' : '#333333',
        };
    }

    return palette;
  }

  String generateUIElementSVG({
    required String elementType,
    required int width,
    required int height,
    required int cornerRadius,
    required int borderWidth,
    required Map<String, String> palette,
    required String style,
    required bool addText,
    required String textContent,
    required bool addShadow,
    required int shadowBlur,
    required int shadowOffset,
    required bool addGradient,
    required bool addBorder,
    required int patchSize,
    required int innerPadding,
  }) {
    final List<String> defs = [];
    final List<String> elements = [];

    // Create filter effects that work in Flutter SVG
    if (addShadow) {
      defs.add('''
  <defs>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="$shadowOffset" dy="$shadowOffset" stdDeviation="$shadowBlur" flood-opacity="0.3"/>
    </filter>
  </defs>''');
    }

    // Generate gradients
    if (addGradient) {
      final gradientDef = _createGradient(palette, style);
      if (gradientDef.isNotEmpty) {
        if (defs.isEmpty) defs.add('<defs>');
        defs[0] = defs[0].replaceAll('</defs>', '$gradientDef\n  </defs>');
        if (defs[0] == '<defs>') defs[0] = '<defs>\n$gradientDef\n  </defs>';
      }
    }

    // Get colors and fill
    final fillColor = _getFillColor(palette, style, addGradient);
    final strokeColor = _getStrokeColor(palette, style);
    final textColor = _getTextColor(palette, style);

    // Generate main element shape based on type
    final mainElement = _createMainElement(
      elementType,
      width,
      height,
      cornerRadius,
      borderWidth,
      fillColor,
      strokeColor,
      style,
      addBorder,
      addShadow,
      innerPadding,
      palette,
    );
    elements.add(mainElement);

    // Add special effects based on style
    elements.addAll(
      _createStyleEffects(style, width, height, cornerRadius, palette),
    );

    // Add text if enabled
    if (addText && textContent.isNotEmpty) {
      final textElement = _createTextElement(
        textContent,
        width,
        height,
        textColor,
        style,
        innerPadding,
      );
      elements.add(textElement);
    }

    // Add 9-patch guides
    elements.add(_create9PatchGuides(width, height, patchSize));

    // Combine all elements
    final svgContent = [
      if (defs.isNotEmpty) defs.join('\n'),
      elements.join('\n'),
    ].join('\n');

    return '<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">\n$svgContent\n</svg>';
  }

  String _createGradient(Map<String, String> palette, String style) {
    switch (style) {
      case 'Modern':
      case 'Raised':
        return '''    <linearGradient id="mainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="${palette['light'] ?? palette['primary']}" stop-opacity="1" />
      <stop offset="100%" stop-color="${palette['dark'] ?? palette['primary']}" stop-opacity="1" />
    </linearGradient>''';

      case 'Inset':
        return '''    <linearGradient id="mainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="${palette['dark'] ?? palette['primary']}" stop-opacity="1" />
      <stop offset="100%" stop-color="${palette['light'] ?? palette['primary']}" stop-opacity="1" />
    </linearGradient>''';

      case 'Glass':
        return '''    <linearGradient id="mainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="${palette['primary']}" stop-opacity="0.3" />
      <stop offset="100%" stop-color="${palette['primary']}" stop-opacity="0.1" />
    </linearGradient>''';

      case 'Neon':
        return '''    <linearGradient id="mainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="${palette['neon'] ?? palette['primary']}" stop-opacity="0.8" />
      <stop offset="100%" stop-color="${palette['primary']}" stop-opacity="0.6" />
    </linearGradient>''';

      default:
        return '''    <linearGradient id="mainGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="${palette['light'] ?? palette['primary']}" stop-opacity="1" />
      <stop offset="100%" stop-color="${palette['primary']}" stop-opacity="1" />
    </linearGradient>''';
    }
  }

  String _getFillColor(
    Map<String, String> palette,
    String style,
    bool addGradient,
  ) {
    if (addGradient) return 'url(#mainGradient)';

    switch (style) {
      case 'Glass':
        return palette['primary'] ?? '#3498db';
      case 'Neon':
        return palette['neon'] ?? palette['primary'] ?? '#3498db';
      case 'Dark Theme':
        return palette['surface'] ?? '#2e2e2e';
      default:
        return palette['primary'] ?? '#3498db';
    }
  }

  String _getStrokeColor(Map<String, String> palette, String style) {
    switch (style) {
      case 'Neon':
        return palette['neon'] ?? palette['primary'] ?? '#3498db';
      case 'Glass':
        return palette['light'] ?? palette['primary'] ?? '#3498db';
      case 'Outlined':
        return palette['primary'] ?? '#3498db';
      default:
        return palette['dark'] ?? '#2c3e50';
    }
  }

  String _getTextColor(Map<String, String> palette, String style) {
    switch (style) {
      case 'Neon':
      case 'Gaming':
        return palette['text'] ?? '#00ff00';
      case 'Glass':
        return palette['text'] ?? '#333333';
      case 'Dark Theme':
        return palette['text'] ?? '#ffffff';
      default:
        return _getContrastColor(palette['primary'] ?? '#3498db');
    }
  }

  String _createMainElement(
    String elementType,
    int width,
    int height,
    int cornerRadius,
    int borderWidth,
    String fillColor,
    String strokeColor,
    String style,
    bool addBorder,
    bool addShadow,
    int innerPadding,
    Map<String, String> palette,
  ) {
    final filters = addShadow ? 'filter="url(#shadow)"' : '';
    final stroke = addBorder
        ? 'stroke="$strokeColor" stroke-width="$borderWidth"'
        : '';

    switch (elementType.toLowerCase()) {
      case 'button':
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="$fillColor" $stroke $filters/>''';

      case 'panel':
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="${style == 'Glass' ? 'rgba(255,255,255,0.1)' : fillColor}" 
        stroke="${palette['dark'] ?? strokeColor}" stroke-width="${borderWidth.clamp(1, 3)}" $filters/>''';

      case 'frame':
        final frameWidth = borderWidth.clamp(2, 8);
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="none" stroke="$strokeColor" stroke-width="$frameWidth" $filters/>
  <rect x="$frameWidth" y="$frameWidth" width="${width - frameWidth * 2}" height="${height - frameWidth * 2}" 
        rx="${(cornerRadius - frameWidth).clamp(0, cornerRadius)}" ry="${(cornerRadius - frameWidth).clamp(0, cornerRadius)}" 
        fill="${palette['surface'] ?? '#ffffff'}"/>''';

      case 'dialog box':
        final titleHeight = 30;
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="${palette['surface'] ?? '#ffffff'}" stroke="$strokeColor" stroke-width="2" $filters/>
  <rect x="0" y="0" width="$width" height="$titleHeight" 
        rx="$cornerRadius" ry="0" 
        fill="$fillColor"/>''';

      case 'progress bar':
        final progressWidth = (width * 0.6).round();
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="${palette['surface'] ?? '#e0e0e0'}" stroke="$strokeColor" stroke-width="1" $filters/>
  <rect x="2" y="2" width="$progressWidth" height="${height - 4}" 
        rx="${(cornerRadius - 2).clamp(0, cornerRadius)}" ry="${(cornerRadius - 2).clamp(0, cornerRadius)}" 
        fill="$fillColor"/>''';

      case 'input field':
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="${palette['surface'] ?? '#ffffff'}" 
        stroke="$strokeColor" stroke-width="$borderWidth" $filters/>''';

      case 'card':
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="${palette['surface'] ?? '#ffffff'}" 
        stroke="${palette['light'] ?? '#e0e0e0'}" stroke-width="1" $filters/>''';

      case 'badge':
        return '''  <ellipse cx="${width / 2}" cy="${height / 2}" rx="${width / 2}" ry="${height / 2}" 
        fill="$fillColor" $stroke $filters/>''';

      case 'tab':
        return '''  <path d="M 0 $height L 0 $cornerRadius Q 0 0 $cornerRadius 0 L ${width - cornerRadius} 0 Q $width 0 $width $cornerRadius L $width $height Z" 
        fill="$fillColor" $stroke $filters/>''';

      default:
        return '''  <rect x="0" y="0" width="$width" height="$height" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="$fillColor" $stroke $filters/>''';
    }
  }

  List<String> _createStyleEffects(
    String style,
    int width,
    int height,
    int cornerRadius,
    Map<String, String> palette,
  ) {
    List<String> effects = [];

    switch (style) {
      case 'Glass':
        effects.add(
          '''  <rect x="0" y="0" width="$width" height="${height / 2}" 
        rx="$cornerRadius" ry="$cornerRadius" 
        fill="rgba(255,255,255,0.2)"/>''',
        );
        break;

      case 'Neon':
        effects.add(
          '''  <rect x="-2" y="-2" width="${width + 4}" height="${height + 4}" 
        rx="${cornerRadius + 2}" ry="${cornerRadius + 2}" 
        fill="none" stroke="${palette['neon'] ?? palette['primary']}" stroke-width="2" opacity="0.5"/>''',
        );
        break;

      case 'Raised':
        effects.add(
          '''  <line x1="$cornerRadius" y1="1" x2="${width - cornerRadius}" y2="1" 
        stroke="rgba(255,255,255,0.6)" stroke-width="1"/>
  <line x1="1" y1="$cornerRadius" x2="1" y2="${height - cornerRadius}" 
        stroke="rgba(255,255,255,0.4)" stroke-width="1"/>''',
        );
        break;

      case 'Inset':
        effects.add(
          '''  <line x1="$cornerRadius" y1="${height - 1}" x2="${width - cornerRadius}" y2="${height - 1}" 
        stroke="rgba(255,255,255,0.6)" stroke-width="1"/>
  <line x1="${width - 1}" y1="$cornerRadius" x2="${width - 1}" y2="${height - cornerRadius}" 
        stroke="rgba(255,255,255,0.4)" stroke-width="1"/>''',
        );
        break;
    }

    return effects;
  }

  String _createTextElement(
    String text,
    int width,
    int height,
    String textColor,
    String style,
    int innerPadding,
  ) {
    final fontSize = _calculateFontSize(width, height, text.length);
    final fontWeight = style == 'Modern' ? 'bold' : 'normal';
    final fontFamily = style == 'Retro'
        ? 'monospace'
        : (style == 'Gaming' ? 'Arial Black' : 'Arial, sans-serif');

    return '''  <text x="${width / 2}" y="${height / 2 + fontSize / 3}" 
        text-anchor="middle" 
        font-family="$fontFamily" 
        font-size="$fontSize" 
        font-weight="$fontWeight"
        fill="$textColor">$text</text>''';
  }

  int _calculateFontSize(int width, int height, int textLength) {
    final maxFontSize = (height * 0.4).clamp(10.0, 24.0);
    final widthBasedSize = (width / textLength * 0.8).clamp(8.0, maxFontSize);
    return widthBasedSize.round();
  }

  String _create9PatchGuides(int width, int height, int patchSize) {
    return '''  <!-- 9-Patch guides -->
  <line x1="$patchSize" y1="0" x2="${width - patchSize}" y2="0" stroke="#ff0000" stroke-width="1" opacity="0.4"/>
  <line x1="0" y1="$patchSize" x2="0" y2="${height - patchSize}" stroke="#ff0000" stroke-width="1" opacity="0.4"/>
  <line x1="$patchSize" y1="$height" x2="${width - patchSize}" y2="$height" stroke="#ff0000" stroke-width="1" opacity="0.4"/>
  <line x1="$width" y1="$patchSize" x2="$width" y2="${height - patchSize}" stroke="#ff0000" stroke-width="1" opacity="0.4"/>''';
  }

  // Utility functions for color manipulation
  List<double> hexToHsl(String hex) {
    hex = hex.replaceAll('#', '');
    int r = int.parse(hex.substring(0, 2), radix: 16);
    int g = int.parse(hex.substring(2, 4), radix: 16);
    int b = int.parse(hex.substring(4, 6), radix: 16);

    double rNorm = r / 255.0;
    double gNorm = g / 255.0;
    double bNorm = b / 255.0;

    double max = [rNorm, gNorm, bNorm].reduce((a, b) => a > b ? a : b);
    double min = [rNorm, gNorm, bNorm].reduce((a, b) => a < b ? a : b);

    double h, s, l = (max + min) / 2;

    if (max == min) {
      h = s = 0; // achromatic
    } else {
      double d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      switch (max) {
        case double x when x == rNorm:
          h = (gNorm - bNorm) / d + (gNorm < bNorm ? 6 : 0);
          break;
        case double x when x == gNorm:
          h = (bNorm - rNorm) / d + 2;
          break;
        case double x when x == bNorm:
          h = (rNorm - gNorm) / d + 4;
          break;
        default:
          h = 0;
      }
      h /= 6;
    }

    return [h * 360, s, l];
  }

  String hslToHex(double h, double s, double l) {
    h = h / 360;

    double hue2rgb(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    double r, g, b;

    if (s == 0) {
      r = g = b = l; // achromatic
    } else {
      double q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      double p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    int rInt = (r * 255).round();
    int gInt = (g * 255).round();
    int bInt = (b * 255).round();

    return '#${rInt.toRadixString(16).padLeft(2, '0')}${gInt.toRadixString(16).padLeft(2, '0')}${bInt.toRadixString(16).padLeft(2, '0')}';
  }

  String _getContrastColor(String hexColor) {
    // Simple contrast calculation - return white or black based on luminance
    hexColor = hexColor.replaceAll('#', '');
    int r = int.parse(hexColor.substring(0, 2), radix: 16);
    int g = int.parse(hexColor.substring(2, 4), radix: 16);
    int b = int.parse(hexColor.substring(4, 6), radix: 16);

    double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5 ? '#000000' : '#ffffff';
  }
}

class ImageEditorTool extends Tool {
  ImageEditorTool()
    : super(
        name: 'Image Editor',
        description:
            'Resize, crop, adjust colors, and apply filters to images (base64 in/out)',
        icon: Icons.image,
        allowEmptyInput: false,
        isOutputMarkdown: true,
        settings: {
          'resize_mode': 'keep_aspect', // keep_aspect, stretch, cover
          'resize_width': 256,
          'resize_height': 256,
          'crop_enabled': false,
          'crop_x': 0,
          'crop_y': 0,
          'crop_width': 100,
          'crop_height': 100,
          'brightness': 1.0,
          'contrast': 1.0,
          'saturation': 1.0,
          'grayscale': false,
          'filter': 'none', // none, blur, sharpen, invert
        },
        settingsHints: {
          'resize_mode': {
            'type': 'dropdown',
            'label': 'Resize Mode',
            'options': ['keep_aspect', 'stretch', 'cover'],
          },
          'resize_width': {
            'type': 'number',
            'label': 'Width',
            'min': 1,
            'max': 4096,
          },
          'resize_height': {
            'type': 'number',
            'label': 'Height',
            'min': 1,
            'max': 4096,
          },
          'crop_enabled': {
            'type': 'bool',
            'label': 'Enable Crop',
            'help': 'Crop image using x,y,width,height',
          },
          'crop_x': {'type': 'number', 'label': 'Crop X', 'min': 0},
          'crop_y': {'type': 'number', 'label': 'Crop Y', 'min': 0},
          'crop_width': {'type': 'number', 'label': 'Crop Width', 'min': 1},
          'crop_height': {'type': 'number', 'label': 'Crop Height', 'min': 1},
          'brightness': {
            'type': 'slider',
            'label': 'Brightness',
            'min': 0.0,
            'max': 2.0,
            'divisions': 20,
          },
          'contrast': {
            'type': 'slider',
            'label': 'Contrast',
            'min': 0.0,
            'max': 2.0,
            'divisions': 20,
          },
          'saturation': {
            'type': 'slider',
            'label': 'Saturation',
            'min': 0.0,
            'max': 2.0,
            'divisions': 20,
          },
          'grayscale': {'type': 'bool', 'label': 'Grayscale'},
          'filter': {
            'type': 'dropdown',
            'label': 'Filter',
            'options': ['none', 'blur', 'sharpen', 'invert'],
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      // Decode base64
      final bytes = base64Decode(input.split(',').last);
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        return ToolResult(
          output: 'Error: Invalid image input',
          status: 'error',
        );
      }

      final origW = image.width;
      final origH = image.height;

      // Crop if enabled
      if (settings['crop_enabled'] == true) {
        int x = settings['crop_x'];
        int y = settings['crop_y'];
        int w = settings['crop_width'];
        int h = settings['crop_height'];
        image = img.copyCrop(image, x: x, y: y, width: w, height: h);
      }

      // Resize
      int targetW = settings['resize_width'];
      int targetH = settings['resize_height'];
      String mode = settings['resize_mode'];
      if (mode == 'keep_aspect') {
        image = img.copyResize(
          image,
          width: targetW,
          height: targetH,
          maintainAspect: true,
        );
      } else if (mode == 'stretch') {
        image = img.copyResize(
          image,
          width: targetW,
          height: targetH,
          maintainAspect: false,
        );
      } else if (mode == 'cover') {
        image = img.copyResizeCropSquare(
          image,
          size: targetW < targetH ? targetW : targetH,
        );
      }

      // Color adjustments
      double brightness = settings['brightness'];
      double contrast = settings['contrast'];
      double saturation = settings['saturation'];

      if (brightness != 1.0) {
        image = img.adjustColor(image, brightness: brightness);
      }
      if (contrast != 1.0) {
        image = img.adjustColor(image, contrast: contrast);
      }
      if (saturation != 1.0) {
        image = img.adjustColor(image, saturation: saturation);
      }
      if (settings['grayscale'] == true) {
        image = img.grayscale(image);
      }

      // Filters
      String filter = settings['filter'];
      if (filter == 'blur') {
        image = img.gaussianBlur(image, radius: 2);
      } else if (filter == 'sharpen') {
        // Apply sharpen using convolution kernel
        image = img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
      } else if (filter == 'invert') {
        image = img.invert(image);
      }

      final finalW = image.width;
      final finalH = image.height;

      // Encode back to base64
      final outBytes = img.encodePng(image);
      final resultBase64 = base64Encode(outBytes);

      // Markdown output with stats
      final md =
          '''
# 🖼️ Image Editor Result

**Original Size:** ${origW}x$origH  
**Final Size:** ${finalW}x$finalH  
**Resize Mode:** $mode  
**Brightness:** $brightness  
**Contrast:** $contrast  
**Saturation:** $saturation  
**Grayscale:** ${settings['grayscale']}  
**Filter:** $filter  

## Output Image
```png
data:image/png;base64,$resultBase64
```
''';
      return ToolResult(output: md, status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }
}

class PwaIconTool extends Tool {
  PwaIconTool()
    : super(
        name: 'PWA Icon Generator',
        description: 'Generate standard + maskable icons for Flutter Web PWAs',
        icon: Icons.android,
        allowEmptyInput: false,
        isOutputMarkdown: true,
        settings: {
          'sizes': '192,512', // text input, parse later
          'generate_maskable': true,
          'maskable_padding': 0.2, // 20% safe area
          'maskable_bg': 'transparent', // black | white | transparent
        },
        settingsHints: {
          'sizes': {
            'type': 'text',
            'label': 'Icon Sizes',
            'help': 'Comma-separated list of sizes (e.g. 192,512)',
          },
          'generate_maskable': {
            'type': 'bool',
            'label': 'Generate Maskable Icon',
          },
          'maskable_padding': {
            'type': 'slider',
            'label': 'Maskable Padding',
            'min': 0.0,
            'max': 0.5,
            'divisions': 10,
            'help': 'Extra safe area around logo (as % of size)',
          },
          'maskable_bg': {
            'type': 'dropdown',
            'label': 'Maskable Background',
            'options': ['transparent', 'black', 'white'],
            'help': 'Background color for maskable padding',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      final bytes = base64Decode(input.split(',').last);
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        return ToolResult(
          output: 'Error: Invalid image input',
          status: 'error',
        );
      }

      // Parse sizes
      final sizeText = settings['sizes'] as String;
      final sizes = sizeText
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .where((v) => v != null && v > 0)
          .map((v) => v!)
          .toList();

      final generateMaskable = settings['generate_maskable'] == true;
      final maskablePadding = settings['maskable_padding'] as double;
      final bgChoice = settings['maskable_bg'] as String;

      // Background color
      img.Color bgColor;
      switch (bgChoice) {
        case 'black':
          bgColor = img.ColorRgba8(0, 0, 0, 255);
          break;
        case 'white':
          bgColor = img.ColorRgba8(255, 255, 255, 255);
          break;
        default: // transparent
          bgColor = img.ColorRgba8(0, 0, 0, 0);
      }

      final outputs = <String, String>{};

      for (final size in sizes) {
        // Standard icon
        final resized = img.copyResize(
          image,
          width: size,
          height: size,
          interpolation: img.Interpolation.cubic,
        );
        final out = base64Encode(img.encodePng(resized));
        outputs['Icon-$size.png'] = out;

        // Maskable icon
        if (generateMaskable) {
          final paddedSize = (size * (1 - maskablePadding)).toInt();
          final base = img.Image(width: size, height: size);
          img.fill(base, color: bgColor);

          final resizedMask = img.copyResize(
            image,
            width: paddedSize,
            height: paddedSize,
            interpolation: img.Interpolation.cubic,
          );
          final dx = (size - resizedMask.width) ~/ 2;
          final dy = (size - resizedMask.height) ~/ 2;
          img.compositeImage(base, resizedMask, dstX: dx, dstY: dy);

          final outMask = base64Encode(img.encodePng(base));
          outputs['Icon-maskable-$size.png'] = outMask;
        }
      }

      // Markdown output
      final md = StringBuffer()
        ..writeln('# 📱 PWA Icons Generated\n')
        ..writeln('## Manifest Snippet\n')
        ..writeln('```json')
        ..writeln('"icons": [');
      for (final entry in outputs.entries) {
        final match = RegExp(r'(\d+)').firstMatch(entry.key);
        final size = match != null ? '${match.group(1)}x${match.group(1)}' : '';
        final purpose = entry.key.contains('maskable')
            ? ', "purpose": "maskable"'
            : '';
        md.writeln(
          '  { "src": "icons/${entry.key}", "sizes": "$size", "type": "image/png"$purpose },',
        );
      }
      md.writeln(']');
      md.writeln('```');

      // Previews
      md.writeln('\n## Output Icons');
      outputs.forEach((name, b64) {
        md.writeln('\n**$name**');
        md.writeln('```png\ndata:image/png;base64,$b64\n```');
      });

      return ToolResult(output: md.toString(), status: 'success');
    } catch (e) {
      return ToolResult(output: 'Error: $e', status: 'error');
    }
  }
}

class NinePatchDecoratorTool extends Tool {
  NinePatchDecoratorTool()
    : super(
        name: '9-Patch UI Decorator',
        description:
            'Generate 9-patch PNG images for Flutter UI components with perfect scaling',
        icon: Icons.crop_free,
        allowEmptyInput: true,
        isOutputMarkdown: true,
        settings: {
          // Preset selection
          'preset': 'button',

          // Size settings
          'width': 120,
          'height': 40,
          'corner_radius': 8,
          'border_width': 2,

          // Color settings
          'primary_color': '#3498db',
          'use_gradient': true,
          'gradient_direction': 'vertical', // vertical, horizontal, diagonal
          'auto_palette': true,
          'secondary_color': '#2980b9',

          // Style settings
          'style': 'raised', // flat, raised, inset, outlined, glass
          'shadow_enabled': true,
          'shadow_blur': 4,
          'shadow_offset_x': 0,
          'shadow_offset_y': 2,
          'shadow_opacity': 0.3,

          // 9-patch stretch areas (from edges)
          'stretch_left': 30,
          'stretch_right': 30,
          'stretch_top': 15,
          'stretch_bottom': 15,

          // Content padding (from edges)
          'content_left': 10,
          'content_right': 10,
          'content_top': 8,
          'content_bottom': 8,

          // Advanced effects
          'inner_glow': false,
          'border_glow': false,
          'texture_overlay': false,
        },
        settingsHints: {
          'preset': {
            'type': 'dropdown',
            'label': 'Preset Style',
            'options': [
              'button',
              'panel',
              'progress_bar',
              'progress_track',
              'input_field',
              'card',
              'dialog',
              'toast',
              'badge',
              'chip',
              'tab',
              'slider_thumb',
              'switch_track',
            ],
            'help': 'Quick preset configurations for common UI elements',
          },
          'width': {
            'type': 'spinner',
            'label': 'Width (px)',
            'min': 20,
            'max': 400,
            'step': 10,
            'decimal': false,
          },
          'height': {
            'type': 'spinner',
            'label': 'Height (px)',
            'min': 10,
            'max': 300,
            'step': 5,
            'decimal': false,
          },
          'corner_radius': {
            'type': 'slider',
            'label': 'Corner Radius',
            'min': 0,
            'max': 50,
            'divisions': 50,
            'show_range': false,
          },
          'border_width': {
            'type': 'slider',
            'label': 'Border Width',
            'min': 0,
            'max': 10,
            'divisions': 10,
            'show_range': false,
          },
          'primary_color': {
            'type': 'color',
            'label': 'Primary Color',
            'alpha': true,
            'presets': true,
            'help': 'Main color for the decorator',
          },
          'secondary_color': {
            'type': 'color',
            'label': 'Secondary Color',
            'alpha': true,
            'presets': true,
            'help': 'Used for gradients and effects',
          },
          'use_gradient': {
            'type': 'bool',
            'label': 'Use Gradient',
            'help': 'Apply gradient between primary and secondary colors',
          },
          'gradient_direction': {
            'type': 'dropdown',
            'label': 'Gradient Direction',
            'options': ['vertical', 'horizontal', 'diagonal'],
          },
          'auto_palette': {
            'type': 'bool',
            'label': 'Auto Generate Palette',
            'help': 'Automatically generate secondary color from primary',
          },
          'style': {
            'type': 'dropdown',
            'label': 'Visual Style',
            'options': ['flat', 'raised', 'inset', 'outlined', 'glass'],
            'help': 'Overall visual appearance',
          },
          'shadow_enabled': {'type': 'bool', 'label': 'Drop Shadow'},
          'shadow_blur': {
            'type': 'slider',
            'label': 'Shadow Blur',
            'min': 0,
            'max': 20,
            'divisions': 20,
            'show_range': false,
          },
          'shadow_offset_x': {
            'type': 'slider',
            'label': 'Shadow X Offset',
            'min': -10,
            'max': 10,
            'divisions': 20,
            'show_range': false,
          },
          'shadow_offset_y': {
            'type': 'slider',
            'label': 'Shadow Y Offset',
            'min': -10,
            'max': 10,
            'divisions': 20,
            'show_range': false,
          },
          'shadow_opacity': {
            'type': 'slider',
            'label': 'Shadow Opacity',
            'min': 0.0,
            'max': 1.0,
            'divisions': 10,
            'show_range': false,
          },
          'stretch_left': {
            'type': 'spinner',
            'label': 'Stretch Left Edge',
            'min': 5,
            'max': 100,
            'step': 5,
            'help': 'Distance from left edge where stretching starts',
          },
          'stretch_right': {
            'type': 'spinner',
            'label': 'Stretch Right Edge',
            'min': 5,
            'max': 100,
            'step': 5,
            'help': 'Distance from right edge where stretching starts',
          },
          'stretch_top': {
            'type': 'spinner',
            'label': 'Stretch Top Edge',
            'min': 5,
            'max': 50,
            'step': 5,
            'help': 'Distance from top edge where stretching starts',
          },
          'stretch_bottom': {
            'type': 'spinner',
            'label': 'Stretch Bottom Edge',
            'min': 5,
            'max': 50,
            'step': 5,
            'help': 'Distance from bottom edge where stretching starts',
          },
          'content_left': {
            'type': 'spinner',
            'label': 'Content Padding Left',
            'min': 0,
            'max': 50,
            'step': 2,
          },
          'content_right': {
            'type': 'spinner',
            'label': 'Content Padding Right',
            'min': 0,
            'max': 50,
            'step': 2,
          },
          'content_top': {
            'type': 'spinner',
            'label': 'Content Padding Top',
            'min': 0,
            'max': 30,
            'step': 2,
          },
          'content_bottom': {
            'type': 'spinner',
            'label': 'Content Padding Bottom',
            'min': 0,
            'max': 30,
            'step': 2,
          },
          'inner_glow': {
            'type': 'bool',
            'label': 'Inner Glow Effect',
            'help': 'Add subtle inner highlight',
          },
          'border_glow': {
            'type': 'bool',
            'label': 'Border Glow',
            'help': 'Add glow around border',
          },
          'texture_overlay': {
            'type': 'bool',
            'label': 'Texture Overlay',
            'help': 'Add subtle texture pattern',
          },
        },
      );

  @override
  Future<ToolResult> execute(String input) async {
    try {
      // Apply preset settings
      _applyPreset();

      // Auto-generate secondary color if enabled
      if (settings['auto_palette'] == true) {
        settings['secondary_color'] = _generateSecondaryColor(
          settings['primary_color'] as String,
        );
      }

      final width = settings['width'] as int;
      final height = settings['height'] as int;

      // Generate the 9-patch PNG
      final pngData = _generate9PatchPNG();
      final base64Data = base64Encode(pngData);

      // Build output
      final md = StringBuffer();
      md.writeln('# 🎨 9-Patch UI Decorator Generated\n');

      // Show current settings summary
      md.writeln('## ⚙️ Current Settings\n');
      md.writeln('- **Size**: ${width}x${height}px');
      md.writeln('- **Style**: ${settings['style']}');
      md.writeln(
        '- **Colors**: ${settings['primary_color']} → ${settings['secondary_color']}',
      );
      md.writeln('- **Corner Radius**: ${settings['corner_radius']}px');
      md.writeln('- **Border**: ${settings['border_width']}px');
      md.writeln(
        '- **Gradient**: ${settings['use_gradient'] ? 'Yes (${settings['gradient_direction']})' : 'No'}',
      );
      md.writeln('- **Shadow**: ${settings['shadow_enabled'] ? 'Yes' : 'No'}');
      md.writeln(
        '- **Stretch Areas**: L:${settings['stretch_left']}, R:${settings['stretch_right']}, T:${settings['stretch_top']}, B:${settings['stretch_bottom']}',
      );
      md.writeln(
        '- **Content Padding**: L:${settings['content_left']}, R:${settings['content_right']}, T:${settings['content_top']}, B:${settings['content_bottom']}\n',
      );

      // Show Flutter implementation
      md.writeln('## 📱 Flutter Usage\n');
      md.writeln('```dart');
      md.writeln(_generateFlutterCode());
      md.writeln('```\n');

      // Show the generated 9-patch image
      md.writeln('## 🖼️ Generated 9-Patch PNG\n');
      md.writeln('**9patch_${settings['preset']}.9.png**\n');
      md.writeln('```png\ndata:image/png;base64,$base64Data\n```\n');

      // Usage instructions
      md.writeln(_getUsageInstructions());

      return ToolResult(output: md.toString(), status: 'success');
    } catch (e, stackTrace) {
      return ToolResult(
        output: 'Error generating 9-patch: $e\n\nStack trace: $stackTrace',
        status: 'error',
      );
    }
  }

  void _applyPreset() {
    final preset = settings['preset'] as String;

    switch (preset) {
      case 'button':
        settings.addAll({
          'width': 120,
          'height': 40,
          'corner_radius': 8,
          'border_width': 0,
          'style': 'raised',
          'use_gradient': true,
          'shadow_enabled': true,
          'primary_color': '#3498db',
          'gradient_direction': 'vertical',
          'stretch_left': 30,
          'stretch_right': 30,
          'stretch_top': 15,
          'stretch_bottom': 15,
          'content_left': 12,
          'content_right': 12,
          'content_top': 8,
          'content_bottom': 8,
          'shadow_blur': 4,
          'shadow_offset_y': 2,
          'inner_glow': true,
        });
        break;

      case 'panel':
        settings.addAll({
          'width': 200,
          'height': 120,
          'corner_radius': 12,
          'border_width': 1,
          'style': 'flat',
          'use_gradient': false,
          'shadow_enabled': true,
          'primary_color': '#ecf0f1',
          'gradient_direction': 'vertical',
          'stretch_left': 50,
          'stretch_right': 50,
          'stretch_top': 30,
          'stretch_bottom': 30,
          'content_left': 16,
          'content_right': 16,
          'content_top': 16,
          'content_bottom': 16,
          'shadow_blur': 6,
          'shadow_offset_y': 3,
          'shadow_opacity': 0.1,
        });
        break;

      case 'progress_bar':
        settings.addAll({
          'width': 200,
          'height': 8,
          'corner_radius': 4,
          'border_width': 0,
          'style': 'raised',
          'use_gradient': true,
          'shadow_enabled': false,
          'primary_color': '#27ae60',
          'gradient_direction': 'vertical',
          'stretch_left': 8,
          'stretch_right': 8,
          'stretch_top': 2,
          'stretch_bottom': 2,
          'content_left': 2,
          'content_right': 2,
          'content_top': 2,
          'content_bottom': 2,
          'inner_glow': true,
        });
        break;

      case 'progress_track':
        settings.addAll({
          'width': 200,
          'height': 8,
          'corner_radius': 4,
          'border_width': 0,
          'style': 'inset',
          'use_gradient': true,
          'shadow_enabled': false,
          'primary_color': '#bdc3c7',
          'gradient_direction': 'vertical',
          'stretch_left': 8,
          'stretch_right': 8,
          'stretch_top': 2,
          'stretch_bottom': 2,
          'content_left': 2,
          'content_right': 2,
          'content_top': 2,
          'content_bottom': 2,
        });
        break;

      case 'input_field':
        settings.addAll({
          'width': 160,
          'height': 32,
          'corner_radius': 6,
          'border_width': 2,
          'style': 'inset',
          'use_gradient': false,
          'shadow_enabled': false,
          'primary_color': '#ffffff',
          'gradient_direction': 'vertical',
          'stretch_left': 40,
          'stretch_right': 40,
          'stretch_top': 12,
          'stretch_bottom': 12,
          'content_left': 12,
          'content_right': 12,
          'content_top': 6,
          'content_bottom': 6,
        });
        break;

      case 'card':
        settings.addAll({
          'width': 180,
          'height': 120,
          'corner_radius': 16,
          'border_width': 0,
          'style': 'raised',
          'use_gradient': false,
          'shadow_enabled': true,
          'primary_color': '#ffffff',
          'gradient_direction': 'vertical',
          'stretch_left': 60,
          'stretch_right': 60,
          'stretch_top': 40,
          'stretch_bottom': 40,
          'content_left': 20,
          'content_right': 20,
          'content_top': 20,
          'content_bottom': 20,
          'shadow_blur': 8,
          'shadow_offset_y': 4,
          'shadow_opacity': 0.15,
        });
        break;

      case 'dialog':
        settings.addAll({
          'width': 280,
          'height': 180,
          'corner_radius': 24,
          'border_width': 0,
          'style': 'raised',
          'use_gradient': false,
          'shadow_enabled': true,
          'primary_color': '#ffffff',
          'gradient_direction': 'vertical',
          'stretch_left': 80,
          'stretch_right': 80,
          'stretch_top': 60,
          'stretch_bottom': 60,
          'content_left': 24,
          'content_right': 24,
          'content_top': 24,
          'content_bottom': 24,
          'shadow_blur': 12,
          'shadow_offset_y': 6,
          'shadow_opacity': 0.25,
        });
        break;

      case 'toast':
        settings.addAll({
          'width': 200,
          'height': 36,
          'corner_radius': 18,
          'border_width': 0,
          'style': 'raised',
          'use_gradient': true,
          'shadow_enabled': true,
          'primary_color': '#2c3e50',
          'gradient_direction': 'vertical',
          'stretch_left': 60,
          'stretch_right': 60,
          'stretch_top': 12,
          'stretch_bottom': 12,
          'content_left': 16,
          'content_right': 16,
          'content_top': 8,
          'content_bottom': 8,
          'shadow_blur': 6,
          'shadow_offset_y': 3,
        });
        break;

      case 'badge':
        settings.addAll({
          'width': 24,
          'height': 24,
          'corner_radius': 12,
          'border_width': 0,
          'style': 'flat',
          'use_gradient': false,
          'shadow_enabled': false,
          'primary_color': '#e74c3c',
          'gradient_direction': 'vertical',
          'stretch_left': 8,
          'stretch_right': 8,
          'stretch_top': 8,
          'stretch_bottom': 8,
          'content_left': 4,
          'content_right': 4,
          'content_top': 4,
          'content_bottom': 4,
        });
        break;

      case 'chip':
        settings.addAll({
          'width': 80,
          'height': 28,
          'corner_radius': 14,
          'border_width': 1,
          'style': 'outlined',
          'use_gradient': false,
          'shadow_enabled': false,
          'primary_color': '#9b59b6',
          'gradient_direction': 'vertical',
          'stretch_left': 20,
          'stretch_right': 20,
          'stretch_top': 10,
          'stretch_bottom': 10,
          'content_left': 8,
          'content_right': 8,
          'content_top': 4,
          'content_bottom': 4,
        });
        break;

      case 'tab':
        settings.addAll({
          'width': 100,
          'height': 32,
          'corner_radius': 16,
          'border_width': 0,
          'style': 'flat',
          'use_gradient': true,
          'shadow_enabled': false,
          'primary_color': '#3498db',
          'gradient_direction': 'vertical',
          'stretch_left': 25,
          'stretch_right': 25,
          'stretch_top': 10,
          'stretch_bottom': 10,
          'content_left': 12,
          'content_right': 12,
          'content_top': 6,
          'content_bottom': 6,
        });
        break;

      case 'slider_thumb':
        settings.addAll({
          'width': 20,
          'height': 20,
          'corner_radius': 10,
          'border_width': 2,
          'style': 'raised',
          'use_gradient': true,
          'shadow_enabled': true,
          'primary_color': '#ffffff',
          'gradient_direction': 'vertical',
          'stretch_left': 6,
          'stretch_right': 6,
          'stretch_top': 6,
          'stretch_bottom': 6,
          'content_left': 2,
          'content_right': 2,
          'content_top': 2,
          'content_bottom': 2,
          'shadow_blur': 3,
          'shadow_offset_y': 1,
          'inner_glow': true,
        });
        break;

      case 'switch_track':
        settings.addAll({
          'width': 40,
          'height': 20,
          'corner_radius': 10,
          'border_width': 1,
          'style': 'inset',
          'use_gradient': true,
          'shadow_enabled': false,
          'primary_color': '#bdc3c7',
          'gradient_direction': 'vertical',
          'stretch_left': 12,
          'stretch_right': 12,
          'stretch_top': 6,
          'stretch_bottom': 6,
          'content_left': 4,
          'content_right': 4,
          'content_top': 4,
          'content_bottom': 4,
        });
        break;
    }
  }

  String _generateSecondaryColor(String primaryHex) {
    final primary = _parseHexColor(primaryHex);
    final style = settings['style'] as String;

    switch (style) {
      case 'raised':
        // Lighter version for highlight
        return _lightenColor(primaryHex, 0.2);
      case 'inset':
        // Darker version for depth
        return _darkenColor(primaryHex, 0.3);
      case 'glass':
        // More transparent version
        return _adjustAlpha(primaryHex, 0.6);
      default:
        // Slightly darker for subtle gradient
        return _darkenColor(primaryHex, 0.15);
    }
  }

  List<int> _generate9PatchPNG() {
    final width = settings['width'] as int;
    final height = settings['height'] as int;

    // Create image with 9-patch borders (2px on each side for markers)
    final totalWidth = width + 2;
    final totalHeight = height + 2;
    final image = img.Image(width: totalWidth, height: totalHeight);

    // Fill with transparent background
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

    // Draw shadow first (if enabled)
    if (settings['shadow_enabled'] == true) {
      _drawShadow(image, 1, 1, width, height);
    }

    // Draw the main decorator shape
    _drawMainShape(image, 1, 1, width, height);

    // Apply visual effects
    _applyVisualEffects(image, 1, 1, width, height);

    // Draw border (if enabled)
    final borderWidth = settings['border_width'] as int;
    if (borderWidth > 0) {
      _drawBorder(image, 1, 1, width, height);
    }

    // Draw 9-patch markers
    _draw9PatchMarkers(image, width, height);

    return img.encodePng(image);
  }

  void _drawShadow(img.Image image, int x, int y, int width, int height) {
    final shadowBlur = settings['shadow_blur'] as int;
    final offsetX = settings['shadow_offset_x'] as int;
    final offsetY = settings['shadow_offset_y'] as int;
    final shadowOpacity = settings['shadow_opacity'] as double;
    final cornerRadius = settings['corner_radius'] as int;

    final shadowX = x + offsetX;
    final shadowY = y + offsetY;

    // Create shadow color
    final shadowColor = img.ColorRgba8(0, 0, 0, (255 * shadowOpacity).round());

    // Draw shadow with blur effect
    for (int blur = shadowBlur; blur >= 0; blur--) {
      final blurOpacity =
          (shadowOpacity * (shadowBlur - blur + 1) / (shadowBlur + 1));
      final blurColor = img.ColorRgba8(0, 0, 0, (255 * blurOpacity).round());

      _drawRoundedRect(
        image,
        shadowX - blur,
        shadowY - blur,
        width + blur * 2,
        height + blur * 2,
        cornerRadius,
        blurColor,
      );
    }
  }

  void _drawMainShape(img.Image image, int x, int y, int width, int height) {
    final cornerRadius = settings['corner_radius'] as int;
    final primaryColor = _parseHexColor(settings['primary_color'] as String);
    final useGradient = settings['use_gradient'] as bool;

    if (useGradient) {
      _drawGradientShape(image, x, y, width, height, cornerRadius);
    } else {
      _drawRoundedRect(image, x, y, width, height, cornerRadius, primaryColor);
    }
  }

  void _drawGradientShape(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int cornerRadius,
  ) {
    final primaryColor = _parseHexColor(settings['primary_color'] as String);
    final secondaryColor = _parseHexColor(
      settings['secondary_color'] as String,
    );
    final gradientDirection = settings['gradient_direction'] as String;

    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, cornerRadius)) {
          double factor = _calculateGradientFactor(
            px,
            py,
            width,
            height,
            gradientDirection,
          );
          final color = _interpolateColors(
            primaryColor,
            secondaryColor,
            factor,
          );

          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            image.setPixel(imgX, imgY, color);
          }
        }
      }
    }
  }

  double _calculateGradientFactor(
    int px,
    int py,
    int width,
    int height,
    String direction,
  ) {
    switch (direction) {
      case 'vertical':
        return py / height;
      case 'horizontal':
        return px / width;
      case 'diagonal':
        return (px + py) / (width + height);
      default:
        return py / height;
    }
  }

  void _applyVisualEffects(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
  ) {
    final style = settings['style'] as String;
    final cornerRadius = settings['corner_radius'] as int;

    switch (style) {
      case 'raised':
        _applyRaisedEffect(image, x, y, width, height, cornerRadius);
        break;
      case 'inset':
        _applyInsetEffect(image, x, y, width, height, cornerRadius);
        break;
      case 'glass':
        _applyGlassEffect(image, x, y, width, height, cornerRadius);
        break;
    }

    // Apply optional effects
    if (settings['inner_glow'] == true) {
      _applyInnerGlow(image, x, y, width, height, cornerRadius);
    }

    if (settings['texture_overlay'] == true) {
      _applyTextureOverlay(image, x, y, width, height, cornerRadius);
    }
  }

  void _applyRaisedEffect(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int cornerRadius,
  ) {
    // Add highlight on top edge
    final highlightColor = img.ColorRgba8(255, 255, 255, 80);
    final highlightHeight = max(1, height ~/ 8);

    for (int py = 0; py < highlightHeight; py++) {
      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, cornerRadius)) {
          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            final existing = image.getPixel(imgX, imgY);
            final blended = _blendColors(existing, highlightColor);
            image.setPixel(imgX, imgY, blended);
          }
        }
      }
    }

    // Add shadow on bottom edge
    final shadowColor = img.ColorRgba8(0, 0, 0, 60);
    final shadowHeight = max(1, height ~/ 8);

    for (int py = height - shadowHeight; py < height; py++) {
      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, cornerRadius)) {
          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            final existing = image.getPixel(imgX, imgY);
            final blended = _blendColors(existing, shadowColor);
            image.setPixel(imgX, imgY, blended);
          }
        }
      }
    }
  }

  void _applyInsetEffect(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int cornerRadius,
  ) {
    // Add shadow on top edge (opposite of raised)
    final shadowColor = img.ColorRgba8(0, 0, 0, 100);
    final shadowHeight = max(1, height ~/ 6);

    for (int py = 0; py < shadowHeight; py++) {
      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, cornerRadius)) {
          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            final existing = image.getPixel(imgX, imgY);
            final blended = _blendColors(existing, shadowColor);
            image.setPixel(imgX, imgY, blended);
          }
        }
      }
    }
  }

  void _applyGlassEffect(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int cornerRadius,
  ) {
    // Add strong highlight on top half
    final highlightColor = img.ColorRgba8(255, 255, 255, 120);
    final highlightHeight = height ~/ 2;

    for (int py = 0; py < highlightHeight; py++) {
      final opacity = (120 * (1 - py / highlightHeight)).round();
      final fadeColor = img.ColorRgba8(255, 255, 255, opacity);

      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, cornerRadius)) {
          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            final existing = image.getPixel(imgX, imgY);
            final blended = _blendColors(existing, fadeColor);
            image.setPixel(imgX, imgY, blended);
          }
        }
      }
    }
  }

  void _applyInnerGlow(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int cornerRadius,
  ) {
    final glowColor = img.ColorRgba8(255, 255, 255, 40);
    final glowWidth = 2;

    // Draw inner glow around the edge
    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, cornerRadius)) {
          // Check if this pixel is near the edge
          bool nearEdge = false;
          for (int dy = -glowWidth; dy <= glowWidth && !nearEdge; dy++) {
            for (int dx = -glowWidth; dx <= glowWidth && !nearEdge; dx++) {
              if (!_isInsideRoundedRect(
                px + dx,
                py + dy,
                width,
                height,
                cornerRadius,
              )) {
                nearEdge = true;
              }
            }
          }

          if (nearEdge) {
            final imgX = x + px;
            final imgY = y + py;
            if (_isValidPixel(image, imgX, imgY)) {
              final existing = image.getPixel(imgX, imgY);
              final blended = _blendColors(existing, glowColor);
              image.setPixel(imgX, imgY, blended);
            }
          }
        }
      }
    }
  }

  void _applyTextureOverlay(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int cornerRadius,
  ) {
    final random = Random(42); // Fixed seed for consistent texture

    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, cornerRadius)) {
          // Simple noise texture
          final noise = random.nextDouble() * 0.1 - 0.05; // -5% to +5%
          final textureOpacity = (20 + noise * 255).round().clamp(0, 255);
          final textureColor = img.ColorRgba8(128, 128, 128, textureOpacity);

          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            final existing = image.getPixel(imgX, imgY);
            final blended = _blendColors(existing, textureColor);
            image.setPixel(imgX, imgY, blended);
          }
        }
      }
    }
  }

  void _drawBorder(img.Image image, int x, int y, int width, int height) {
    final borderWidth = settings['border_width'] as int;
    final cornerRadius = settings['corner_radius'] as int;
    final borderColor = _getBorderColor();

    // Draw border by checking if pixel is in outer shape but not in inner shape
    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        final isInOuter = _isInsideRoundedRect(
          px,
          py,
          width,
          height,
          cornerRadius,
        );
        final isInInner = _isInsideRoundedRect(
          px - borderWidth,
          py - borderWidth,
          width - 2 * borderWidth,
          height - 2 * borderWidth,
          max(0, cornerRadius - borderWidth),
        );

        if (isInOuter && !isInInner) {
          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            image.setPixel(imgX, imgY, borderColor);
          }
        }
      }
    }

    // Apply border glow if enabled
    if (settings['border_glow'] == true) {
      _applyBorderGlow(image, x, y, width, height, cornerRadius, borderWidth);
    }
  }

  void _applyBorderGlow(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int cornerRadius,
    int borderWidth,
  ) {
    final glowColor = _parseHexColor(settings['primary_color'] as String);
    final glowSize = 2;

    for (int py = -glowSize; py < height + glowSize; py++) {
      for (int px = -glowSize; px < width + glowSize; px++) {
        final distance = _getDistanceToShape(
          px,
          py,
          width,
          height,
          cornerRadius,
        );

        if (distance >= borderWidth && distance <= borderWidth + glowSize) {
          final glowIntensity = 1.0 - ((distance - borderWidth) / glowSize);
          final glowAlpha = (60 * glowIntensity).round();
          final finalGlowColor = img.ColorRgba8(
            glowColor.r.toInt(),
            glowColor.g.toInt(),
            glowColor.b.toInt(),
            glowAlpha,
          );

          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            final existing = image.getPixel(imgX, imgY);
            final blended = _blendColors(existing, finalGlowColor);
            image.setPixel(imgX, imgY, blended);
          }
        }
      }
    }
  }

  void _draw9PatchMarkers(img.Image image, int width, int height) {
    final stretchLeft = settings['stretch_left'] as int;
    final stretchRight = settings['stretch_right'] as int;
    final stretchTop = settings['stretch_top'] as int;
    final stretchBottom = settings['stretch_bottom'] as int;

    final contentLeft = settings['content_left'] as int;
    final contentRight = settings['content_right'] as int;
    final contentTop = settings['content_top'] as int;
    final contentBottom = settings['content_bottom'] as int;

    final black = img.ColorRgba8(0, 0, 0, 255);

    // Top stretch markers (horizontal stretchable area)
    final leftStretchEnd = width - stretchRight;
    for (int i = stretchLeft; i < leftStretchEnd; i++) {
      if (i + 1 < image.width) {
        image.setPixel(i + 1, 0, black);
      }
    }

    // Left stretch markers (vertical stretchable area)
    final topStretchEnd = height - stretchBottom;
    for (int i = stretchTop; i < topStretchEnd; i++) {
      if (i + 1 < image.height) {
        image.setPixel(0, i + 1, black);
      }
    }

    // Bottom content area markers (horizontal content padding)
    final contentRightEnd = width - contentRight;
    for (int i = contentLeft; i < contentRightEnd; i++) {
      if (i + 1 < image.width && height + 1 < image.height) {
        image.setPixel(i + 1, height + 1, black);
      }
    }

    // Right content area markers (vertical content padding)
    final contentBottomEnd = height - contentBottom;
    for (int i = contentTop; i < contentBottomEnd; i++) {
      if (width + 1 < image.width && i + 1 < image.height) {
        image.setPixel(width + 1, i + 1, black);
      }
    }
  }

  void _drawRoundedRect(
    img.Image image,
    int x,
    int y,
    int width,
    int height,
    int radius,
    img.Color color,
  ) {
    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        if (_isInsideRoundedRect(px, py, width, height, radius)) {
          final imgX = x + px;
          final imgY = y + py;
          if (_isValidPixel(image, imgX, imgY)) {
            image.setPixel(imgX, imgY, color);
          }
        }
      }
    }
  }

  bool _isInsideRoundedRect(int px, int py, int width, int height, int radius) {
    if (px < 0 || py < 0 || px >= width || py >= height) return false;
    if (radius <= 0) return true;

    // Check corners
    final corners = [
      {'x': radius, 'y': radius}, // Top-left
      {'x': width - radius, 'y': radius}, // Top-right
      {'x': radius, 'y': height - radius}, // Bottom-left
      {'x': width - radius, 'y': height - radius}, // Bottom-right
    ];

    for (final corner in corners) {
      final cx = corner['x'] as int;
      final cy = corner['y'] as int;

      // Check if point is in this corner's quadrant
      bool inQuadrant = false;
      if (cx == radius && cy == radius) {
        // Top-left
        inQuadrant = px <= radius && py <= radius;
      } else if (cx == width - radius && cy == radius) {
        // Top-right
        inQuadrant = px >= width - radius && py <= radius;
      } else if (cx == radius && cy == height - radius) {
        // Bottom-left
        inQuadrant = px <= radius && py >= height - radius;
      } else if (cx == width - radius && cy == height - radius) {
        // Bottom-right
        inQuadrant = px >= width - radius && py >= height - radius;
      }

      if (inQuadrant) {
        final dx = px - cx;
        final dy = py - cy;
        return dx * dx + dy * dy <= radius * radius;
      }
    }

    return true; // Point is not in any corner area, so it's inside
  }

  double _getDistanceToShape(
    int px,
    int py,
    int width,
    int height,
    int radius,
  ) {
    // Simple distance calculation to shape edge
    if (_isInsideRoundedRect(px, py, width, height, radius)) {
      return 0.0;
    }

    // Calculate distance to nearest edge
    double minDist = double.infinity;

    // Check distance to edges
    if (px < 0) minDist = min(minDist, -px.toDouble());
    if (px >= width) minDist = min(minDist, (px - width + 1).toDouble());
    if (py < 0) minDist = min(minDist, -py.toDouble());
    if (py >= height) minDist = min(minDist, (py - height + 1).toDouble());

    return minDist;
  }

  bool _isValidPixel(img.Image image, int x, int y) {
    return x >= 0 && y >= 0 && x < image.width && y < image.height;
  }

  img.Color _parseHexColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return img.ColorRgba8(r, g, b, 255);
    } else if (hex.length == 8) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      final a = int.parse(hex.substring(6, 8), radix: 16);
      return img.ColorRgba8(r, g, b, a);
    }
    return img.ColorRgba8(0, 0, 0, 255);
  }

  img.Color _interpolateColors(
    img.Color color1,
    img.Color color2,
    double factor,
  ) {
    factor = factor.clamp(0.0, 1.0);

    final r = (color1.r + (color2.r - color1.r) * factor).round();
    final g = (color1.g + (color2.g - color1.g) * factor).round();
    final b = (color1.b + (color2.b - color1.b) * factor).round();
    final a = (color1.a + (color2.a - color1.a) * factor).round();

    return img.ColorRgba8(r, g, b, a);
  }

  img.Color _blendColors(img.Color base, img.Color overlay) {
    final alpha = overlay.a / 255.0;
    final invAlpha = 1.0 - alpha;

    final r = (base.r * invAlpha + overlay.r * alpha).round();
    final g = (base.g * invAlpha + overlay.g * alpha).round();
    final b = (base.b * invAlpha + overlay.b * alpha).round();
    final a = max(base.a, overlay.a);

    return img.ColorRgba8(r, g, b, a.toInt());
  }

  img.Color _getBorderColor() {
    final style = settings['style'] as String;
    final primaryColor = _parseHexColor(settings['primary_color'] as String);

    if (style == 'outlined') {
      return primaryColor;
    } else {
      // Generate darker version for border
      final darkR = (primaryColor.r * 0.6).round();
      final darkG = (primaryColor.g * 0.6).round();
      final darkB = (primaryColor.b * 0.6).round();
      return img.ColorRgba8(darkR, darkG, darkB, primaryColor.a.toInt());
    }
  }

  String _lightenColor(String hexColor, double amount) {
    final color = _parseHexColor(hexColor);
    final r = (color.r + (255 - color.r) * amount).clamp(0, 255).round();
    final g = (color.g + (255 - color.g) * amount).clamp(0, 255).round();
    final b = (color.b + (255 - color.b) * amount).clamp(0, 255).round();

    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  String _darkenColor(String hexColor, double amount) {
    final color = _parseHexColor(hexColor);
    final r = (color.r * (1 - amount)).clamp(0, 255).round();
    final g = (color.g * (1 - amount)).clamp(0, 255).round();
    final b = (color.b * (1 - amount)).clamp(0, 255).round();

    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  String _adjustAlpha(String hexColor, double alpha) {
    final color = _parseHexColor(hexColor);
    final newAlpha = (255 * alpha).clamp(0, 255).round();

    return '#'
        '${(color.r as int).toRadixString(16).padLeft(2, '0')}'
        '${(color.g as int).toRadixString(16).padLeft(2, '0')}'
        '${(color.b as int).toRadixString(16).padLeft(2, '0')}'
        '${(newAlpha.round()).toRadixString(16).padLeft(2, '0')}';
  }

  String _generateFlutterCode() {
    final width = settings['width'] as int;
    final height = settings['height'] as int;
    final cornerRadius = settings['corner_radius'] as int;
    final borderWidth = settings['border_width'] as int;
    final primaryColor = settings['primary_color'] as String;
    final secondaryColor = settings['secondary_color'] as String;
    final useGradient = settings['use_gradient'] as bool;
    final gradientDirection = settings['gradient_direction'] as String;
    final shadowEnabled = settings['shadow_enabled'] as bool;
    final style = settings['style'] as String;

    final code = StringBuffer();
    code.writeln('// Using 9-patch image');
    code.writeln('Container(');
    code.writeln('  width: $width,');
    code.writeln('  height: $height,');
    code.writeln('  decoration: BoxDecoration(');
    code.writeln('    image: DecorationImage(');
    code.writeln(
      '      image: AssetImage(\'assets/9patch_${settings['preset']}.9.png\'),',
    );
    code.writeln('      fit: BoxFit.fill, // Important: Use fill for 9-patch');
    code.writeln('    ),');
    code.writeln('  ),');
    code.writeln('  child: Text(\'Your content here\'),');
    code.writeln(')');

    code.writeln('\n// Alternative: Pure Flutter BoxDecoration');
    code.writeln('Container(');
    code.writeln('  width: $width,');
    code.writeln('  height: $height,');
    code.writeln('  decoration: BoxDecoration(');
    code.writeln('    borderRadius: BorderRadius.circular($cornerRadius.0),');

    if (useGradient) {
      code.writeln(
        '    gradient: ${_getFlutterGradient(gradientDirection, primaryColor, secondaryColor)},',
      );
    } else {
      final cleanColor = primaryColor.replaceAll('#', '');
      code.writeln('    color: Color(0xFF$cleanColor),');
    }

    if (borderWidth > 0) {
      final borderColor = _getBorderColor();
      final cleanBorderColor = _colorToHex(borderColor).replaceAll('#', '');
      code.writeln('    border: Border.all(');
      code.writeln('      color: Color(0xFF$cleanBorderColor),');
      code.writeln('      width: $borderWidth.0,');
      code.writeln('    ),');
    }

    if (shadowEnabled) {
      final shadowBlur = settings['shadow_blur'] as int;
      final offsetX = settings['shadow_offset_x'] as int;
      final offsetY = settings['shadow_offset_y'] as int;
      final shadowOpacity = settings['shadow_opacity'] as double;

      code.writeln('    boxShadow: [');
      code.writeln('      BoxShadow(');
      code.writeln('        color: Colors.black.withOpacity($shadowOpacity),');
      code.writeln('        blurRadius: $shadowBlur.0,');
      code.writeln('        offset: Offset($offsetX.0, $offsetY.0),');
      code.writeln('      ),');
      code.writeln('    ],');
    }

    code.writeln('  ),');
    code.writeln('  child: Text(\'Your content here\'),');
    code.writeln(')');

    return code.toString();
  }

  String _getFlutterGradient(String direction, String color1, String color2) {
    final cleanColor1 = color1.replaceAll('#', '');
    final cleanColor2 = color2.replaceAll('#', '');

    switch (direction) {
      case 'vertical':
        return 'LinearGradient(\n      begin: Alignment.topCenter,\n      end: Alignment.bottomCenter,\n      colors: [Color(0xFF$cleanColor1), Color(0xFF$cleanColor2)],\n    )';
      case 'horizontal':
        return 'LinearGradient(\n      begin: Alignment.centerLeft,\n      end: Alignment.centerRight,\n      colors: [Color(0xFF$cleanColor1), Color(0xFF$cleanColor2)],\n    )';
      case 'diagonal':
        return 'LinearGradient(\n      begin: Alignment.topLeft,\n      end: Alignment.bottomRight,\n      colors: [Color(0xFF$cleanColor1), Color(0xFF$cleanColor2)],\n    )';
      default:
        return 'LinearGradient(colors: [Color(0xFF$cleanColor1), Color(0xFF$cleanColor2)])';
    }
  }

  String _colorToHex(img.Color color) {
    return '#${color.r.toInt().toRadixString(16).padLeft(2, '0')}'
        '${color.g.toInt().toRadixString(16).padLeft(2, '0')}'
        '${color.b.toInt().toRadixString(16).padLeft(2, '0')}';
  }

  String _getUsageInstructions() {
    return '''
## 📋 How to Use Your 9-Patch

### 1. **Add to Flutter Project**
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/9patch_${settings['preset']}.9.png
```

### 2. **Android Integration**
- Place the `.9.png` file in `android/app/src/main/res/drawable/`
- Reference in XML layouts: `android:background="@drawable/9patch_${settings['preset']}"`

### 3. **9-Patch Stretching Guide**
- **Black pixels on TOP edge**: Define horizontal stretch areas
- **Black pixels on LEFT edge**: Define vertical stretch areas  
- **Black pixels on BOTTOM edge**: Define horizontal content padding
- **Black pixels on RIGHT edge**: Define vertical content padding

### 4. **Current Stretch Configuration**
- **Horizontal stretch**: Pixels ${settings['stretch_left']} to ${(settings['width'] as int) - (settings['stretch_right'] as int)} will stretch
- **Vertical stretch**: Pixels ${settings['stretch_top']} to ${(settings['height'] as int) - (settings['stretch_bottom'] as int)} will stretch
- **Content area**: ${settings['content_left']},${settings['content_top']} to ${(settings['width'] as int) - (settings['content_right'] as int)},${(settings['height'] as int) - (settings['content_bottom'] as int)}

### 5. **Best Practices**
- Use **BoxFit.fill** when using 9-patch as DecorationImage
- Test stretching with different content sizes
- Keep stretch areas away from visual details (corners, borders)
- Ensure content padding provides enough space for text/icons

### 6. **Preset Optimizations**
- **${settings['preset']}**: Optimized for ${_getPresetDescription()}
''';
  }

  String _getPresetDescription() {
    switch (settings['preset']) {
      case 'button':
        return 'clickable elements with proper touch targets';
      case 'panel':
        return 'content containers and background panels';
      case 'progress_bar':
        return 'horizontal progress indicators';
      case 'progress_track':
        return 'progress bar backgrounds';
      case 'input_field':
        return 'text input backgrounds with focus states';
      case 'card':
        return 'elevated content cards with shadows';
      case 'dialog':
        return 'modal dialogs and popups';
      case 'toast':
        return 'notification messages';
      case 'badge':
        return 'small notification counters';
      case 'chip':
        return 'tag-like selections';
      case 'tab':
        return 'tab navigation elements';
      case 'slider_thumb':
        return 'draggable slider controls';
      case 'switch_track':
        return 'toggle switch backgrounds';
      default:
        return 'general UI elements';
    }
  }
}

Map<String, List<Tool Function()>> getMiscTools() {
  return {
    'Image Tools': [
      () => PngToIcoTool(),
      () => ImageEditorTool(),
      () => PwaIconTool(),
      () => NinePatchDecoratorTool(),
    ],
    'Misc': [() => ColorPaletteGenerator(), () => NinePatchUITool()],
  };
}
