import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({super.key});

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String _selected = 'Download with WiFi';

  static const List<String> _options = [
    'Download with WiFi',
    'Download with mobile data and WiFi',
  ];

  @override
  Widget build(BuildContext context) {
    final itemStyle = AuthTextStyles.fieldInput.copyWith(fontSize: 18);
    // itemstyle for dropdown items
    final dropdownItemStyle = AuthTextStyles.fieldInput.copyWith(fontSize: 14);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1F1F1F), width: 3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_selected, style: itemStyle),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: (value) {
              setState(() {
                _selected = value;
              });
            },
            itemBuilder: (context) => _options.map((opt) {
              return PopupMenuItem<String>(
                value: opt,
                child: Text(
                  opt,
                  style: dropdownItemStyle.copyWith(
                    color: _getColor(opt),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getColor(String value) {
    return value == _selected ? Colors.red : Colors.black;
  }
}
