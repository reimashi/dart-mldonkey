import 'file-info.dart';
import 'package:size_type/size_type.dart';

class SharedFileInfo extends FileInfo {
  final Size uploaded;
  final int requests;

  SharedFileInfo({
    int id, int networkId,
    String name, Size size, this.uploaded,
    this.requests
  }) : super(id, networkId, name, size);
}