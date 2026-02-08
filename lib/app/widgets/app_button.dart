import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost, dangerGhost }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final AppButtonVariant variant;
  final bool fullWidth;
  final TextStyle? textStyle;

  const AppButton._({
    super.key,
    required this.text,
    required this.onPressed,
    required this.variant,
    this.textStyle,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 24,
    this.fullWidth = true,
  });

  factory AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    TextStyle? textStyle,
    bool isLoading = false,
    double height = 48,
    double borderRadius = 24,
    bool fullWidth = true,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      textStyle: textStyle,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      variant: AppButtonVariant.primary,
    );
  }

  factory AppButton.secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    TextStyle? textStyle,
    bool isLoading = false,
    double height = 48,
    double borderRadius = 24,
    bool fullWidth = true,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      textStyle: textStyle,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      variant: AppButtonVariant.secondary,
    );
  }

  factory AppButton.danger({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    TextStyle? textStyle,
    bool isLoading = false,
    double height = 48,
    double borderRadius = 24,
    bool fullWidth = true,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      textStyle: textStyle,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      variant: AppButtonVariant.danger,
    );
  }

  factory AppButton.ghost({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    TextStyle? textStyle,
    bool isLoading = false,
    double height = 48,
    double borderRadius = 24,
    bool fullWidth = true,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      textStyle: textStyle,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      variant: AppButtonVariant.ghost,
    );
  }

  factory AppButton.dangerGhost({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    TextStyle? textStyle,
    bool isLoading = false,
    double height = 48,
    double borderRadius = 24,
    bool fullWidth = true,
  }) {
    return AppButton._(
      key: key,
      text: text,
      onPressed: onPressed,
      textStyle: textStyle,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      fullWidth: fullWidth,
      variant: AppButtonVariant.dangerGhost,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeFor(variant);

    final Widget button = scheme.isGhost
        ? _buildTextButton(scheme)
        : _buildElevatedButton(scheme);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: button,
    );
  }

  Widget _buildTextButton(_ButtonScheme scheme) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: scheme.foreground,
        disabledForegroundColor: scheme.foregroundDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: _content(scheme),
    );
  }

  Widget _buildElevatedButton(_ButtonScheme scheme) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.background,
        foregroundColor: scheme.foreground,
        disabledBackgroundColor: scheme.backgroundDisabled,
        disabledForegroundColor: scheme.foregroundDisabled,
        elevation: scheme.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: scheme.borderSide ?? BorderSide.none,
        ),
      ),
      child: _content(scheme),
    );
  }

  Widget _content(_ButtonScheme scheme) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(scheme.foreground),
        ),
      );
    }

    return Text(
      text,
      style: (textStyle ?? AppTextStyles.textMedium).copyWith(
        color: scheme.foreground,
      ),
    );
  }

  _ButtonScheme _schemeFor(AppButtonVariant v) {
    switch (v) {
      case AppButtonVariant.primary:
        return _ButtonScheme(
          background: AppColors.nineHundred,
          foreground: AppColors.fifty,
          backgroundDisabled: AppColors.sixHundred,
          foregroundDisabled: AppColors.fifty,
          elevation: 4,
        );

      case AppButtonVariant.secondary:
        return _ButtonScheme(
          background: AppColors.hundred,
          foreground: AppColors.nineHundred,
          backgroundDisabled: AppColors.fourHundred,
          foregroundDisabled: AppColors.sevenHundred,
          elevation: 4,
          borderSide: BorderSide(color: AppColors.twoHundred),
        );

      case AppButtonVariant.danger:
        return _ButtonScheme(
          background: AppColors.primary,
          foreground: AppColors.fifty,
          backgroundDisabled: AppColors.primary.withValues(alpha: 0.35),
          foregroundDisabled: AppColors.twoHundred,
          elevation: 4,
        );

      case AppButtonVariant.ghost:
        return _ButtonScheme(
          foreground: AppColors.sixHundred,
          foregroundDisabled: AppColors.threeHundred,
          elevation: 0,
        );

      case AppButtonVariant.dangerGhost:
        return _ButtonScheme(
          foreground: AppColors.primary,
          foregroundDisabled: AppColors.primary.withValues(alpha: 0.35),
          elevation: 0,
        );
    }
  }
}

class _ButtonScheme {
  final Color foreground;
  final Color? background;
  final Color foregroundDisabled;
  final Color? backgroundDisabled;
  final double elevation;
  final BorderSide? borderSide;

  const _ButtonScheme({
    required this.foreground,
    this.background,
    required this.foregroundDisabled,
    this.backgroundDisabled,
    this.elevation = 0,
    this.borderSide,
  });

  bool get isGhost => background == null;
}
