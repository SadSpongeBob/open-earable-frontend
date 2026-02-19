import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/features/sensors/widgets/sensor_configuration_view.dart';
import 'package:openearable/app/ui/device/devices_popup_controller.dart';
import 'package:openearable/app/widgets/devices_popup.dart';
import 'package:openearable/features/sensors/widgets/sensors_values.dart';
import 'package:openearable/app/widgets/bluetooth_button.dart';
import 'package:openearable/app/theme/text_styles.dart';
import '../../../app/routing/routes.dart';

/// A page that displays sensor configuration and live sensor values.
///
/// The layout is split into two sections:
/// - Left panel: Bluetooth connection, sensor configuration, and navigation
/// - Right panel: Live sensor charts and values
///
/// If [isRecordingSource] is true, the "Go Back" action navigates to the
/// Recording Page; otherwise it navigates to the Home Page.
class SensorPage extends StatefulWidget {
  /// Whether this page was opened from the recording flow.
  ///
  /// When true, the back action returns to the Recording page.
  /// When false, it returns to the Home Page.
  final bool isRecordingSource;

  const SensorPage({super.key, this.isRecordingSource = false});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final GlobalKey _sensorBluetoothKey = GlobalKey();
  final DevicesPopupController _popupController = DevicesPopupController();

  void _onBluetoothPressed() {
    _popupController.toggle(
      context: context,
      positionedPopup: const Positioned(
        top: 30,
        left: 295,
        child: DevicesPopup(),
      ),
    );
  }

  @override
  void dispose() {
    _popupController.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // LEFT SIDE MENU (Configuration Panel)
          Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.fifty,
              boxShadow: [
                BoxShadow(
                  color: AppColors.twoHundred,
                  blurRadius: 30,
                  offset: const Offset(-3, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    child: BluetoothButton(
                      buttonKey: _sensorBluetoothKey,
                      onPressed: _onBluetoothPressed,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: SensorConfigurationView()),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (widget.isRecordingSource) {
                            context.go(Routes.recording);
                          } else {
                            context.go(Routes.home);
                          }
                        },
                        child: SizedBox(
                          height: 120,
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                widget.isRecordingSource
                                    ? 'assets/buttons/shutter.png'
                                    : 'assets/buttons/projects.png',
                                width: 70,
                                height: 70,
                              ),
                              const SizedBox(width: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 17,
                                  ),
                                  const Text(
                                    " Go Back",
                                    style: AppTextStyles.footerMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT SIDE CONTENT (Charts)
          Expanded(
            child: Scaffold(
              backgroundColor: AppColors.hundred,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Sensors", style: AppTextStyles.titleBold),
                      const SizedBox(height: 10),
                      Expanded(child: SensorValues()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
