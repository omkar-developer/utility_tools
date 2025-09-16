import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/config/markdown_generator.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:utility_tools/services/file_converter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:utility_tools/widgets/input_text_field.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:markdown/markdown.dart' as m;

String _cleanBase64Static(String base64Text) {
  return base64Text
      .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
      .replaceAll(RegExp(r'\s+'), '');
}

String _detectImageFormatFromBytes(Uint8List bytes) {
  if (bytes.length >= 4) {
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'gif';
    }
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return 'bmp';
    if (bytes.length > 11 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    if (bytes[0] == 0x00 &&
        bytes[1] == 0x00 &&
        bytes[2] == 0x01 &&
        bytes[3] == 0x00) {
      return 'ico';
    }
  }
  return 'unknown';
}

class Base64ImageSyntax extends m.InlineSyntax {
  Base64ImageSyntax()
    : super(
        // Updated regex to handle both regular images and SVG
        r'!\[([^\]]*)\]\((data:image\/[a-zA-Z0-9.+-]+(?:;base64)?[;,][A-Za-z0-9+/=]+)\)',
      );

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final altText = match.group(1) ?? '';
    final dataUrl = match.group(2) ?? '';

    final el = m.Element.empty('base64image');
    el.attributes['alt'] = altText;
    el.attributes['src'] = dataUrl;

    parser.addNode(el);
    return true;
  }
}

class Base64ImageNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  Base64ImageNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    final style = parentStyle ?? config.p.textStyle;
    final src = attributes['src'] ?? '';
    final alt = attributes['alt'] ?? '';

    if (!src.startsWith('data:image/')) {
      return TextSpan(text: alt.isNotEmpty ? alt : textContent, style: style);
    }

    try {
      // Check if it's SVG
      if (src.contains('data:image/svg+xml')) {
        // Handle SVG data URL
        final parts = src.split(',');
        if (parts.length == 2) {
          final svgContent = utf8.decode(base64Decode(parts[1]));
          return WidgetSpan(
            child: SizedBox(
              height: 200, // or desired height
              child: SvgPicture.string(svgContent, fit: BoxFit.contain),
            ),
          );
        }
      }

      // Handle regular base64 images
      final clean = _cleanBase64Static(src);
      final bytes = base64Decode(clean);
      final format = _detectImageFormatFromBytes(bytes);
      return WidgetSpan(
        child: UnifiedBase64ImageViewer(bytes: bytes, format: format),
      );
    } catch (e) {
      return TextSpan(
        text: '[Invalid image]',
        style: style.copyWith(color: Colors.red),
      );
    }
  }
}

final base64ImageGenerator2 = SpanNodeGeneratorWithTag(
  tag: 'base64image', // Changed from 'base64img' to match your syntax
  generator: (element, config, visitor) {
    return Base64ImageNode(element.attributes, element.textContent, config);
  },
);

class UnifiedBase64ImageViewer extends StatelessWidget {
  final Uint8List bytes;
  final String format;

  const UnifiedBase64ImageViewer({
    super.key,
    required this.bytes,
    required this.format,
  });

  String get prettySize => (bytes.length / 1024).toStringAsFixed(1);

  Future<void> _saveImage(BuildContext context) async {
    try {
      final extension = (format.isNotEmpty ? format : 'png');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'image_$timestamp.$extension';
      await FileExporter.saveBinaryFile(bytes, filename);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved as $filename'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      // fallback: share raw bytes as base64 text if platform share doesn't accept binary
      final base64Text = base64Encode(bytes);
      SharePlus.instance.share(
        ShareParams(
          text: 'data:image/$format;base64,$base64Text',
          title: 'Image',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Full screen interactive viewer
            SizedBox.expand(
              child: InteractiveViewer(
                minScale: 0.1,
                maxScale: 10.0,
                clipBehavior: Clip.none,
                child: Center(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),

            // Close button (top-right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  tooltip: 'Close',
                ),
              ),
            ),

            // Info and action bar (bottom)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${format.toUpperCase()} Image',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(bytes.length / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.save_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _saveImageFromFullscreen(
                              context,
                              bytes,
                              format,
                            ),
                            tooltip: 'Save',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _shareImageFromFullscreen(
                              context,
                              bytes,
                              format,
                            ),
                            tooltip: 'Share',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Zoom instructions (top-left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pinch to zoom • Drag to pan',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for fullscreen actions
  Future<void> _saveImageFromFullscreen(
    BuildContext context,
    Uint8List bytes,
    String format,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'image_$timestamp.$format';

      final savedPath = await FileExporter.saveBinaryFile(bytes, filename);

      if (context.mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved as $filename'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareImageFromFullscreen(
    BuildContext context,
    Uint8List bytes,
    String format,
  ) async {
    try {
      final base64Text = base64Encode(bytes);
      await SharePlus.instance.share(
        ShareParams(
          text: 'data:image/$format;base64,$base64Text',
          title: 'Image',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image;
      case 'gif':
        return Icons.gif;
      case 'svg':
        return Icons.image;
      case 'ico':
        return Icons.apps;
      case 'webp':
        return Icons.web;
      default:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey[100],
                        child: Center(
                          child: Text('Failed to load ${format.toUpperCase()}'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getFormatIcon(format), size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${format.toUpperCase()} • $prettySize KB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.zoom_in, size: 16, color: Colors.grey[500]),
                Text(
                  ' Tap to zoom',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum IOFormat { text, markdown }

class IOCard extends StatelessWidget {
  final String label;
  final bool isOutput;
  final bool livePreview;
  final TextEditingController? controller;
  final Function(String action)? onButtonPressed;
  final ValueChanged<bool>? onLivePreviewChanged;
  final bool enableActions;
  final bool compactProcessButton;
  final VoidCallback? onExecute;
  final Function(bool saved)? onSaved;
  final IOFormat format;
  final String content;
  final FileExporter _exporter = FileExporter();
  final double fontSize = 16.0;
  final ScrollController? scrollController;
  final bool isStreaming;
  final bool isCancelStreaming;
  final VoidCallback? onCancelStreaming;
  final String? statusMessage;
  final VoidCallback? onSaveJS;
  final bool showSaveJSButton;
  final bool wrapCodeText;
  final ValueChanged<bool>? onWrapToggled;

  final testText = """
On a cool autumn morning, the sky was painted in hues of orange and pink, with the sun barely peeking above the horizon. The forest, still wrapped in the silence of dawn, held a peacefulness that seemed untouched by time. A light mist hung over the ground, curling around the trees like a soft blanket. Birds began to stir, their songs adding a delicate melody to the stillness.

Beneath the canopy of leaves, the forest floor was littered with fallen branches and the occasional burst of vibrant color from the autumn foliage. The rustling of the leaves was the only sound as the wind began to pick up, dancing through the trees with a playful energy. Far in the distance, a brook gurgled quietly, its waters clear and refreshing as they wound their way through the woods.

Deeper in the forest, a small clearing appeared, bathed in the golden light of the rising sun. The ground was soft and covered with moss, offering a quiet refuge for those who ventured this far. It was here that the fox often came, its orange fur blending in with the autumn colors. It would leap from one tree to another, its movements swift and fluid, always alert to the sounds around it.

Time seemed to slow in the clearing. It was a place where the rush of the outside world felt miles away, and the beauty of nature was allowed to unfold in its purest form. The peace of the moment was intoxicating, a feeling of being fully present in the world, not just a spectator but a part of the scene.

As the morning passed, the forest began to wake in earnest. The sun climbed higher, and the mist evaporated, leaving behind a fresh, crisp air. The birds were joined by squirrels, rabbits, and the occasional deer, each going about their day in their own quiet way. But the fox, elusive as ever, remained hidden, a silent observer of the world it called home.
""";

  IOCard({
    super.key,
    required this.label,
    required this.isOutput,
    this.controller,
    this.onButtonPressed,
    this.onLivePreviewChanged,
    this.livePreview = false,
    this.enableActions = true,
    this.compactProcessButton = false,
    this.onExecute,
    this.format = IOFormat.text,
    this.content = '',
    this.onSaved,
    this.scrollController,
    this.isStreaming = false,
    this.onCancelStreaming,
    this.isCancelStreaming = false,
    this.statusMessage,
    this.onSaveJS,
    this.showSaveJSButton = false,
    this.wrapCodeText = false,
    this.onWrapToggled,
  });

  Future<void> handlePasteAction(TextEditingController? controller) async {
    if (controller == null) return;

    try {
      // Try getting image from clipboard first
      final Uint8List? imageBytes = await Pasteboard.image;
      if (imageBytes != null) {
        // Convert to base64
        final base64Image = base64Encode(imageBytes);
        // Here assuming PNG, you can extend to detect format if needed
        controller.text = 'data:image/png;base64,$base64Image';
        return;
      }

      // If no image, fallback to text
      final data = await Pasteboard.text; // gets clipboard as text
      if (data != null && data.isNotEmpty) {
        controller.text = data;
      }
    } catch (e) {
      debugPrint('Failed to paste from clipboard: $e');
    }
  }

  void _handleAction(BuildContext context, String action) async {
    if (action == 'paste') {
      //final data = await Clipboard.getData(Clipboard.kTextPlain);
      //if (data?.text != null) controller?.text = data!.text!;
      handlePasteAction(controller);
    } else if (action == 'clear') {
      controller?.clear();
    } else if (action == 'copy') {
      Clipboard.setData(ClipboardData(text: content));
    } else if (action == 'togglePreview') {
      onLivePreviewChanged?.call(!livePreview);
    } else if (action == 'process') {
      onExecute?.call();
    } else if (action == 'cancelStreaming') {
      onCancelStreaming?.call();
    } else if (action == 'share') {
      await SharePlus.instance.share(ShareParams(text: content, title: label));
    } else if (action == 'save') {
      final format = await _exporter.showFormatPicker(context);
      if (format != null) {
        final savedPath = await _exporter.saveAs(
          content,
          format: format,
          isMarkdown: true,
        );
        onSaved?.call(savedPath != null);
      }
    } else if (action == 'saveTxt') {
      final savedPath = await _exporter.saveAsText(content);
      onSaved?.call(savedPath != null);
    } else if (action == 'saveAny') {
      final savedPath = await _exporter.saveAsAny(content);
      onSaved?.call(savedPath != null);
    } else if (action == 'savePdf') {
      final savedPath = await _exporter.saveAsPdf(
        content,
        isMarkdown: format == IOFormat.markdown,
      );
      onSaved?.call(savedPath != null);
    } else if (action == 'saveHtml') {
      final savedPath = await _exporter.saveAsHtml(
        content,
        isMarkdown: format == IOFormat.markdown,
      );
      onSaved?.call(savedPath != null);
    } else if (action == 'printPdf') {
      await Printing.layoutPdf(
        onLayout: (format) async {
          final pdf = pw.Document();
          pdf.addPage(pw.Page(build: (context) => pw.Text(content)));
          return pdf.save();
        },
      );
    }

    onButtonPressed?.call(action);
  }

  Widget buildText() {
    return Base64ImageField(controller: controller, fontSize: fontSize);
  }

  Widget _buildMarkdownOutput(BuildContext context) {
    // Format content based on IOFormat
    final String data = format == IOFormat.text
        ? "```text\n$content\n```"
        : content;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Configure base markdown theme
    final baseConfig = isDark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;

    // Select appropriate syntax highlighting theme
    final highlightTheme = isDark ? atomOneDarkTheme : githubTheme;

    // Ensure code blocks have transparent backgrounds
    final adjustedTheme = Map<String, TextStyle>.from(highlightTheme);
    adjustedTheme['root'] = (adjustedTheme['root'] ?? const TextStyle())
        .copyWith(
          backgroundColor: Colors.transparent,
          color:
              adjustedTheme['root']?.color ??
              (isDark ? Colors.white : Colors.black),
        );

    /// Code block wrapper with copy functionality, language label, and image support
    Widget codeWrapper(Widget child, String text, String? language) {
      Widget content = child;

      // Handle different formats
      if (language != null) {
        final lang = language.toLowerCase();

        // SVG Support
        if (lang == 'svg') {
          try {
            content = _buildSvgViewer(text);
          } catch (e) {
            content = _buildErrorContainer('Error rendering SVG:\n$e');
          }
        }
        // Image formats (base64)
        else if (_isImageFormat(lang)) {
          try {
            content = _buildImageViewer(context, text, lang);
          } catch (e) {
            content = _buildErrorContainer('Error rendering $lang image:\n$e');
          }
        }
        // Data URL images
        else if (lang == 'dataurl' && text.trim().startsWith('data:image/')) {
          try {
            content = _buildDataUrlViewer(context, text);
          } catch (e) {
            content = _buildErrorContainer('Error rendering image:\n$e');
          }
        }
      }
      // Auto-detect base64 images without language tag
      else if (_looksLikeBase64Image(text)) {
        try {
          final detectedFormat = _detectImageFormat(text);
          content = _buildImageViewer(context, text, detectedFormat);
        } catch (e) {
          content = child; // Fall back to original if detection fails
        }
      } else if (wrapCodeText) {
        content = LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth, // enforce wrapping
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    50,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(50),
                    width: 1.0,
                  ),
                ),
                child: ProxyRichText(TextSpan(text: text)),
              ), // keep original styles and behavior
            );
          },
        );
      }

      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(50),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.only(
              top: 12.0,
              bottom: 4.0,
              right: 6.0,
              left: 6.0,
            ),
            child: content,
          ),
          // Language label (top-left)
          if (language != null && language.isNotEmpty)
            Positioned(
              left: 8.0,
              top: 8.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(200),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(80),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  language.toLowerCase(),
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          // Copy/Save/Share buttons (top-right)
          Positioned(
            right: 4.0,
            top: 0.0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(100),
                  borderRadius: BorderRadius.circular(18.0),
                ),
                child: SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'copy',
                      icon: Icon(Icons.content_copy, size: 16),
                      tooltip: 'Copy',
                    ),
                    ButtonSegment<String>(
                      value: 'save',
                      icon: Icon(Icons.save, size: 16),
                      tooltip: 'Save',
                    ),
                    ButtonSegment<String>(
                      value: 'share',
                      icon: Icon(Icons.share, size: 16),
                      tooltip: 'Share',
                    ),
                  ],
                  selected: const <String>{},
                  onSelectionChanged: (Set<String> newSelection) {
                    if (newSelection.isNotEmpty) {
                      final choice = newSelection.first;
                      switch (choice) {
                        case 'copy':
                          _copyToClipboard(context, text, language);
                          break;
                        case 'save':
                          _saveContent(context, text, language);
                          break;
                        case 'share':
                          shareText(text, label);
                          break;
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Configure markdown with syntax highlighting and code wrapper
    final configWithHighlight = baseConfig.copy(
      configs: [
        PreConfig(
          theme: adjustedTheme,
          wrapper: codeWrapper,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );

    final generator = MarkdownGenerator(
      inlineSyntaxList: [Base64ImageSyntax()],
      generators: [base64ImageGenerator2], // This now works correctly
    );

    // Use MarkdownBlock with SingleChildScrollView for auto-scroll support
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        scrollbars: true,
        overscroll: false,
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        child: MarkdownBlock(
          data: data,
          config: configWithHighlight,
          generator: generator,
        ),
      ),
    );
  }

  // Enhanced save function for images and text
  void _saveContent(BuildContext context, String text, String? language) async {
    final lang = language?.toLowerCase();

    // Handle image formats
    if (lang != null && (_isImageFormat(lang) || lang == 'dataurl')) {
      await _saveImageFile(context, text, lang);
    }
    // Handle SVG
    else if (lang == 'svg') {
      await _saveTextFile(context, text, 'svg');
    }
    // Handle regular text
    else {
      await _saveTextFile(
        context,
        text,
        languageStringToFileExtension(language ?? 'txt'),
      );
    }
  }

  // Save image files as binary
  Future<void> _saveImageFile(
    BuildContext context,
    String content,
    String format,
  ) async {
    try {
      Uint8List bytes;
      String extension;

      if (format == 'dataurl' && content.startsWith('data:image/')) {
        final parts = content.split(',');
        if (parts.length != 2) throw Exception('Invalid data URL');

        final mimeMatch = RegExp(r'data:image/(\w+)').firstMatch(parts[0]);
        extension = mimeMatch?.group(1) ?? 'png';
        bytes = base64Decode(parts[1]);
      } else {
        final cleanBase64 = content
            .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
            .replaceAll(RegExp(r'\s+'), '');

        bytes = base64Decode(cleanBase64);
        extension = format;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'image_$timestamp.$extension';

      // This returns null if user cancels, path if successful
      final savedPath = await FileExporter.saveBinaryFile(bytes, filename);

      if (context.mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved as $filename'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // User cancelled - don't show any message or show cancelled message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save text files
  Future<void> _saveTextFile(
    BuildContext context,
    String content,
    String extension,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'file_$timestamp.$extension';

      await FileExporter.saveTextFile(content, filename);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved as $filename'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build SVG viewer
  Widget _buildSvgViewer(String svgText) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: SvgPicture.string(
        svgText,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Container(
          height: 300,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  // Build image viewer for base64 data
  Widget _buildImageViewer(
    BuildContext context,
    String base64Text,
    String format,
  ) {
    final cleanBase64 = _cleanBase64(base64Text);
    final bytes = base64Decode(cleanBase64);
    final detectedFormat = (format.isEmpty || format == 'dataurl')
        ? _detectImageFormatFromBytes(bytes)
        : format;
    return UnifiedBase64ImageViewer(bytes: bytes, format: detectedFormat);
  }

  // Build data URL viewer
  Widget _buildDataUrlViewer(BuildContext context, String dataUrl) {
    final parts = dataUrl.split(',');
    if (parts.length != 2) throw Exception('Invalid data URL format');

    final mimeMatch = RegExp(r'data:image/(\w+)').firstMatch(parts[0]);
    final format = mimeMatch?.group(1) ?? 'unknown';

    return _buildImageViewer(context, parts[1], format);
  }

  // Build error container
  Widget _buildErrorContainer(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Helper functions
  bool _isImageFormat(String lang) {
    const imageFormats = [
      'png',
      'jpg',
      'jpeg',
      'gif',
      'bmp',
      'webp',
      'ico',
      'tiff',
      'tif',
    ];
    return imageFormats.contains(lang);
  }

  bool _looksLikeBase64Image(String text) {
    final cleaned = text.trim();
    if (cleaned.length < 100) return false;
    if (!RegExp(r'^[A-Za-z0-9+/]+=*$').hasMatch(cleaned)) return false;

    try {
      final bytes = base64Decode(cleaned);
      return _hasImageSignature(bytes);
    } catch (e) {
      return false;
    }
  }

  bool _hasImageSignature(Uint8List bytes) {
    if (bytes.length < 8) return false;

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // GIF: 47 49 46
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes.length > 11 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // ICO: 00 00 01 00
    if (bytes[0] == 0x00 &&
        bytes[1] == 0x00 &&
        bytes[2] == 0x01 &&
        bytes[3] == 0x00) {
      return true;
    }

    return false;
  }

  String _detectImageFormat(String base64Text) {
    try {
      final bytes = base64Decode(_cleanBase64(base64Text));

      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'jpg';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'gif';
      }
      if (bytes[0] == 0x42 && bytes[1] == 0x4D) return 'bmp';
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes.length > 11 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'webp';
      }
      if (bytes[0] == 0x00 &&
          bytes[1] == 0x00 &&
          bytes[2] == 0x01 &&
          bytes[3] == 0x00) {
        return 'ico';
      }

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  String _cleanBase64(String base64Text) {
    return base64Text
        .replaceAll(RegExp(r'data:image/[^;]+;base64,'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  void _pasteTestText() {
    if (controller != null) {
      controller!.text = testText;
    }
  }

  String languageStringToFileExtension(String languageIdentifier) {
    // Trim whitespace for standardization
    final String lang = languageIdentifier.trim();

    // If the input is empty after trimming, return a default
    if (lang.isEmpty) {
      return 'txt';
    }

    // Convert to lowercase for case-insensitive checks
    final String lowerLang = lang.toLowerCase();

    // A map for language identifiers that need transformation.
    const Map<String, String> languageMap = {
      // Full names to common extensions
      'javascript': 'js',
      'typescript': 'ts',
      'python': 'py',
      'c++': 'cpp',
      'cxx': 'cpp',
      'cc': 'cpp',
      'csharp': 'cs',
      'golang': 'go',
      'kotlin': 'kt',
      'ruby': 'rb',
      'perl': 'pl',
      'markdown': 'md',
      'powershell': 'ps1',
      'makefile': 'mk', // Common alternative
      'dockerfile': 'dockerfile', // Common convention
      'objective-c': 'm', // Or 'mm' for Objective-C++
      'matlab': 'm',
      'solidity': 'sol',
      'gql': 'graphql',
      'yaml': 'yml', // Common alternative
      'shell': 'sh', // Common alternative
      'zsh': 'zsh',
      'fish': 'fish',
      'text': 'txt',
      // Add more specific transformations as needed
    };

    // Check if the lowercase version needs transformation.
    if (languageMap.containsKey(lowerLang)) {
      return languageMap[lowerLang]!;
    }

    // If not found in the map, clean the original identifier and return it.
    // This handles perfect matches (html->html) and unknown identifiers.
    // Remove characters that are typically not part of file extensions.
    String cleanedIdentifier = lang.replaceAll(RegExp(r'[^a-zA-Z0-9#+-]'), '');

    // Ensure it's not empty and not too long after cleaning.
    if (cleanedIdentifier.isEmpty) {
      return 'txt'; // Fallback
    }
    if (cleanedIdentifier.length > 15) {
      // Slightly longer limit
      cleanedIdentifier = cleanedIdentifier.substring(0, 15);
    }

    // Return the cleaned identifier, converted to lowercase for consistency.
    return cleanedIdentifier.toLowerCase();
  }

  void saveText(String text, String? extension) async {
    final savedPath = await _exporter.saveAsExtension(
      text,
      extension: extension ?? 'txt',
    );
    onSaved?.call(savedPath != null);
  }

  void openFile() async {
    final str = await FileExporter.openFile(maxLength: 128000);
    if (str.isNotEmpty) controller?.text = str;
  }

  void shareText(String text, String title) async {
    SharePlus.instance.share(ShareParams(text: text, title: title));
  }

  /// Helper method to handle clipboard operations
  void _copyToClipboard(BuildContext context, String text, String? language) {
    // Trim trailing whitespace/newlines
    final trimmedText = text.trimRight();

    Clipboard.setData(ClipboardData(text: trimmedText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16.0),
            const SizedBox(width: 8.0),
            Text('Copied ${language ?? "code"} to clipboard'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  WidgetSpan base64ImageGenerator(
    m.Element node,
    MarkdownConfig config,
    TextStyle? style,
  ) {
    final dataUrl = node.attributes['src'] ?? '';
    final alt = node.attributes['alt'] ?? '';

    try {
      final bytes = base64Decode(dataUrl.split(',').last);
      return WidgetSpan(
        child: GestureDetector(
          onTap: () {
            // Optional full screen view
          },
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) {
              return Text('[Invalid image]', style: style);
            },
          ),
        ),
      );
    } catch (_) {
      return WidgetSpan(
        child: Text('[Invalid base64 image: $alt]', style: style),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (!isOutput) ...[
                  Tooltip(
                    message: 'Paste Test Text',
                    child: IconButton(
                      icon: const Icon(Icons.text_snippet),
                      onPressed: _pasteTestText,
                    ),
                  ),
                  Tooltip(
                    message: 'Paste from clipboard',
                    child: IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: enableActions
                          ? () => _handleAction(context, 'paste')
                          : null,
                    ),
                  ),
                  Tooltip(
                    message: 'Load from File',
                    child: IconButton(
                      icon: const Icon(Icons.file_open),
                      onPressed: openFile,
                    ),
                  ),
                  Tooltip(
                    message: 'Clear text',
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: enableActions
                          ? () => _handleAction(context, 'clear')
                          : null,
                    ),
                  ),
                  if (compactProcessButton && enableActions && !livePreview)
                    Tooltip(
                      message: 'Process',
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _handleAction(context, 'process'),
                      ),
                    ),
                ] else ...[
                  if (isStreaming && onCancelStreaming != null) ...[
                    Tooltip(
                      message: 'Cancel streaming',
                      child: IconButton(
                        onPressed: isCancelStreaming ? null : onCancelStreaming,
                        icon: SizedBox(
                          width: 24,
                          height: 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.rectangle, // small stop icon
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  Tooltip(
                    message: 'Copy to clipboard',
                    child: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: enableActions && content.isNotEmpty
                          ? () => _handleAction(context, 'copy')
                          : null,
                    ),
                  ),
                  Tooltip(
                    message: wrapCodeText
                        ? 'Disable text wrap'
                        : 'Enable text wrap',
                    child: IconButton(
                      icon: Icon(wrapCodeText ? Icons.wrap_text : Icons.code),
                      onPressed: () => onWrapToggled?.call(!wrapCodeText),
                    ),
                  ),
                  Tooltip(
                    message: 'Print',
                    child: IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: enableActions && content.isNotEmpty
                          ? () => _handleAction(context, 'printPdf')
                          : null,
                    ),
                  ),
                  Tooltip(
                    message: 'Save to file',
                    child: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: enableActions && content.isNotEmpty
                          ? () => _handleAction(context, 'save')
                          : null,
                    ),
                  ),
                  Tooltip(
                    message: 'Share',
                    child: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: enableActions && content.isNotEmpty
                          ? () => _handleAction(context, 'share')
                          : null,
                    ),
                  ),
                  showSaveJSButton
                      ? Tooltip(
                          message: 'Save Tool to library',
                          child: IconButton(
                            icon: const Icon(Icons.save_alt),
                            onPressed: content.isNotEmpty ? onSaveJS : null,
                          ),
                        )
                      : Row(
                          children: [
                            const Text('Live Preview'),
                            const SizedBox(width: 6),
                            Switch(
                              value: livePreview,
                              onChanged: enableActions
                                  ? (v) =>
                                        _handleAction(context, 'togglePreview')
                                  : null,
                            ),
                          ],
                        ),
                ],
              ],
            ),
          ),

          // Text / Markdown panel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: isOutput ? _buildMarkdownOutput(context) : buildText(),
            ),
          ),

          // Full Process button under input
          if (!isOutput && !livePreview && !compactProcessButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: statusMessage != null && statusMessage!.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withAlpha(100),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(statusMessage!),
                        )
                      : const SizedBox(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: isStreaming
                        ? Tooltip(
                            message: 'Cancel streaming',
                            child: ElevatedButton(
                              onPressed: isCancelStreaming
                                  ? null
                                  : onCancelStreaming,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(80, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),

                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            shape: BoxShape
                                                .rectangle, // square stop icon
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Cancel'),
                                ],
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: enableActions
                                ? () => _handleAction(context, 'process')
                                : null,
                            child: const Text('Process'),
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
