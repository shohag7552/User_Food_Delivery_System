import 'package:flutter/material.dart';

/// Shared state behind the web top-nav search field.
///
/// Every page's [WebTopNav] renders the same search box backed by this single
/// [controller], so the typed query survives navigation. The search page
/// registers a handler to receive submitted queries; when no handler is
/// registered (user submitted from another page) the nav field opens the
/// search route first and the page picks the text up on init.
class WebSearchBus {
  WebSearchBus._();

  static final TextEditingController controller = TextEditingController();

  // ── Focus ──
  // Each mounted top-nav field owns its own FocusNode and registers it here
  // (a single shared node breaks when two nav bars are mounted during a route
  // transition). Focus requests go to the most recently attached — the field
  // on the visible page.
  static final List<FocusNode> _focusNodes = [];

  static void attachFocus(FocusNode node) => _focusNodes.add(node);

  static void detachFocus(FocusNode node) => _focusNodes.remove(node);

  static void requestFocus() {
    if (_focusNodes.isNotEmpty) _focusNodes.last.requestFocus();
  }

  // ── Query handler (registered by the search page) ──

  static void Function(String query)? _handler;

  static void register(void Function(String query) handler) =>
      _handler = handler;

  static void clear(void Function(String query) handler) {
    // Compare with == rather than identical(): instance-method tear-offs are
    // equal but not guaranteed identical, and a failed clear would leave a
    // dead handler behind (blocking every search after the page closes).
    if (_handler == handler) _handler = null;
  }

  /// Whether the search page is currently listening.
  static bool get isReady => _handler != null;

  static void submit(String query) => _handler?.call(query);
}
