import 'package:firebase_performance/firebase_performance.dart';

/// Firebase Performance Monitoring Service
/// Track app performance and network requests
class FirebasePerformanceService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Initialize Performance Monitoring
  static Future<void> initialize() async {
    try {
      await _performance.setPerformanceCollectionEnabled(true);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Create a trace for VPN connection
  static Future<Trace?> startVPNConnectionTrace(String serverName) async {
    try {
      final trace = _performance.newTrace('vpn_connection_$serverName');
      await trace.start();
      return trace;
    } catch (e) {
      return null;
    }
  }

  /// Stop a trace
  static Future<void> stopTrace(Trace? trace) async {
    try {
      if (trace != null) {
        await trace.stop();
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// Create a custom trace
  static Future<Trace?> startCustomTrace(String traceName) async {
    try {
      final trace = _performance.newTrace(traceName);
      await trace.start();
      return trace;
    } catch (e) {
      return null;
    }
  }

  /// Add metric to trace
  static Future<void> setTraceMetric(
    Trace? trace,
    String metricName,
    int value,
  ) async {
    try {
      if (trace != null) {
        trace.setMetric(metricName, value);
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// Add attribute to trace
  static Future<void> setTraceAttribute(
    Trace? trace,
    String attributeName,
    String value,
  ) async {
    try {
      if (trace != null) {
        trace.putAttribute(attributeName, value);
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// Track HTTP request performance
  static Future<HttpMetric?> startHttpMetric({
    required String url,
    required HttpMethod method,
  }) async {
    try {
      final metric = _performance.newHttpMetric(url, method);
      await metric.start();
      return metric;
    } catch (e) {
      return null;
    }
  }

  /// Stop HTTP metric
  static Future<void> stopHttpMetric(HttpMetric? metric) async {
    try {
      if (metric != null) {
        await metric.stop();
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// Track VPN connection performance
  static Future<void> trackVPNConnection({
    required String serverName,
    required Future<void> Function() connectionFunction,
  }) async {
    final trace = await startVPNConnectionTrace(serverName);
    try {
      await connectionFunction();
      await setTraceAttribute(trace, 'server_name', serverName);
      await setTraceAttribute(trace, 'success', 'true');
    } catch (e) {
      await setTraceAttribute(trace, 'success', 'false');
      await setTraceAttribute(trace, 'error', e.toString());
      rethrow;
    } finally {
      await stopTrace(trace);
    }
  }

  /// Track server list fetch performance
  static Future<T> trackServerListFetch<T>({
    required Future<T> Function() fetchFunction,
  }) async {
    final trace = await startCustomTrace('server_list_fetch');
    try {
      final result = await fetchFunction();
      await setTraceAttribute(trace, 'success', 'true');
      return result;
    } catch (e) {
      await setTraceAttribute(trace, 'success', 'false');
      await setTraceAttribute(trace, 'error', e.toString());
      rethrow;
    } finally {
      await stopTrace(trace);
    }
  }
}
