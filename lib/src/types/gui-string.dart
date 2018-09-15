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
          Endian.little);
      head.setInt32(2, source.length > 0xffff ? source.length : 0x00,
          Endian.little);
    }
    else {
      headRaw = new Uint8List(2);
      ByteData head = headRaw.buffer.asByteData();

      head.setInt16(0, source.length > 0xffff ? 0xffff : source.length,
          Endian.little);
    }

    return new List.from(headRaw)
      ..addAll(utf8.encode(source));
  }

  String toString() => this._str;

  static String read(ByteArrayReader data) {
    int size = data.readInt16(Endian.little);
    if (size == 0xffff) size = data.readInt32(Endian.little);
    if (size > 0) return data.readString(size, utf8);
    else return "";
  }

  static double readFloat(ByteArrayReader data) {
    return double.parse(GuiString.read(data));
  }
}