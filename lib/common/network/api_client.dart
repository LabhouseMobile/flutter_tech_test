import 'dart:async';

import 'package:cabina/common/errors/exceptions.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper over [http.Client] that applies a timeout and maps transport
/// and status failures onto the [CabinaException] hierarchy.
class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<String> getString(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response =
          await _client.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      throw ApiException(
        'Request to ${uri.host} failed',
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (e) {
      throw NetworkException('Request to ${uri.host} timed out', cause: e);
    } on http.ClientException catch (e) {
      throw NetworkException('Could not reach ${uri.host}', cause: e);
    }
  }

  void dispose() => _client.close();
}
