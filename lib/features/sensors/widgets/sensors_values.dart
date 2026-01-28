import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openearable/features/home/state/wearables_provider.dart';
import 'package:openearable/features/sensors/widgets/selectable_sensor_card.dart';
import 'package:openearable/app/theme/text_styles.dart';

class SensorValues extends StatefulWidget {
  const SensorValues({super.key});

  @override
  State<SensorValues> createState() => _SensorValuesState();
}

class _SensorValuesState extends State<SensorValues> {

  @override
Widget build(BuildContext context) {
  return Consumer<WearablesProvider>(
    builder: (context, wearablesProvider, child) {
      List<Widget> charts = [];

      for (var wearable in wearablesProvider.wearables) {
        final providers =
            wearablesProvider.getSensorDataProviders(wearable);

        for (var dataProvider in providers) {
          charts.add(
            ChangeNotifierProvider.value(
              value: dataProvider,
              child: SelectableSensorCard(
                sensor: dataProvider.sensor,
                wearable: wearable,
              ),
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
    },
  );
}


  Widget _buildSmallScreenLayout(BuildContext context, List<Widget> charts) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: charts.isEmpty
        ? Center(
          child: Text("No sensors available", style: GlobalTextStyles.subHeader),
        )
        : ListView(
          children: charts,
        ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context, List<Widget> charts) {
    if (charts.isEmpty) {
      return Center(
        child: Text(
          "No sensors available",
          style: GlobalTextStyles.subHeader,
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
