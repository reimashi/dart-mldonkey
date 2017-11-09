import 'dart:convert';
import 'dart:typed_data';

/// Read data from byte array
class ByteArrayReader {
  final List<int> _data;
  int _position;

  final Endianness endian;

  ByteArrayReader(List<int> data, [Endianness endian = Endianness.BIG_ENDIAN])
      : this._data = data,
        this.endian = endian,
        this._position = 0;

  /// Get the current seek [position]
  int get position => this._position;

  /// Get the data [length] in bytes
  int get length => this._data.length;

  /// Read an unsigned byte
  int read() {
    if (this._position >= this._data.length)
      throw new Exception("End of array");
    return this._data[this._position++];
  }

  /// Set the read pointer to the [position]
  void seek(int position) {
    if (position > this._data.length)
      this._position = this._data.length;
    else
      this._position = position;

    // Negative position correction
    if (this._position < 0) {
      this._position = 0;
    }
  }

  /// Skip a [offset] of bytes. Negative values rewind the pointer.
  void skip(int offset) {
    this.seek(this._position + offset);
  }

  /// Read a set of bytes of [size].
  List<int> readBytes(int size) {
    if (size < 1)
      size = 1;
    else if (size > (this._data.length - this._position))
      size = this._data.length - this._position;

    var result = new List<int>();
    result.addAll(this._data.getRange(this._position, this._position + size));
    this._position += size;
    return result;
  }

  /// Read a 2 bytes int
  int readInt16([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(2));
    ByteData bd = li.buffer.asByteData();
    return bd.getInt16(0, endian);
  }

  /// Read a 2 bytes unsigned int
  int readUint16([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(2));
    ByteData bd = li.buffer.asByteData();
    return bd.getUint16(0, endian);
  }

  /// Read a 4 bytes int
  int readInt32([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(4));
    ByteData bd = li.buffer.asByteData();
    return bd.getInt32(0, endian);
  }

  /// Read a 4 bytes unsigned int
  int readUint32([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(4));
    ByteData bd = li.buffer.asByteData();
    return bd.getUint32(0, endian);
  }

  /// Read a 8 bytes int
  int readInt64([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(8));
    ByteData bd = li.buffer.asByteData();
    return bd.getInt64(0, endian);
  }

  /// Read a 8 bytes unsigned int
  int readUint64([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(8));
    ByteData bd = li.buffer.asByteData();
    return bd.getUint64(0, endian);
  }

  /// Read a 4 bytes float
  double readFloat32([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(8));
    ByteData bd = li.buffer.asByteData();
    return bd.getFloat32(0, endian);
  }

  /// Read a 8 bytes float
  double readFloat64([Endianness endian = null]) {
    if (endian == null) endian = this.endian;
    Uint8List li = new Uint8List.fromList(readBytes(8));
    ByteData bd = li.buffer.asByteData();
    return bd.getFloat64(0, endian);
  }

  /// Read a string of [size]
  String readString(int size, [Encoding encoding = UTF8]) {
    return encoding.decode(this.readBytes(size));
  }

  /// Convert the byte array to string as text. Optionally, can be converted
  /// to [hexadecimal] representation of the raw data.
  String toString({bool hexadecimal = false}) {
    if (hexadecimal)
      return _toHexString();
    else
      return UTF8.decode(this._data);
  }

  /// Convert the byte array to a hexadecimal string
  String _toHexString() {
    String hexstr = "0x";
    String tmp;
    for (num i = 0; i < this._data.length; i++) {
      tmp = this._data[i].toRadixString(16);
      hexstr += tmp.length == 1 ? "0" + tmp : tmp;
    }
    return hexstr;
  }
}
