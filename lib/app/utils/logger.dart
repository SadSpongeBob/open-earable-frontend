import 'package:logger/logger.dart';

/// Global logger access for the application.
///
/// This module provides a lazily initialized [Logger] instance that must be
/// set once during app startup via [initLogger] and can then be accessed
/// anywhere through the [logger] getter.
late final Logger _logger;

/// Returns the globally initialized [Logger] instance.
///
/// The logger must be initialized by calling [initLogger] before accessing
/// this getter, otherwise a runtime error will occur.
Logger get logger => _logger;

/// Initializes the global [Logger] instance.
///
/// This should be called once during application startup (e.g. in `main()`
/// or dependency injection setup) before any logging is performed.
///
/// Subsequent calls will overwrite the previously set logger.
void initLogger(Logger logger) {
  _logger = logger;
}
