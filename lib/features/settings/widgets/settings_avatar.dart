import 'package:flutter/cupertino.dart';

class SettingsAvatar extends StatefulWidget {
  final String? avatarUrl;
  final Future<void> Function() refreshUser;

  const SettingsAvatar({
    super.key,
    required this.avatarUrl,
    required this.refreshUser,
  });

  @override
  State<SettingsAvatar> createState() => _SettingsAvatarState();
}

class _SettingsAvatarState extends State<SettingsAvatar> {
  bool _didTryRefresh = false;

  @override
  Widget build(BuildContext context) {
    final url = widget.avatarUrl;

    if (url == null || url.isEmpty) {
      return Image.asset("assets/images/user.png", width: 80, height: 100);
    }

    return Image.network(
      url,
      width: 80,
      height: 100,
      errorBuilder: (context, error, stack) {
        if (!_didTryRefresh) {
          _didTryRefresh = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.refreshUser();
          });
        }
        return Image.asset("assets/images/user.png", width: 80, height: 100);
      },
    );
  }
}
