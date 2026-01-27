import 'package:flutter/material.dart';
import 'package:openearable/features/home/widgets/sensor_configuration_view.dart';
import 'package:openearable/features/home/widgets/sensors_values_card.dart';
import 'package:openearable/app/widgets/image_button.dart';
import 'package:provider/provider.dart';
import 'package:openearable/features/home/controllers/wearables_provider.dart';
import 'package:openearable/app/theme/text_styles.dart';

enum SensorPageSource {
  home,
  recording,
}

class SensorPage extends StatelessWidget {
  final VoidCallback onBluetoothPressed;
  final SensorPageSource source;

  SensorPage({
    super.key,
    required this.onBluetoothPressed,
    required this.source,
  });

  final GlobalKey _sensorBtKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFE6E6E6),
        body: Row(
          children: [
            // LEFT SIDE MENU (Configuration Panel)
            Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFFF2F2F2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF8F8F8F),
                    blurRadius: 30,
                    offset: Offset(-3, 0),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    child: Consumer<WearablesProvider>(
                      builder: (context, provider, _) {
                        bool isConnected = provider.wearables.isNotEmpty;
                        return ImageButton(
                          buttonKey: _sensorBtKey,
                          image: 'assets/images/bluetooth.png',
                          activeImage: 'assets/images/bluetooth_active.png',
                          isActive: isConnected,
                          onPressed: onBluetoothPressed,
                          width: 70,
                          height: 70,
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SensorConfigurationView(
                      onSetConfigPressed: () {},
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          height: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                source == SensorPageSource.home
                                    ? 'assets/images/projects.png'
                                    : 'assets/images/recording.png',
                                width: 55,
                                height: 55,
                              ),
                              const SizedBox(width: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_ios_new_rounded, size: 17),
                                  const Text(" Go Back", style: AppTextStyles.footnoteMedium),
                                ],
                              ),
                            ],
                          )
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT SIDE CONTENT (Charts)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Sensors",
                      style: AppTextStyles.titleBold,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SensorValuesCard(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
