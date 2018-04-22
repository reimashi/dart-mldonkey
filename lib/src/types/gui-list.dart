import 'dart:typed_data';
import 'package:size_type/size_type.dart';
import 'byte_array_reader.dart';
import 'gui-string.dart';
import 'package:mldonkey/src/states/subfile.dart';
import 'package:mldonkey/src/states/comment.dart';

typedef T ListParser<T>(ByteArrayReader data);

class GuiList {
  static List<T> read<T>(ByteArrayReader data, ListParser<T> parser) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    List<T> toret = new List<T>();

    for (int i = 0; i < size; i++) {
      toret.add(parser(data));
    }

    return toret;
  }

  static List<int> readInt16(ByteArrayReader data) {
    return read<int>(data, (data) => data.readInt16(Endianness.LITTLE_ENDIAN));
  }

  static List<int> readInt32(ByteArrayReader data) {
    return read<int>(data, (data) => data.readInt32(Endianness.LITTLE_ENDIAN));
  }

  static Map<int, int> readMapInt32(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    Map<int, int> toret = {};

    for (int i = 0; i < size; i++) {
      int key = data.readInt32(Endianness.LITTLE_ENDIAN);
      int val = data.readInt32(Endianness.LITTLE_ENDIAN);
      toret[key] = val;
    }

    return toret;
  }

  static Map<int, String> readMapInt32String(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    Map<int, String> toret = {};

    for (int i = 0; i < size; i++) {
      int key = data.readInt32(Endianness.LITTLE_ENDIAN);
      String val = GuiString.read(data);
      toret[key] = val;
    }

    return toret;
  }

  static Map<String, String> readMapStringString(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    Map<String, String> toret = {};

    for (int i = 0; i < size; i++) {
      String key = GuiString.read(data);
      String val = GuiString.read(data);
      toret[key] = val;
    }

    return toret;
  }

  static Map<String, Object> readTags(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    Map<String, Object> toret = {};

    for (int i = 0; i < size; i++) {
      String key = GuiString.read(data);
      int type = data.readInt8();
      Object val = null;

      switch (type) {
        case 0: val = data.readUint32(); break;
        case 1: val = data.readInt32(); break;
        case 2: val = GuiString.read(data); break;
        case 3: val = data.readInt32(); break;
        case 4: val = data.readInt16(); break;
        case 5: val = data.readInt8(); break;
        case 6: val = data.readInt64(); break;
        default: throw new TypeError();
      }

      toret[key] = val;
    }

    return toret;
  }

  static List<String> readStrings(ByteArrayReader data) {
    return read<String>(data, (data) => GuiString.read(data));
  }

  static List<Subfile> readSubfiles(ByteArrayReader data) {
    return read<Subfile>(data, (data) {
      return new Subfile(
          GuiString.read(data),
          new Size(data.readInt64(Endianness.LITTLE_ENDIAN)),
          GuiString.read(data));
    });
  }

  static List<Comment> readComments(ByteArrayReader data) {
    return read<Comment>(data, (data) {
      return new Comment(
          data.readInt32(Endianness.LITTLE_ENDIAN),
          data.readInt8(),
          GuiString.read(data),
          data.readInt8(),
          GuiString.read(data));
    });
  }
}
