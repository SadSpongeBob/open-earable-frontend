import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/features/home/state/wearables_state.dart';
import 'package:openearable/features/sensors/widgets/selectable_sensor_card.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A widget that displays all sensor values from connected wearables.
///
/// Each sensor is displayed as a [SelectableSensorCard] that allows the user
/// to select and view detailed sensor data.  
///
/// The layout adapts based on the available screen width:
/// - For narrow screens (width < 600), it shows a simple vertical list of cards.
/// - For wider screens, it displays a larger, spaced list of cards with separators.
///
/// If no sensors are available from connected wearables, a placeholder message
/// is shown.
class SensorValues extends ConsumerWidget {
  const SensorValues({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wearablesNotifier = ref.watch(wearablesProvider);

    List<Widget> charts = [];

    for (var wearable in wearablesNotifier.wearables) {
      final providers =
          wearablesNotifier.getSensorDataProviders(wearable);

      for (int i = 0; i < providers.length; i++) {
        final dataProvider = providers[i];
        
        charts.add(
          SelectableSensorCard(
            sensor: dataProvider.sensor,
            wearable: wearable,
            sensorIndex: i,
          ),
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildSmallScreenLayout(context, charts);
        } else {
          return _buildLargeScreenLayout(context, charts);
        }
      },
    );
  }

  /// Builds the sensor layout for small screens (e.g., mobile devices).
  ///
  /// Displays a vertical list of [SelectableSensorCard] widgets with padding.
  /// If no sensors are available, shows a centered placeholder message.
  Widget _buildSmallScreenLayout(BuildContext context, List<Widget> charts) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: charts.isEmpty
        ? Center(
          child: Text("No sensors available", style: AppTextStyles.subheaderRegular),
        )
        : ListView(
          children: charts,
        ),
    );
  }

  /// Builds the sensor layout for large screens (e.g., tablets or desktop).
  ///
  /// Displays a vertically separated list of [SelectableSensorCard] widgets.
  /// If no sensors are available, shows a centered placeholder message.
  Widget _buildLargeScreenLayout(BuildContext context, List<Widget> charts) {
    if (charts.isEmpty) {
      return Center(
        child: Text(
          "No sensors available",
          style: AppTextStyles.subheaderRegular,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: charts.length,
      itemBuilder: (context, index) => charts[index],
      separatorBuilder: (context, index) => const SizedBox(height: 25),
    );
  }
}
