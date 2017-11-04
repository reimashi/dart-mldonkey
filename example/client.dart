import 'package:mldonkey/mldonkey.dart';
import 'package:logging/logging.dart';

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  Client pc = await Client.connect("vega", 4001);
  print("Connected");
}
