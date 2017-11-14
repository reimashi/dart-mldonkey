import 'file-type.dart';

class FileFormat {
  final String extension;
  final FileType type;
  final Map<String, String> meta;

  FileFormat(
      this.extension,
      this.type,
      this.meta
    );

  static FileFormat get Unknown => new FileFormat("", FileType.Unknown, {});

  String toString() => ".${extension} (${type})";
}