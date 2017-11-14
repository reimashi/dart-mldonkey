import 'package:mldonkey/src/states/file-type.dart';
import 'package:mldonkey/src/states/file-format.dart';

import 'byte_array_reader.dart';
import 'gui-string.dart';

import 'package:logging/logging.dart';

class GuiFileFormat {
  static Logger _log = new Logger("File format");

  static FileFormat read(ByteArrayReader data) {
    int type = data.readInt8();

    _log.fine("Type of format " + type.toString());
    if (type == 0) return new FileFormat("", FileType.Unknown, {});
    else if (type == 1) {
      _log.fine("Type 1");
      String ext = GuiString.read(data);
      String tt = GuiString.read(data);

      FileType ft = FileType.Unknown;
      if (tt.contains(r"/audio/gi")) ft = FileType.Audio;
      else if (tt.contains(r"/video/gi")) ft = FileType.Video;

      return new FileFormat(ext, ft, {});
    }
    else if (type == 2) {
      _log.fine("Type 2");
      Map<String, String> meta = {
        "codec": GuiString.read(data),
        "resolution": data.readInt32().toString() + "x" + data.readInt32().toString(),
        "fps": data.readInt32().toString(),
        "rate": data.readInt32().toString()
      };

      return new FileFormat("", FileType.Video, meta);
    }
    else if (type == 3) {
      _log.fine("Type 3");
      Map<String, String> meta = {
        "title": GuiString.read(data),
        "artist": GuiString.read(data),
        "album": GuiString.read(data),
        "year": GuiString.read(data),
        "comment": GuiString.read(data),
        "tracknum": data.readInt32().toString(),
        "genre": data.readInt32().toString(),
      };

      return new FileFormat("mp3", FileType.Audio, meta);
    }
    else if (type == 4) {
      _log.warning("Type 4 not implemented");
    }
    else {
      _log.warning("Unrecognized type");
    }
  }
}