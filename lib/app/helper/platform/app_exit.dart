// Picks the right implementation at compile time: native uses dart:io exit(0),
// web uses a no-op. This keeps the existing Android/iOS exit behavior intact
// while letting the same code compile for the web.
import 'app_exit_io.dart' if (dart.library.html) 'app_exit_web.dart' as platform;

void exitApp() => platform.exitApp();
