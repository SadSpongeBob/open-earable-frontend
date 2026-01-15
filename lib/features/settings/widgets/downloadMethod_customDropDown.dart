import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1F1F1F), width: 3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: Text(_selected)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: (value) => setState(() => _selected = value),
            itemBuilder: (context) => _options
                .map((opt) => PopupMenuItem<String>(
              value: opt,
              child: Text(opt, style: TextStyle(color: _getColor(opt, _selected))),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Color _getColor(String value, String selected) {
    return value == selected ? Colors.red : Colors.black;
  }
}