import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/features/home/state/network_status.dart';
import 'package:openearable/features/playback/controllers/playback_controller.dart';

/// A widget that displays an error message for a failed recording load.
///
/// Provides two actions for the user:
/// 1. **Go Back**: Navigates to the home screen.
/// 2. **Retry**: Invalidates the network and video player providers to attempt reloading.
///
/// Parameters:
/// - [errorMessage]: The message describing the failure.
/// - [recording]: The [Recording] that failed to load, used to retry playback.
class FailedLoadScreen extends ConsumerWidget {
  const FailedLoadScreen({
    super.key,
    required this.errorMessage,
    required this.recording,
  });

  final String errorMessage;
  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 400,
              child: Text(
                errorMessage,
                style: AppTextStyles.subheaderMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 340,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton.danger(
                    text: 'Go Back',
                    // Navigate back to the home screen
                    onPressed: () => context.go(Routes.home),
                    fullWidth: false,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton.primary(
                      text: 'Retry',
                      // Retry loading: invalidate network and video player state
                      onPressed: () {
                        ref.invalidate(networkStatusProvider);
                        ref.invalidate(
                          videoPlayerControllerProvider(recording),
                        );
                      },
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
