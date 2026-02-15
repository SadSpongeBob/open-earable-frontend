import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';

final sensorConfigurationStorageProvider =
    Provider<SensorConfigurationStorage>((ref) {
  final localMedia = ref.watch(localMediaProvider);
  return SensorConfigurationStorage(localMedia);
});

class SensorConfigurationStorage {
  final LocalMedia localMedia;

  SensorConfigurationStorage(this.localMedia);

  /// Returns the directory where sensor configurations are stored.
  /// Creates the directory if it does not exist.
  Future<Directory> _getConfigDirectory() async {
    final configDir = Directory('${localMedia.baseDir.path}/sensor_configurations');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return configDir;
  }

  /// Returns a list of all configuration files in the sensor configurations directory.
  /// Each file is expected to be a JSON file with a specific configuration.
  Future<List<File>> _getAllConfigFiles() async {
    final configDir = await _getConfigDirectory();
    return configDir.list().where((file) =>
      file is File && file.path.endsWith('.json'),
    ).cast<File>().toList();
  }

  /// Returns the file for a specific configuration key.
  /// Creates the file if it does not exist.
  Future<File> _getConfigFile(String key) async {
    final configDir = await _getConfigDirectory();
    return File('${configDir.path}/${sanitizeKey(key)}.json');
  }

  /// Saves a configuration for a specific key.
  /// If the file already exists, it will be overwritten.
  /// The configuration is expected to be a map of string key-value pairs.
  Future<void> saveConfiguration(String key, Map<String, String> config) async {
    final File file = await _getConfigFile(key);
    await file.writeAsString(jsonEncode(config));
  }

  Future<List<String>> listConfigurationKeys() async {
    final files = await _getAllConfigFiles();
    return files.map(_getKeyFromFile).toList();
  }

  String _getKeyFromFile(File file) =>
      file.uri.pathSegments.last.replaceAll('.json', '');

  /// Loads all configurations from the sensor configurations directory.
  /// Returns a map where the keys are configuration names and the values are maps of string key-value pairs.
  /// Each configuration is expected to be stored in a JSON file.
  Future<Map<String, Map<String, String>>> loadConfigurations() async {
    final allConfigs = <String, Map<String, String>>{};
    final configFiles = await _getAllConfigFiles();
    for (final file in configFiles) {
      final contents = await file.readAsString();
      allConfigs[_getKeyFromFile(file)] = Map<String, String>.from(jsonDecode(contents));
    }
    return allConfigs;
  }

  Future<Map<String, String>> loadConfiguration(String key) async {
    final file = await _getConfigFile(key);
    if (await file.exists()) {
      final contents = await file.readAsString();
      return Map<String, String>.from(jsonDecode(contents));
    }
    return {};
  }

  /// Deletes a specific configuration by its key.
  /// If the file does not exist, it will do nothing.
  Future<void> deleteConfiguration(String key) async {
    final file = await _getConfigFile(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String sanitizeKey(String key) => key.replaceAll(RegExp(r'[^\w\-]'), '_');
}
