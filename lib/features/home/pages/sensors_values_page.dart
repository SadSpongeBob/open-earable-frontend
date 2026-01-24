import 'package:flutter/material.dart';
import 'package:openearable/features/home/controllers/wearables_provider.dart';
import 'package:openearable/features/home/widgets/selectable_sensor_card.dart';
import 'package:provider/provider.dart';

class SensorValuesPage extends StatefulWidget {
  const SensorValuesPage({super.key});

  @override
  State<SensorValuesPage> createState() => _SensorValuesPageState();
}

class _SensorValuesPageState extends State<SensorValuesPage> {

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
          child: Text("No sensors connected", style: Theme.of(context).textTheme.titleLarge),
        )
        : ListView(
          children: charts,
        ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context, List<Widget> charts) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: charts.isEmpty ? 1 : charts.length,
      itemBuilder: (context, index) {
        if (charts.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.grey,
                width: 1,
                style: BorderStyle.solid,
                strokeAlign: -1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text("No sensors available", style: Theme.of(context).textTheme.titleLarge),
            ),
          );
        }
        return charts[index];
      },
    );
  }
}
