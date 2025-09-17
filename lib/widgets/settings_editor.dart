import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';

class SettingsEditor extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Map<String, dynamic>? settingsHints;
  final void Function(Map<String, dynamic>) onChanged;
  final bool liveUpdate;
  final bool showApplyButton;
  final bool useColumnMode;
  final bool useGrid;
  final double? cardWidth;
  final double? cardHeight;
  final double? labelWidth;
  final int columnCount;

  const SettingsEditor({
    super.key,
    required this.settings,
    required this.onChanged,
    this.liveUpdate = false,
    this.settingsHints,
    this.useColumnMode = false,
    this.cardWidth,
    this.cardHeight,
    this.labelWidth,
    this.showApplyButton = true,
    this.columnCount = 2,
    this.useGrid = false,
  });

  @override
  State<SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends State<SettingsEditor> {
  late Map<String, dynamic> currentSettings;
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    currentSettings = Map<String, dynamic>.from(widget.settings);

    for (final entry in currentSettings.entries) {
      if (entry.value is String || entry.value is num) {
        controllers[entry.key] = TextEditingController(
          text: entry.value.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateSetting(String key, dynamic value) {
    setState(() => currentSettings[key] = value);
    widget.onChanged(currentSettings);
  }

  Widget _buildEditor(BuildContext context, String key, dynamic value) {
    final hint = widget.settingsHints?[key];
    final hintMap = (hint != null && hint is Map<String, dynamic>)
        ? hint
        : null;
    final label = hintMap?['label'] as String? ?? _formatLabel(key);
    final helpText = hintMap?['help'] as String?;

    final showLabel = hintMap?['show_label'] ?? true; // Default to true

    if (!showLabel) {
      // Skip label wrapper, return just the control
      return _buildControl(context, key, value, hintMap ?? {});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (helpText != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: helpText,
                child: GestureDetector(
                  onTapDown: (details) {
                    final RenderBox overlay =
                        Overlay.of(context).context.findRenderObject()
                            as RenderBox;
                    showMenu(
                      context: context,
                      position: RelativeRect.fromRect(
                        details.globalPosition & const Size(48, 48),
                        Offset.zero & overlay.size,
                      ),
                      items: [
                        PopupMenuItem(
                          enabled: false,
                          child: Container(
                            width: 250, // Adjust width as needed
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              helpText,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                      elevation: 8,
                    );
                  },
                  child: const Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        _buildControl(context, key, value, hintMap ?? {}),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildEditorColumnMode(String key, dynamic value) {
    final hint = widget.settingsHints?[key];
    final hintMap = (hint != null && hint is Map<String, dynamic>)
        ? hint
        : null;
    final label = hintMap?['label'] as String? ?? _formatLabel(key);
    final helpText = hintMap?['help'] as String?;

    final showLabel = hintMap?['show_label'] ?? true; // Default to true

    if (!showLabel) {
      // Skip label wrapper, return just the control
      return _buildControl(context, key, value, hintMap ?? {});
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Label section (constant width)
        SizedBox(
          width: 200, // Constant width for labels
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Tooltip(
                      message: label,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (helpText != null) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: helpText,
                      child: GestureDetector(
                        onTapDown: (details) {
                          final RenderBox overlay =
                              Overlay.of(context).context.findRenderObject()
                                  as RenderBox;
                          showMenu(
                            context: context,
                            position: RelativeRect.fromRect(
                              details.globalPosition & const Size(48, 48),
                              Offset.zero & overlay.size,
                            ),
                            items: [
                              PopupMenuItem(
                                enabled: false,
                                child: Container(
                                  width: 250,
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    helpText,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                            elevation: 8,
                          );
                        },
                        child: const Icon(
                          Icons.help_outline,
                          size: 24,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 2, color: Colors.grey),
        // Control section (takes remaining space)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _buildControl(context, key, value, hintMap ?? {}),
          ),
        ),
      ],
    );
  }

  Widget _buildControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final type = hint['type'];

    // If explicit type is provided, use it
    if (type != null) {
      switch (type) {
        case 'bool':
          return _buildBoolControl(context, key, value);
        case 'number':
          return _buildNumberControl(context, key, value, hint);
        case 'spinner':
          return _buildSpinnerControl(context, key, value, hint);
        case 'dropdown':
          return _buildDropdownControl(context, key, value, hint);
        case 'multiline':
          return _buildMultilineControl(context, key, value, hint);
        case 'slider':
          return _buildSliderControl(context, key, value, hint);
        case 'text':
          return _buildTextControl(context, key, value, hint);
        case 'multiselect':
          return _buildMultiSelectControl(context, key, value, hint);
        case 'color':
          return _buildColorControl(context, key, value, hint);
        case 'date':
          return _buildDateControl(context, key, value, hint);
        case 'time':
          return _buildTimeControl(context, key, value, hint);
        case 'range':
          return _buildRangeControl(context, key, value, hint);
        case 'file':
          return _buildFileControl(context, key, value, hint);
        case 'custom':
          final builder =
              hint['builder']
                  as Widget Function(
                    BuildContext,
                    String,
                    dynamic,
                    Map<String, dynamic>,
                    Function,
                  )?;
          if (builder != null) {
            return builder(context, key, value, hint, _updateSetting);
          }
          return _buildFallbackControl(key, value);
        default:
          return _buildFallbackControl(key, value);
      }
    }

    // Auto-deduce type based on value and content
    if (value is bool) {
      return _buildBoolControl(context, key, value);
    } else if (value is int || value is double) {
      return _buildNumberControl(context, key, value, {
        ...hint,
        'decimal': value is double,
      });
    } else if (value is String) {
      // Check for special patterns
      if (value.toString().contains('\n') || value.length > 100) {
        return _buildMultilineControl(context, key, value, {
          ...hint,
          'min_lines': 3,
          'max_lines': 6,
        });
      } else if (value.length > 50) {
        return _buildMultilineControl(context, key, value, {
          ...hint,
          'min_lines': 2,
          'max_lines': 3,
        });
      } else {
        return _buildTextControl(context, key, value, hint);
      }
    } else if (value is List || value is Set) {
      // Could be dropdown with options from list
      return _buildDropdownControl(context, key, value, {
        ...hint,
        'options': value,
      });
    }

    // Fallback for unknown types
    return _buildFallbackControl(key, value);
  }

  // Date Control
  Widget _buildDateControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final currentValue = value as String? ?? '';
    DateTime? selectedDate;

    if (currentValue.isNotEmpty) {
      selectedDate = DateTime.tryParse(currentValue);
    }

    final minDate = hint['min_date'] != null
        ? DateTime.tryParse(hint['min_date'].toString())
        : null;
    final maxDate = hint['max_date'] != null
        ? DateTime.tryParse(hint['max_date'].toString())
        : null;

    String displayText = selectedDate != null
        ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
        : 'Select date...';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: minDate ?? DateTime(1900),
          lastDate: maxDate ?? DateTime(2100),
        );

        if (picked != null) {
          final formattedDate =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          _updateSetting(key, formattedDate);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: selectedDate != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Time Control
  Widget _buildTimeControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final currentValue = value as String? ?? '';
    TimeOfDay? selectedTime;

    if (currentValue.isNotEmpty) {
      final parts = currentValue.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final format24h = hint['format'] == '24h';

    String displayText = selectedTime != null
        ? format24h
              ? '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'
              : selectedTime.format(context)
        : 'Select time...';

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: format24h),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final formattedTime =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          _updateSetting(key, formattedTime);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: selectedTime != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Range Control (dual slider)
  Widget _buildRangeControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final min = (hint['min'] ?? 0).toDouble();
    final max = (hint['max'] ?? 100).toDouble();

    // Value should be a Map with 'start' and 'end' keys
    final currentValue = value is Map ? value : null;
    final startValue = (currentValue?['start'] ?? hint['default_start'] ?? min)
        .toDouble();
    final endValue = (currentValue?['end'] ?? hint['default_end'] ?? max)
        .toDouble();

    RangeValues currentRange = RangeValues(
      startValue.clamp(min, max),
      endValue.clamp(min, max),
    );

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RangeSlider(
              min: min,
              max: max,
              divisions: hint['divisions'] as int?,
              values: currentRange,
              labels: RangeLabels(
                currentRange.start.round().toString(),
                currentRange.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  currentRange = values;
                });
                _updateSetting(key, {'start': values.start, 'end': values.end});
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${currentRange.start.round()}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Max: ${currentRange.end.round()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (hint['show_range'] == true)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    min.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    max.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  // File Control (Dart only)
  Widget _buildFileControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final currentValue = value as String? ?? '';
    final accept = hint['accept'] as List<String>? ?? [];
    final multiple = hint['multiple'] == true;

    String displayText = currentValue.isNotEmpty
        ? currentValue
              .split('/')
              .last // Show filename only
        : multiple
        ? 'Select files...'
        : 'Select file...';

    return InkWell(
      onTap: () async {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: accept.isEmpty ? FileType.any : FileType.custom,
            allowedExtensions: accept.isEmpty
                ? null
                : accept.map((e) => e.replaceFirst('.', '')).toList(),
            allowMultiple: multiple,
          );

          if (result != null) {
            _updateSetting(key, result);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.attach_file,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: currentValue.isNotEmpty
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (accept.isNotEmpty)
              Chip(
                label: Text(
                  accept.join(', '),
                  style: const TextStyle(fontSize: 10),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final colorValue = value as String? ?? '#3498db';
    final showAlpha = hint['alpha'] == true;
    final showPresets = hint['presets'] != false;

    return ColorPickerField(
      initialColor: colorValue,
      showAlpha: showAlpha,
      showPresets: showPresets,
      onColorChanged: (color) => _updateSetting(key, color),
      label: hint['label'] as String? ?? 'Color',
      help: hint['help'] as String?,
    );
  }

  Widget _buildBoolControl(BuildContext context, String key, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Switch(
          value: value as bool? ?? false,
          onChanged: (v) => _updateSetting(key, v),
        ),
      ],
    );
  }

  Widget _buildSpinnerControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final isDouble = hint['decimal'] == true || value is double;
    final min = hint['min']?.toDouble() ?? 0;
    final max = hint['max']?.toDouble() ?? 100;
    final step = hint['step']?.toDouble() ?? (isDouble ? 0.1 : 1.0);

    // Get initial value
    double initialValue = 0;
    if (value is num) {
      initialValue = value.toDouble();
    } else if (value is String) {
      initialValue = double.tryParse(value) ?? min;
    }

    return SizedBox(
      child: SpinBox(
        min: min,
        max: max,
        step: step,
        value: initialValue,
        decimals: isDouble ? (hint['decimals'] as int? ?? 1) : 0,
        onChanged: (v) {
          if (isDouble) {
            _updateSetting(key, v);
          } else {
            _updateSetting(key, v.toInt());
          }
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: hint['placeholder'] as String?,
        ),
      ),
    );
  }

  Widget _buildNumberControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final isDouble = hint['decimal'] == true || value is double;
    final min = hint['min']?.toDouble() ?? 0;
    final max = hint['max']?.toDouble() ?? 100;

    return SizedBox(
      child: TextField(
        controller: controllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hint['placeholder'] as String?,
        ),
        onChanged: (v) {
          if (v.isEmpty) return;

          if (isDouble) {
            final parsedValue = double.tryParse(v) ?? min;
            final clampedValue = parsedValue.clamp(min, max);
            _updateSetting(key, clampedValue);
          } else {
            final parsedValue = int.tryParse(v) ?? min.toInt();
            final clampedValue = parsedValue.clamp(min.toInt(), max.toInt());
            _updateSetting(key, clampedValue);
          }
        },
      ),
    );
  }

  Widget _buildDropdownControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final options = hint['options'] as List<dynamic>? ?? [];

    if (options.isEmpty) {
      // No options, just return a disabled dropdown
      return DropdownButton<dynamic>(
        value: null,
        items: [],
        onChanged: null,
        isExpanded: true,
      );
    }

    // Extract the actual values from options
    final optionValues = options
        .map((opt) => opt is Map ? opt['value'] : opt)
        .toList();

    // Ensure selectedValue is valid
    dynamic selectedValue = value;
    if (value == null || !optionValues.contains(value)) {
      selectedValue = optionValues.first;
    }

    return DropdownButton<dynamic>(
      value: selectedValue,
      isExpanded: true,
      items: options.map((opt) {
        final optionValue = opt is Map ? opt['value'] : opt;
        final displayText = opt is Map
            ? (opt['label'] ?? optionValue).toString()
            : optionValue.toString();
        return DropdownMenuItem<dynamic>(
          value: optionValue,
          child: Text(displayText),
        );
      }).toList(),
      onChanged: (v) => _updateSetting(key, v),
    );
  }

  Widget _buildMultilineControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    return TextField(
      controller: controllers[key],
      maxLines: hint['max_lines'] as int? ?? 5,
      minLines: hint['min_lines'] as int? ?? 3,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hint['placeholder'] as String?,
      ),
      onChanged: (v) => _updateSetting(key, v),
    );
  }

  Widget _buildSliderControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final min = (hint['min'] ?? 0).toDouble();
    final max = (hint['max'] ?? 100).toDouble();
    double currentValue = (value as num?)?.toDouble() ?? min;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          min: min,
          max: max,
          divisions: hint['divisions'] as int?,
          value: currentValue.clamp(min, max).toDouble(),
          label: currentValue.toStringAsFixed(1),
          onChanged: (v) => _updateSetting(key, v),
        ),
        if (hint['show_range'] == true)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toString(), style: const TextStyle(fontSize: 12)),
              Text(max.toString(), style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }

  Widget _buildTextControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    // Normalize options to a list of {label, value} maps
    List<Map<String, String>> normalizeOptions(List<dynamic> raw) {
      return raw.map<Map<String, String>>((opt) {
        if (opt is Map) {
          // Handle model maps {id: ..., object: ...}
          if (opt.containsKey("id")) {
            final id = opt["id"].toString();
            final obj = opt["object"]?.toString() ?? "";
            return {
              "label": id, // show model id as label
              "value": id, // also use id as value
              "object": obj,
            };
          }

          // Default behavior (label/value style maps)
          final label = (opt["label"] ?? opt["value"] ?? "").toString();
          final val = (opt["value"] ?? opt["label"] ?? "").toString();
          return {"label": label, "value": val};
        } else {
          // Fallback: plain string
          final s = opt.toString();
          return {"label": s, "value": s};
        }
      }).toList();
    }

    final rawOptions = hint['options'] as List<dynamic>? ?? const [];
    final staticOptions = normalizeOptions(rawOptions);

    final hasStaticOptions = staticOptions.isNotEmpty;
    final hasDynamicOptions = hint['optionsCallback'] is Function;

    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controllers[key],
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hint['placeholder'] as String?,
          suffixIcon: (hasStaticOptions || hasDynamicOptions)
              ? IconButton(
                  tooltip: 'Choose from presets',
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () async {
                    List<Map<String, String>> options = staticOptions;

                    // If dynamic callback exists, fetch options at runtime
                    if (hasDynamicOptions) {
                      final cb =
                          hint['optionsCallback']
                              as Future<List<Map<String, String>>> Function(
                                Map<String, TextEditingController>,
                              );
                      try {
                        final raw = await cb(controllers);
                        options = normalizeOptions(raw);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to load options: $e'),
                            ),
                          );
                        }
                        return;
                      }
                    }

                    final selected = await showDialog<String>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: Text(
                          hint['label']?.toString() ?? 'Select option',
                        ),
                        children: [
                          FutureBuilder<List<Map<String, String>>>(
                            future: hasDynamicOptions
                                ? (hint['optionsCallback']
                                          as Future<List<dynamic>> Function(
                                            Map<String, TextEditingController>,
                                          ))(controllers)
                                      .then(normalizeOptions)
                                : Future.value(staticOptions),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Failed to load options: ${snapshot.error}',
                                  ),
                                );
                              }
                              final options = snapshot.data ?? [];
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: options.map((o) {
                                  return SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(ctx, o['value']),
                                    child: Text(o['label'] ?? o['value'] ?? ''),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    );

                    if (selected != null) {
                      final c = controllers[key];
                      if (c != null) c.text = selected;
                      _updateSetting(key, selected);
                    }
                  },
                )
              : null,
        ),
        obscureText: hint['obscure'] == true,
        onChanged: (v) => _updateSetting(key, v),
      ),
    );
  }

  Widget _buildFallbackControl(String key, dynamic value) {
    return TextField(
      controller: controllers[key],
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onChanged: (v) => _updateSetting(key, v),
    );
  }

  Widget _buildMultiSelectControl(
    BuildContext context,
    String key,
    dynamic value,
    Map<String, dynamic> hint,
  ) {
    final options = hint['options'] as List<dynamic>? ?? [];
    final List<dynamic> selectedValues = value is List ? value : [value];
    final minSelections = hint['min_selections'] as int? ?? 0;
    final maxSelections = hint['max_selections'] as int? ?? options.length;

    String displayText = selectedValues.isEmpty
        ? 'Select items...'
        : selectedValues
              .map(
                (v) => options
                    .where((o) => (o is Map ? o['value'] : o) == v)
                    .map((o) => o is Map ? o['label'] ?? o['value'] : o)
                    .first
                    .toString(),
              )
              .join(', ');

    if (displayText.length > 50) {
      displayText = '${displayText.substring(0, 47)}...';
    }

    return InkWell(
      onTap: () async {
        final result = await showDialog<List<dynamic>>(
          context: context,
          builder: (BuildContext context) {
            List<dynamic> tempSelection = List.from(selectedValues);

            return AlertDialog(
              title: Text(hint['label'] ?? _formatLabel(key)),
              content: SizedBox(
                width: double.minPositive,
                child: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (minSelections > 0 ||
                              maxSelections < options.length)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Select ${minSelections > 0 ? '$minSelections-' : 'up to '}$maxSelections items',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ListBody(
                            children: options.map((opt) {
                              final displayText = opt is Map
                                  ? (opt['label'] ?? opt['value']).toString()
                                  : opt.toString();
                              final optionValue = opt is Map
                                  ? opt['value']
                                  : opt;
                              final isSelected = tempSelection.contains(
                                optionValue,
                              );

                              return CheckboxListTile(
                                title: Text(displayText),
                                value: isSelected,
                                dense: true,
                                onChanged: (bool? selected) {
                                  setState(() {
                                    if (selected == true) {
                                      if (!tempSelection.contains(
                                            optionValue,
                                          ) &&
                                          tempSelection.length <
                                              maxSelections) {
                                        tempSelection.add(optionValue);
                                      }
                                    } else {
                                      tempSelection.remove(optionValue);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: tempSelection.length >= minSelections
                      ? () => Navigator.of(context).pop(tempSelection)
                      : null,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (result != null) {
          _updateSetting(key, result);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(child: Text(displayText, overflow: TextOverflow.ellipsis)),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ')
        .trim();
  }

  double getWidthHint(String key, double defaultWidth) {
    final hint = widget.settingsHints?[key];
    final hintMap = (hint != null && hint is Map<String, dynamic>)
        ? hint
        : null;

    final widthValue = hintMap?['width'];
    if (widthValue is num) {
      return widthValue.toDouble();
    }

    return defaultWidth;
  }

  @override
  Widget build(BuildContext context) {
    if (currentSettings.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(100),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              const SizedBox(height: 12),
              Text(
                'No settings available for this tool.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool showApplyButton = !widget.liveUpdate && widget.showApplyButton;
    final double effectiveCardWidth =
        widget.cardWidth ?? (widget.useColumnMode ? double.infinity : 280);

    if (widget.useColumnMode) {
      // Column mode - everything in a single column
      List<Widget> children = currentSettings.entries
          .map(
            (entry) => Container(
              width: effectiveCardWidth,
              height: widget.cardHeight,
              margin: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 2,
                shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: _buildEditorColumnMode(entry.key, entry.value),
                ),
              ),
            ),
          )
          .toList();

      // Add apply button if needed
      if (showApplyButton) {
        children.add(
          Container(
            width: effectiveCardWidth,
            margin: const EdgeInsets.only(top: 8),
            child: Card(
              elevation: 3,
              shadowColor: Theme.of(context).colorScheme.primary.withAlpha(100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: () => widget.onChanged.call(currentSettings),
                  icon: const Icon(Icons.check),
                  label: const Text('Apply Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(children: children),
      );
    } else {
      // Wrap mode (original behavior)
      List<Widget> children = currentSettings.entries
          .map(
            (entry) => Container(
              width: getWidthHint(entry.key, effectiveCardWidth),
              height: widget.cardHeight,
              margin: const EdgeInsets.all(0),
              child: Card(
                elevation: 2,
                shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: _buildEditor(context, entry.key, entry.value),
                ),
              ),
            ),
          )
          .toList();

      // Add apply button if needed
      if (showApplyButton) {
        children.add(
          Container(
            width: effectiveCardWidth,
            margin: const EdgeInsets.all(4),
            child: Card(
              elevation: 3,
              shadowColor: Theme.of(context).colorScheme.primary.withAlpha(100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: () => widget.onChanged.call(currentSettings),
                  icon: const Icon(Icons.check),
                  label: const Text('Apply Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return !widget.useGrid
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(2),
              child: Wrap(children: children),
            )
          : GridView.count(
              crossAxisCount: widget.columnCount,
              childAspectRatio: 2,
              children: children,
            );
    }
  }
}

class SettingsDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic> settings;
  final Map<String, dynamic>? settingsHints;

  const SettingsDialog({
    super.key,
    required this.title,
    required this.settings,
    this.settingsHints,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final editorKey = GlobalKey<_SettingsEditorState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.infinity,
        child: SettingsEditor(
          settingsHints: widget.settingsHints,
          useColumnMode: true,
          key: editorKey,
          settings: widget.settings,
          onChanged: (_) {},
          liveUpdate: false,
          showApplyButton: false,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final latest =
                editorKey.currentState?.currentSettings ??
                Map<String, dynamic>.from(widget.settings);
            Navigator.of(context).pop(latest);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class ColorPickerField extends StatefulWidget {
  final String initialColor;
  final bool showAlpha;
  final bool showPresets;
  final Function(String) onColorChanged;
  final String? label;
  final String? help;

  const ColorPickerField({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.showAlpha = false,
    this.showPresets = true,
    this.label,
    this.help,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late TextEditingController _controller;
  late Color _currentColor;
  bool _showPicker = false;

  @override
  void initState() {
    super.initState();
    _currentColor = _parseColor(widget.initialColor);
    _controller = TextEditingController(text: widget.initialColor);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseColor(String colorStr) {
    try {
      colorStr = colorStr.trim();
      if (colorStr.startsWith('#')) {
        final hex = colorStr.substring(1);
        if (hex.length == 3) {
          return Color(
            int.parse(
              'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}',
              radix: 16,
            ),
          );
        } else if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
      // Handle rgb/rgba
      if (colorStr.startsWith('rgb')) {
        final match = RegExp(
          r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)',
        ).firstMatch(colorStr);
        if (match != null) {
          final r = int.parse(match.group(1)!);
          final g = int.parse(match.group(2)!);
          final b = int.parse(match.group(3)!);
          final a = match.group(4) != null
              ? (double.parse(match.group(4)!) * 255).round()
              : 255;
          return Color.fromARGB(a, r, g, b);
        }
      }
    } catch (e) {
      // Fallback to default color
    }
    return const Color(0xFF3498DB);
  }

  String _colorToHex(Color color) {
    if (widget.showAlpha && color.alpha != 255) {
      return '#${color.value.toRadixString(16).padLeft(8, '0')}';
    } else {
      return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    }
  }

  void _updateColor(Color color) {
    setState(() {
      _currentColor = color;
      final hexColor = _colorToHex(color);
      _controller.text = hexColor;
      widget.onColorChanged(hexColor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
        ],

        // Color input field with preview
        Row(
          children: [
            // Color preview button
            GestureDetector(
              onTap: () => setState(() => _showPicker = !_showPicker),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _currentColor.alpha < 255
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/transparency_grid.png',
                            ), // You'd need this asset
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _currentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // Text input
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '#3498db',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPicker ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => setState(() => _showPicker = !_showPicker),
                  ),
                ),
                onChanged: (value) {
                  final color = _parseColor(value);
                  setState(() => _currentColor = color);
                  widget.onColorChanged(value);
                },
              ),
            ),
          ],
        ),

        if (widget.help != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.help!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],

        // Expandable color picker
        if (_showPicker) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: ColorPickerWidget(
              color: _currentColor,
              onColorChanged: _updateColor,
              showAlpha: widget.showAlpha,
              showPresets: widget.showPresets,
            ),
          ),
        ],
      ],
    );
  }
}

class ColorPickerWidget extends StatefulWidget {
  final Color color;
  final Function(Color) onColorChanged;
  final bool showAlpha;
  final bool showPresets;

  const ColorPickerWidget({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.showAlpha = false,
    this.showPresets = true,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.color);
  }

  void _updateColor(HSVColor hsvColor) {
    setState(() => _hsvColor = hsvColor);
    widget.onColorChanged(hsvColor.toColor());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hue slider
        SizedBox(
          height: 20,
          child: GestureDetector(
            onPanUpdate: (details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(
                details.globalPosition,
              );
              final hue = (localPosition.dx / renderBox.size.width * 360).clamp(
                0.0,
                360.0,
              );
              _updateColor(_hsvColor.withHue(hue));
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    for (int i = 0; i <= 6; i++)
                      HSVColor.fromAHSV(1.0, i * 60.0, 1.0, 1.0).toColor(),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left:
                        (_hsvColor.hue /
                            360 *
                            MediaQuery.of(context).size.width *
                            0.8) -
                        6,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade400),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Saturation-Value picker
        SizedBox(
          height: 150,
          child: GestureDetector(
            onPanUpdate: (details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(
                details.globalPosition,
              );
              final saturation = (localPosition.dx / renderBox.size.width)
                  .clamp(0.0, 1.0);
              final value = (1.0 - localPosition.dy / renderBox.size.height)
                  .clamp(0.0, 1.0);
              _updateColor(
                _hsvColor.withSaturation(saturation).withValue(value),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor(),
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: _hsvColor.saturation * 200 - 6,
                      top: (1.0 - _hsvColor.value) * 150 - 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Alpha slider (if enabled)
        if (widget.showAlpha) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 20,
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                final alpha = (localPosition.dx / renderBox.size.width).clamp(
                  0.0,
                  1.0,
                );
                _updateColor(_hsvColor.withAlpha(alpha));
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      _hsvColor.toColor().withOpacity(0.0),
                      _hsvColor.toColor().withOpacity(1.0),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left:
                          (_hsvColor.alpha *
                              MediaQuery.of(context).size.width *
                              0.8) -
                          6,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade400),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Color presets (if enabled)
        if (widget.showPresets) ...[
          const SizedBox(height: 16),
          const Text(
            'Quick Colors:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Material Design colors
              for (final color in [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
                Colors.black,
              ])
                GestureDetector(
                  onTap: () => _updateColor(HSVColor.fromColor(color)),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hsvColor.toColor().value == color.value
                            ? Colors.black
                            : Colors.grey.shade300,
                        width: _hsvColor.toColor().value == color.value ? 2 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
