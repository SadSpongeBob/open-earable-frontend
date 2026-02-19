import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/services/user/user_preference_storage.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/widgets/pill_menu.dart';

/// Dropdown widget for selecting the user's preferred download method.
///
/// Allows the user to choose between:
/// - WiFi only downloads
/// - Mobile data and WiFi downloads
///
/// Uses [UserPreferenceStorage] to persist the preference locally
/// and updates the UI reactively with loading/saving states.
class DownloadMethodDropdown extends ConsumerStatefulWidget {
  const DownloadMethodDropdown({super.key});

  @override
  ConsumerState<DownloadMethodDropdown> createState() =>
      _DownloadMethodDropdownState();
}

class _DownloadMethodDropdownState
    extends ConsumerState<DownloadMethodDropdown> {
  // --- Option Text Constants ---
  static const String _wifiOnlyText = 'Download with WiFi';
  static const String _mobileAndWifiText = 'Download with mobile data and WiFi';
  static const List<String> _options = [_wifiOnlyText, _mobileAndWifiText];

  // --- State ---
  String _selected = _wifiOnlyText;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  /// Loads the saved download preference from [UserPreferenceStorage].
  ///
  /// Updates [_selected] and sets [_loading] to false once loaded.
  Future<void> _loadPreference() async {
    final storage = ref.read(userPreferenceStorage);
    final wifiOnly = await storage.isWifiOnly();

    if (!mounted) return;
    setState(() {
      _selected = wifiOnly ? _wifiOnlyText : _mobileAndWifiText;
      _loading = false;
    });
  }

  /// Handles selection changes in the dropdown.
  ///
  /// Updates [_selected], saves the preference via [UserPreferenceStorage],
  /// and manages [_saving] state during the operation.
  Future<void> _onSelected(String value) async {
    setState(() {
      _selected = value;
      _saving = true;
    });

    final storage = ref.read(userPreferenceStorage);
    final wifiOnly = value == _wifiOnlyText;
    await storage.setWifiOnly(wifiOnly);

    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return PillMenu<String>(
      value: (_loading || _saving) ? null : _selected,
      options: _options,
      labelOf: (s) => s,
      onChanged: _onSelected,
      itemColor: _getColor,
    );
  }

  /// Returns the color for each dropdown item based on selection and loading state.
  Color _getColor(String value) {
    if (_loading) return AppColors.nineHundred;
    return value == _selected ? AppColors.primary : AppColors.nineHundred;
  }
}
