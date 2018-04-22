import 'package:size_type/size_type.dart';

abstract class FileInfo {
  final int id;
  final int networkId;
  final String name;
  final Size size;

  FileInfo(this.id, this.networkId, this.name, this.size);
}