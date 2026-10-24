import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openPlatformOfflineDatabase(String name) async {
  final directory = await getApplicationSupportDirectory();
  return databaseFactoryIo.openDatabase(path.join(directory.path, name));
}
