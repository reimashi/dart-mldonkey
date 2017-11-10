import 'dart:typed_data';
import 'byte_array_reader.dart';
import 'gui-string.dart';

class GuiList {
  static List<int> readInt16(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    List<int> toret = new List<int>();

    for (int i = 0; i < size; i++) {
      toret.add(data.readInt16(Endianness.LITTLE_ENDIAN));
    }

    return toret;
  }

  static List<int> readInt32(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    List<int> toret = new List<int>();

    for (int i = 0; i < size; i++) {
      toret.add(data.readInt32(Endianness.LITTLE_ENDIAN));
    }

    return toret;
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

  static List<String> readStrings(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    List<String> toret = [];

    for (int i = 0; i < size; i++) {
      toret.add(GuiString.read(data));
    }

    return toret;
  }
}