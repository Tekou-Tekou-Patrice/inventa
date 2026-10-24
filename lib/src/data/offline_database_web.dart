import 'package:sembast_web/sembast_web.dart';

Future<Database> openPlatformOfflineDatabase(String name) =>
    databaseFactoryWeb.openDatabase(name);
