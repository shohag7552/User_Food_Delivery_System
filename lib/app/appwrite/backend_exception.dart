/// A refusal from the backend function: [code] is the stable reason the
/// server gave (e.g. `price_changed`), [message] its readable text.
class BackendException implements Exception {
  final String code;
  final String message;

  /// The whole error object, e.g. the server's `totals` on `price_changed`.
  final Map<String, dynamic> details;

  const BackendException(this.code, this.message, {this.details = const {}});

  @override
  String toString() => 'BackendException($code): $message';
}
