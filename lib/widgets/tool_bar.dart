import 'package:flutter/material.dart';
import '../models/tool.dart';

class ToolBar extends StatelessWidget {
  final List<Tool> tools;
  final Tool? selectedTool;
  final void Function(Tool) onToolSelected;
  final Widget? firstWidget;

  const ToolBar({
    super.key,
    required this.tools,
    required this.onToolSelected,
    this.selectedTool,
    this.firstWidget,
  });

  bool isSelected(Tool tool) => tool == selectedTool;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    // For very small screens or when there are many tools, use scrollable layout
    final useScrollableLayout = isMobile && tools.length > 4;

    if (useScrollableLayout) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Row(
          children: [
            for (final tool in tools)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: _buildToolButton(context, tool, true),
              ),
          ],
        ),
      );
    }

    // Desktop and tablet: Use wrap layout to show all tools
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 2.0 : 4.0),
      child: Wrap(
        spacing: isMobile ? 4.0 : 6.0,
        runSpacing: isMobile ? 4.0 : 6.0,
        alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (firstWidget != null) firstWidget!,
          if (firstWidget != null && tools.isNotEmpty)
            Container(
              width: 1,
              height: 24,
              color: Theme.of(context).dividerColor,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
          for (final tool in tools) _buildToolButton(context, tool, isMobile),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, Tool tool, bool isMobile) {
    final theme = Theme.of(context);
    final selected = isSelected(tool);

    if (isMobile) {
      // Mobile: Compact button style
      return SizedBox(
        height: 36,
        child: Tooltip(
          message: tool.description,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              foregroundColor: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              elevation: selected ? 2 : 1,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withAlpha(
                          (0.3 * 255).toInt(),
                        ),
                  width: 1,
                ),
              ),
            ),
            icon: Icon(tool.icon, size: 16),
            label: Text(
              tool.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            onPressed: () => onToolSelected(tool),
          ),
        ),
      );
    }

    // Desktop/Tablet: Larger button with better spacing
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Tooltip(
        message: tool.description,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            foregroundColor: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            elevation: selected ? 3 : 1,
            shadowColor: selected
                ? theme.colorScheme.primary.withAlpha((0.3 * 255).toInt())
                : Colors.black12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withAlpha((0.2 * 255).toInt()),
                width: selected ? 2 : 1,
              ),
            ),
          ),
          icon: Icon(
            tool.icon,
            size: 20,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
          label: Text(
            tool.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
          onPressed: () => onToolSelected(tool),
        ),
      ),
    );
  }
}

// Alternative version with chip-style buttons for very dense layouts
class CompactToolBar extends StatelessWidget {
  final List<Tool> tools;
  final Tool? selectedTool;
  final void Function(Tool) onToolSelected;
  final Widget? firstWidget;

  const CompactToolBar({
    super.key,
    required this.tools,
    required this.onToolSelected,
    this.selectedTool,
    required this.firstWidget,
  });

  bool isSelected(Tool tool) => tool == selectedTool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: [
          if (firstWidget != null) firstWidget!,
          for (final tool in tools)
            FilterChip(
              selected: isSelected(tool),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tool.icon,
                    size: 16,
                    color: isSelected(tool)
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tool.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected(tool)
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              checkmarkColor: theme.colorScheme.onPrimary,
              side: BorderSide(
                color: isSelected(tool)
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
                width: 1,
              ),
              onSelected: (_) => onToolSelected(tool),
            ),
        ],
      ),
    );
  }
}
