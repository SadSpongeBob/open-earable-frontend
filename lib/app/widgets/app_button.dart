import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final AppButtonVariant variant;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.height = 48,
    this.borderRadius = 24,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeFor(variant);

    final button = ElevatedButton(
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
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(scheme.foreground),
              ),
            )
          : Text(
              text,
              style: AppTextStyles.textMedium.copyWith(
                color: scheme.foreground,
              ),
            ),
    );

    if (!fullWidth) return SizedBox(height: height, child: button);

    return SizedBox(width: double.infinity, height: height, child: button);
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
          elevation: 0,
          borderSide: BorderSide(color: AppColors.twoHundred),
        );

      case AppButtonVariant.danger:
        return _ButtonScheme(
          background: AppColors.primary,
          foreground: AppColors.fifty,
          backgroundDisabled: AppColors.primary.withValues(alpha: 0.35),
          foregroundDisabled: AppColors.twoHundred,
          elevation: 2,
        );
    }
  }
}

class _ButtonScheme {
  final Color background;
  final Color foreground;
  final Color backgroundDisabled;
  final Color foregroundDisabled;
  final double elevation;
  final BorderSide? borderSide;

  const _ButtonScheme({
    required this.background,
    required this.foreground,
    required this.backgroundDisabled,
    required this.foregroundDisabled,
    required this.elevation,
    this.borderSide,
  });
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 24,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      variant: AppButtonVariant.primary,
      fullWidth: fullWidth,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 24,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      variant: AppButtonVariant.secondary,
      fullWidth: fullWidth,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final bool fullWidth;

  const DangerButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 48,
    this.borderRadius = 24,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      height: height,
      borderRadius: borderRadius,
      variant: AppButtonVariant.danger,
      fullWidth: fullWidth,
    );
  }
}
