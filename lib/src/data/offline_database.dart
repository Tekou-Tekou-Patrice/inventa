import 'package:sembast/sembast.dart';

import 'offline_database_native.dart'
    if (dart.library.html) 'offline_database_web.dart' as platform;

Future<Database> openOfflineDatabase(String name) =>
    platform.openPlatformOfflineDatabase(name);
