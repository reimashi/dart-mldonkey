import 'package:mldonkey/mldonkey.dart';
import 'package:logging/logging.dart';

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  Client pc = await Client.connect("localhost", 4001);

  pc.onStatsUpdate.listen((stats) {
    print("Stats: ${stats.downloadRate / 1024} - ${stats.uploadRate / 1024} kbps");
  });

  pc.onNetworkInfoUpdate.listen((netInfo) {
    print("Red: ${netInfo.name}\t\t${netInfo.downloaded} - ${netInfo.uploaded}");
  });

  print("Connected");
}
