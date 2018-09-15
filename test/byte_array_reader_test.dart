import 'package:mldonkey/mldonkey.dart';
import 'package:test/test.dart';
import 'dart:convert';

void main() {
  const String totest = "Hola mundo!";

  group('ByteArrayReader. Basic methods', () {
    ByteArrayReader data;

    setUp(() {
      data = new ByteArrayReader([0x80, 1, 0, 1, 0, 1, 0, 1]);
    });

    test('readBytes size', () {
      int size = 4;
      expect(data.readBytes(size).length, size);
    });
  });

  group('ByteArrayReader. Typed reads', () {
    ByteArrayReader data;

    setUp(() {
      data = new ByteArrayReader([0x80, 1, 0, 1]..addAll(utf8.encode(totest)));
    });

    test('Int8', () {
      expect(data.readInt8(), -128);
    });

    test("Uint8", () {
      expect(data.readUint8(), 128);
    });

    test('Int32', () {
      expect(data.readInt32(), -2147418111);
    });

    test("Uint32", () {
      expect(data.readUint32(), 2147549185);
    });

    test("String", () {
      data.skip(4);
      expect(data.readString(totest.length), equals(totest));
    });
  });
}
