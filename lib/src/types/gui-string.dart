import 'dart:typed_data';
import 'dart:convert';
import 'byte_array_reader.dart';

class GuiString {
  final int length;
  final String _str;

  GuiString.fromString(String str) : this.length = str.length, this._str = str;

  List<int> get bytes {
    String source = _str.toString();
    Uint8List headRaw;

    if (source.length > 0xffff) {
      headRaw = new Uint8List(6);
      ByteData head = headRaw.buffer.asByteData();

      head.setInt16(0, source.length > 0xffff ? 0xffff : source.length,
          Endianness.LITTLE_ENDIAN);
      head.setInt32(2, source.length > 0xffff ? source.length : 0x00,
          Endianness.LITTLE_ENDIAN);
    }
    else {
      headRaw = new Uint8List(2);
      ByteData head = headRaw.buffer.asByteData();

      head.setInt16(0, source.length > 0xffff ? 0xffff : source.length,
          Endianness.LITTLE_ENDIAN);
    }

    return new List.from(headRaw)
      ..addAll(UTF8.encode(source));
  }

  String toString() => this._str;

  static String read(ByteArrayReader data) {
    int size = data.readInt16(Endianness.LITTLE_ENDIAN);
    if (size == 0xffff) size = data.readInt32(Endianness.LITTLE_ENDIAN);
    return data.readString(size, UTF8);
  }

  static double readFloat(ByteArrayReader data) {
    return double.parse(GuiString.read(data));
  }
}