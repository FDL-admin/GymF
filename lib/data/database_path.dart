import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> resolveDatabasePath() async {
  final directory = await getApplicationDocumentsDirectory();
  return p.join(directory.path, 'gymf.db');
}
