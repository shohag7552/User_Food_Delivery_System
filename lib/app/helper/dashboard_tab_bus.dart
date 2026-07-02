/// Lets pushed routes (e.g. the ecommerce product detail page) ask the
/// always-present root dashboard to open one of its tabs.
///
/// The dashboard registers its tab handler on mount and clears it on dispose;
/// other screens call [open] then pop back to the dashboard.
class DashboardTabBus {
  DashboardTabBus._();

  static void Function(int index)? _handler;

  static void register(void Function(int index) handler) =>
      _handler = handler;

  static void clear(void Function(int index) handler) {
    if (identical(_handler, handler)) _handler = null;
  }

  static bool get isReady => _handler != null;

  static void open(int index) => _handler?.call(index);
}
