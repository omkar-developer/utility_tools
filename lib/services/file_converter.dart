import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

enum ExportFormat {
  txt('Text File', 'txt'),
  pdf('PDF Document', 'pdf'),
  html('HTML Document', 'html'),
  md('Markdown File', 'md'),
  any('Any File', 'any');

  const ExportFormat(this.displayName, this.extension);
  final String displayName;
  final String extension;
}

class FileExporter {
  /// Enhanced save as text (your existing function improved)
  Future<String?> saveAsText(
    String text, {
    String defaultFileName = 'output.txt',
  }) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(text));

    final String? savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Text File',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['txt'],
      bytes: bytes,
    );

    return savedPath;
  }

  Future<String?> saveAsAny(
    String text, {
    String defaultFileName = 'output',
  }) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(text));

    final String? savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save File',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['*'],
      bytes: bytes,
    );

    return savedPath;
  }

  Future<String?> saveAsExtension(
    String text, {
    String defaultFileName = 'output',
    String extension = 'txt',
  }) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(text));

    final String? savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save File',
      fileName: '$defaultFileName.$extension',
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );

    return savedPath;
  }

  static Future<Uint8List?> openBinaryFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true, // ensures web returns bytes
    );

    if (result == null) return null;

    final file = result.files.single;

    if (kIsWeb) {
      // Web: just return bytes directly
      if (file.bytes == null) return null;
      return file.bytes!;
    } else {
      // Desktop: read full file from path
      if (file.path == null) return null;
      final io.File f = io.File(file.path!);
      return await f.readAsBytes();
    }
  }

  static Future<String> openFile({int maxLength = 50000}) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return '';

    if (kIsWeb) {
      // Web implementation
      return _handleWebFile(result.files.single, maxLength);
    } else {
      // Desktop implementation
      return _handleDesktopFile(result.files.single, maxLength);
    }
  }

  static Future<String> _handleWebFile(PlatformFile file, int maxLength) async {
    if (file.bytes == null) return '[Error: Could not read file]';

    final bytes = file.bytes!;

    // Check if binary (crude check on first 512 bytes or entire file if smaller)
    final checkBytes = bytes.length > 512 ? bytes.sublist(0, 512) : bytes;
    bool isBinary = checkBytes.any((b) => b == 0);

    if (isBinary) {
      // Check if it's an image by extension
      final ext = p.extension(file.name).toLowerCase();
      const imageExts = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

      if (imageExts.contains(ext)) {
        final base64Str = base64Encode(bytes);
        final mimeType = _getMimeType(ext);
        return 'data:$mimeType;base64,$base64Str';
      }

      return '[Error: File appears to be binary, not text]';
    }

    // Handle as text file
    try {
      String content = utf8.decode(bytes);
      if (content.length > maxLength) {
        content = '${content.substring(0, maxLength)}\n\n[...truncated]';
      }
      return content;
    } catch (e) {
      return '[Error: Could not decode file as UTF-8 text]';
    }
  }

  static Future<String> _handleDesktopFile(
    PlatformFile platformFile,
    int maxLength,
  ) async {
    if (platformFile.path == null) return '';

    final file = File(platformFile.path!);
    final raf = await file.open();

    // Read first 512 bytes to check if binary
    final headerBytes = await raf.read(512);
    await raf.close();

    bool isBinary = headerBytes.any((b) => b == 0);

    if (isBinary) {
      // Check if it's an image by extension
      final ext = p.extension(file.path).toLowerCase();
      const imageExts = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

      if (imageExts.contains(ext)) {
        // Read whole file as bytes and convert to base64
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final mimeType = _getMimeType(ext);
        return 'data:$mimeType;base64,$base64Str';
      }

      return '[Error: File appears to be binary, not text]';
    }

    // If it's text: safely stream UTF-8
    final reader = file.openRead();
    final buffer = StringBuffer();
    int totalRead = 0;
    bool truncated = false;

    try {
      await for (var chunk in reader.transform(utf8.decoder)) {
        totalRead += chunk.length;
        if (totalRead > maxLength) {
          buffer.write(
            chunk.substring(0, chunk.length - (totalRead - maxLength)),
          );
          truncated = true;
          break;
        } else {
          buffer.write(chunk);
        }
      }
    } catch (e) {
      return '[Error: Could not read file as text]';
    }

    if (truncated) buffer.write('\n\n[...truncated]');
    return buffer.toString();
  }

  static String _getMimeType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Enhanced save as PDF with better markdown support
  Future<String?> saveAsPdf(
    String content, {
    String fileName = 'output.pdf',
    bool isMarkdown = false,
  }) async {
    final pdf = pw.Document();

    if (isMarkdown) {
      await _addMarkdownToPdf(pdf, content);
    } else {
      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Paragraph(
              text: content,
              style: pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            ),
          ],
        ),
      );
    }

    final Uint8List bytes = await pdf.save();

    final String? savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );

    return savedPath;
  }

  /// New: Save as HTML with GPT-style theming
  Future<String?> saveAsHtml(
    String content, {
    String fileName = 'output.html',
    bool isMarkdown = false,
  }) async {
    String htmlContent;

    if (isMarkdown) {
      // Convert markdown to HTML
      htmlContent = md.markdownToHtml(content);
      htmlContent = _wrapInHtmlTemplate(htmlContent);
    } else {
      // Convert plain text to HTML
      htmlContent = _wrapInHtmlTemplate('<pre>${_escapeHtml(content)}</pre>');
    }

    final Uint8List bytes = Uint8List.fromList(utf8.encode(htmlContent));

    final String? savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save HTML',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['html'],
      bytes: bytes,
    );

    return savedPath;
  }

  /// New: Save as Markdown
  Future<String?> saveAsMarkdown(
    String content, {
    String fileName = 'output.md',
  }) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));

    final String? savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Markdown',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['md'],
      bytes: bytes,
    );

    return savedPath;
  }

  /// Universal save function - one function for all formats
  Future<String?> saveAs(
    String content, {
    required ExportFormat format,
    bool isMarkdown = false,
    String? fileName,
  }) async {
    final String defaultFileName = fileName ?? 'output.${format.extension}';

    switch (format) {
      case ExportFormat.txt:
        return await saveAsText(content, defaultFileName: defaultFileName);
      case ExportFormat.pdf:
        return await saveAsPdf(
          content,
          fileName: defaultFileName,
          isMarkdown: isMarkdown,
        );
      case ExportFormat.html:
        return await saveAsHtml(
          content,
          fileName: defaultFileName,
          isMarkdown: isMarkdown,
        );
      case ExportFormat.md:
        return await saveAsMarkdown(content, fileName: defaultFileName);
      case ExportFormat.any:
        return await saveAsAny(content, defaultFileName: defaultFileName);
    }
  }

  /// Show format picker dialog
  Future<ExportFormat?> showFormatPicker(BuildContext context) async {
    return await showDialog<ExportFormat>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Format'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ExportFormat.values.map((format) {
              IconData icon;
              switch (format) {
                case ExportFormat.txt:
                  icon = Icons.text_snippet_outlined;
                  break;
                case ExportFormat.pdf:
                  icon = Icons.picture_as_pdf_outlined;
                  break;
                case ExportFormat.html:
                  icon = Icons.web_outlined;
                  break;
                case ExportFormat.md:
                  icon = Icons.code_outlined;
                  break;
                case ExportFormat.any:
                  icon = Icons.file_download_outlined;
                  break;
              }

              return ListTile(
                leading: Icon(icon),
                title: Text(format.displayName),
                subtitle: Text('.${format.extension}'),
                onTap: () => Navigator.of(context).pop(format),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Helper methods
  Future<void> _addMarkdownToPdf(pw.Document pdf, String content) async {
    final lines = content.split('\n');
    final List<pw.Widget> widgets = [];

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      // Headers
      if (line.startsWith('#')) {
        final level = line.indexOf(' ');
        if (level > 0) {
          final text = line.substring(level + 1);
          final fontSize = 20.0 - (level - 1) * 2;

          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
              child: pw.Text(
                text,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
        }
      }
      // Lists
      else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '• ',
                  style: pw.TextStyle(fontSize: 12),
                ), // Fixed bullet character
                pw.Expanded(
                  child: pw.Text(
                    line.substring(2),
                    style: pw.TextStyle(fontSize: 12, lineSpacing: 1.4),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Blockquotes
      else if (line.startsWith('> ')) {
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                  width: 3,
                  color: PdfColor.fromHex('#6b7280'),
                ),
              ),
              color: PdfColor.fromHex('#f3f4f6'),
            ),
            child: pw.Text(
              line.substring(2),
              style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
            ),
          ),
        );
      }
      // Code blocks (basic support)
      else if (line.startsWith('```')) {
        // Skip the opening line, but you could enhance this to handle code blocks
        continue;
      }
      // Regular paragraphs
      else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              line,
              style: pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            ),
          ),
        );
      }
    }

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(40),
        build: (context) => widgets,
      ),
    );
  }

  String _wrapInHtmlTemplate(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        :root {
            --bg-color: #ffffff;
            --text-color: #374151;
            --code-bg: #f6f8fa;
            --code-border: #d0d7de;
            --blockquote-border: #d0d7de;
            --link-color: #0969da;
            --heading-color: #1f2937;
            --table-border: #d1d5db;
        }
        
        @media (prefers-color-scheme: dark) {
            :root {
                --bg-color: #1a1a1a;
                --text-color: #e5e7eb;
                --code-bg: #2d333b;
                --code-border: #444c56;
                --blockquote-border: #444c56;
                --link-color: #58a6ff;
                --heading-color: #f9fafb;
                --table-border: #374151;
            }
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            line-height: 1.6;
            color: var(--text-color);
            background-color: var(--bg-color);
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            font-size: 16px;
        }
        
        h1, h2, h3, h4, h5, h6 {
            color: var(--heading-color);
            font-weight: 600;
            margin: 1.5rem 0 1rem 0;
        }
        
        code {
            background-color: var(--code-bg);
            padding: 0.2rem 0.4rem;
            border-radius: 4px;
            font-family: 'SF Mono', Monaco, 'Cascadia Code', monospace;
            font-size: 0.875rem;
            border: 1px solid var(--code-border);
        }
        
        pre {
            background-color: var(--code-bg);
            padding: 1rem;
            border-radius: 8px;
            overflow-x: auto;
            margin: 1rem 0;
            border: 1px solid var(--code-border);
        }
        
        pre code {
            background: none;
            padding: 0;
            border: none;
        }
        
        blockquote {
            border-left: 4px solid var(--blockquote-border);
            padding-left: 1rem;
            margin: 1rem 0;
            font-style: italic;
            opacity: 0.8;
        }
        
        a {
            color: var(--link-color);
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 1rem 0;
        }
        
        th, td {
            border: 1px solid var(--table-border);
            padding: 0.5rem;
            text-align: left;
        }
        
        th {
            background-color: var(--code-bg);
            font-weight: 600;
        }
    </style>
</head>
<body>
$content
</body>
</html>''';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  static Future<String?> saveBinaryFile(
    Uint8List bytes,
    String filename,
  ) async {
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Save File',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['*'],
      bytes: bytes,
    );
  }

  static Future<String?> saveTextFile(String content, String filename) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Save Text File',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['Any'],
      bytes: bytes,
    );
  }
}
