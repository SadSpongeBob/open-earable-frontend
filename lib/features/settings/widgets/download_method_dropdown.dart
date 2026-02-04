import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/services/user/user_preference_storage.dart';
import '../../../app/theme/text_styles.dart';

class CustomDropdown extends ConsumerStatefulWidget {
  const CustomDropdown({super.key});

  @override
  ConsumerState<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends ConsumerState<CustomDropdown> {
  static const String _wifiOnlyText = 'Download with WiFi';
  static const String _mobileAndWifiText = 'Download with mobile data and WiFi';

  static const List<String> _options = [
    _wifiOnlyText,
    _mobileAndWifiText,
  ];

  String _selected = _wifiOnlyText;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final storage = ref.read(userPreferenceStorage);
    final wifiOnly = await storage.isWifiOnly();

    if (!mounted) return;
    setState(() {
      _selected = wifiOnly ? _wifiOnlyText : _mobileAndWifiText;
      _loading = false;
    });
  }

  Future<void> _onSelected(String value) async {
    setState(() {
      _selected = value;
    });

    final storage = ref.read(userPreferenceStorage);
    final wifiOnly = value == _wifiOnlyText;
    await storage.setWifiOnly(wifiOnly);
  }

  @override
  Widget build(BuildContext context) {
    final itemStyle = AppTextStyles.textMedium;
    final dropdownItemStyle = AppTextStyles.textMedium;

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
            child: Text(_loading ? 'Loading' : _selected, style: itemStyle),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: _onSelected,
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
