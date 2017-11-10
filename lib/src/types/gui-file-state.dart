import 'package:mldonkey/src/states/file-state.dart';
import 'gui-string.dart';
import 'byte_array_reader.dart';

import 'package:logging/logging.dart';

class GuiFileState {
  static Logger _log = new Logger("File status");

  static FileState read(ByteArrayReader data) {
    int type = data.readInt8();

    switch(type) {
      case 0: return FileState.Downloading;
      case 1: return FileState.Paused;
      case 2: return FileState.Downloaded;
      case 3: return FileState.Shared;
      case 4: return FileState.Cancelled;
      case 5: return FileState.New;
      case 6:
        _log.fine(GuiString.read(data));
        return FileState.Aborted;
      case 7: return FileState.Queued;
    }
  }
}