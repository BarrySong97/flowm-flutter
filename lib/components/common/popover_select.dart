import 'package:flowm/shared/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';

class PopoverSelectItem {
  final String value;
  final String label;

  PopoverSelectItem({required this.value, required this.label});
}

class PopoverSelect extends StatefulWidget {
  final List<PopoverSelectItem> items;
  final String value;
  final Function(String)? onChanged;

  const PopoverSelect({
    super.key,
    required this.items,
    required this.value,
    this.onChanged,
  });

  @override
  State<PopoverSelect> createState() => _PopoverSelectState();
}

class _PopoverSelectState extends State<PopoverSelect> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  String get _selectedLabel {
    return widget.items
        .firstWhere((item) => item.value == _selectedValue,
            orElse: () => widget.items.first)
        .label;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showPopover(
          context: context,
          bodyBuilder: (context) => _buildPopoverList(context),
          onPop: () => AppLogger.debug('Popover was popped!'),
          direction: PopoverDirection.bottom,
          backgroundColor: Colors.white,
          width: 200,
          height: widget.items.length * 32.0 + 16,
          arrowHeight: 0,
          arrowWidth: 0,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_selectedLabel),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildPopoverList(BuildContext popoverContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: widget.items.map((item) {
          final bool isSelected = item.value == _selectedValue;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedValue = item.value;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(item.value);
              }
              Navigator.of(popoverContext).pop();
            },
            child: Container(
              height: 32,
              color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label),
                  if (isSelected)
                    Icon(Icons.check,
                        color: Theme.of(popoverContext).primaryColor),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
