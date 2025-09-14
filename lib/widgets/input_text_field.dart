import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class Base64ImageField extends StatelessWidget {
  final TextEditingController? controller;
  final double? fontSize;
  final double maxWidth;
  final double maxHeight;

  const Base64ImageField({
    super.key,
    this.controller,
    this.maxWidth = 300,
    this.maxHeight = 300,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    // If controller is null, just show a normal TextField
    if (controller == null) {
      return TextField(
        minLines: null,
        maxLines: null,
        textAlign: TextAlign.start,
        textAlignVertical: TextAlignVertical.top,
        expands: true,
        style: (!kIsWeb && Platform.isWindows)
            ? TextStyle(fontFamily: 'Segoe UI Emoji', fontSize: fontSize)
            : null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        ),
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, _, __) {
        final text = controller!.text;

        if (text.startsWith('data:image/')) {
          try {
            final base64Data = text.split(',')[1];
            final bytes = base64Decode(base64Data);

            return FutureBuilder<Size>(
              future: _getImageSize(bytes),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.memory(bytes, fit: BoxFit.scaleDown),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          } catch (e) {
            return const Text('Invalid image data');
          }
        }

        return TextField(
          controller: controller,
          minLines: null,
          maxLines: null,
          textAlign: TextAlign.start,
          textAlignVertical: TextAlignVertical.top,
          expands: true,
          style: (!kIsWeb && Platform.isWindows)
              ? TextStyle(fontFamily: 'Segoe UI Emoji', fontSize: fontSize)
              : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ),
          ),
        );
      },
    );
  }

  Future<Size> _getImageSize(Uint8List bytes) async {
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }
}
