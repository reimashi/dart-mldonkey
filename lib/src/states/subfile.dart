import 'package:size_type/size_type.dart';

class Subfile {
  final String name;
  final Size size;
  final String format;

  Subfile(
      this.name,
      this.size,
      this.format
    );

  String toString() => "Subfile: ${this.name} (${this.size}, ${this.format})";
}