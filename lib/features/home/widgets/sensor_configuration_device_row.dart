import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:openearable/features/home/controllers/sensor_configuration_storage.dart';
import 'package:openearable/features/home/widgets/edge_recorder_prefix_row.dart';
import 'package:openearable/features/home/widgets/save_config_row.dart';
import 'package:openearable/features/home/widgets/sensor_configuration_value_row.dart';
import 'package:provider/provider.dart';
import 'package:openearable/features/home/controllers/sensor_configurations_provider.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A widget that displays a list of sensor configurations for a device.
class SensorConfigurationDeviceRow extends StatefulWidget {
  final Wearable device;

  const SensorConfigurationDeviceRow({super.key, required this.device});

  @override
  State<SensorConfigurationDeviceRow> createState() =>
      _SensorConfigurationDeviceRowState();
}

class _SensorConfigurationDeviceRowState
    extends State<SensorConfigurationDeviceRow>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Widget> _content = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _updateContent();
      }
    });
    _content = [CircularProgressIndicator()];
    _updateContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFF2F2F2),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.device.hasCapability<SensorConfigurationManager>())
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildTabBar(context),
              ),
            ),
          ..._content,
        ],
      ),
    );
  }

  Future<void> _updateContent() async {
    final Wearable device = widget.device;

    if (!device.hasCapability<SensorConfigurationManager>()) {
      if (!mounted) return;
      setState(() {
        _content = [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("This device does not support configuring sensors."),
          ),
        ];
      });
      return;
    }

    final SensorConfigurationManager sensorManager =
        device.requireCapability<SensorConfigurationManager>();

    if (_tabController.index == 0) {
      _buildNewTabContent(device);
    } else {
      await _buildLoadTabContent(sensorManager);
    }
  }

  void _buildNewTabContent(Wearable device) {
    SensorConfigurationManager sensorManager =
        device.requireCapability<SensorConfigurationManager>();
    final List<Widget> content = sensorManager.sensorConfigurations
        .map(
          (config) => SensorConfigurationValueRow(sensorConfiguration: config),
        )
        .cast<Widget>()
        .toList();

    content.addAll([
      const Divider(),
      const SaveConfigRow(),
    ]);

    if (device.hasCapability<EdgeRecorderManager>()) {
      content.addAll([
        const Divider(),
        EdgeRecorderPrefixRow(manager: device.requireCapability<EdgeRecorderManager>()),
      ]);
    }

    if (!mounted) return;
    setState(() {
      _content = content;
    });
  }

  Future<void> _buildLoadTabContent(SensorConfigurationManager device) async {
    if (!mounted) return;
    setState(() {
      _content = [CircularProgressIndicator()];
    });

    final configKeys = await SensorConfigurationStorage.listConfigurationKeys();

    if (!mounted) return;

    if (configKeys.isEmpty) {
      setState(() {
        _content = [
          ListTile(title: Text("No configurations found")),
        ];
      });
      return;
    }

    final widgets = configKeys.map((key) {
      return ListTile(
        title: Text(key),
        onTap: () async {
          final config =
              await SensorConfigurationStorage.loadConfiguration(key);
          if (!mounted) return;

          final result = await Provider.of<SensorConfigurationProvider>(
            context,
            listen: false,
          ).restoreFromJson(config);

          if (!result && mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Error"),
                content: Text("Failed to load configuration: $key"),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
            return;
          }

          _tabController.index = 0;
          _updateContent();
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            await SensorConfigurationStorage.deleteConfiguration(key);
            if (mounted) _updateContent();
          },
        ),
      );
    }).toList();

    setState(() {
      _content = widgets;
    });
  }

  Widget? _buildTabBar(BuildContext context) {
    if (!widget.device.hasCapability<SensorConfigurationManager>()) return null;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: TabBar.secondary(
        controller: _tabController,
        labelStyle: AppTextStyles.footnoteMedium,
        unselectedLabelStyle: AppTextStyles.footnoteMedium,
        unselectedLabelColor: Color(0xFF6E6E6E),
        tabs: const [
          Tab(text: 'New'),
          Tab(text: 'Saved'),
        ],
      ),
    );
  }
}
