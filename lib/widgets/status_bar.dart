import 'package:flutter/material.dart';

enum ToolStatus {
  idle, // No tool selected or ready state
  processing, // Tool is currently executing
  success, // Tool executed successfully
  warning, // Tool completed with warnings
  error, // Tool execution failed
}

class StatusBar extends StatelessWidget {
  final String leftText;
  final String? centerText;
  final String? rightText;
  final ToolStatus status;

  const StatusBar({
    super.key,
    required this.leftText,
    this.centerText,
    this.rightText,
    this.status = ToolStatus.idle,
  });

  Icon? _statusIcon(Color iconColor) {
    switch (status) {
      case ToolStatus.processing:
        return Icon(Icons.sync, size: 16, color: iconColor);
      case ToolStatus.success:
        return Icon(Icons.check_circle, size: 16, color: iconColor);
      case ToolStatus.error:
        return Icon(Icons.error, size: 16, color: iconColor);
      default:
        return null;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (status) {
      case ToolStatus.processing:
        return Theme.of(context).colorScheme.primary;
      case ToolStatus.success:
        return Colors.green;
      case ToolStatus.error:
        return Colors.red;
      case ToolStatus.warning:
        return Colors.orange;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _statusColor(context);
    final textStyle = TextStyle(color: iconColor, fontWeight: FontWeight.w600);

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Left section (status + text)
          Expanded(
            child: Row(
              children: [
                if (_statusIcon(iconColor) != null) ...[
                  _statusIcon(iconColor)!,
                  const SizedBox(width: 4),
                ],
                Text(
                  leftText,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Right section
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                rightText ?? '',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withAlpha((0.5 * 255).toInt()),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
