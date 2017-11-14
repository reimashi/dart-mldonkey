import 'package:size_type/size_type.dart';
import 'file-state.dart';
import 'file-format.dart';
import 'comment.dart';
import 'subfile.dart';

class FileInfo {
  final int id;
  final int networkId;

  final String name;
  final List<String> otherNames;
  final Map<String, List<int>> hashes;
  final List<String> links;

  final Size size;
  final Size downloaded;
  double get completed => (downloaded.Bytes * 100) / size.Bytes;

  final int sources;
  final int clients;

  final FileState state;
  final int priority;

  final FileFormat format;

  final DateTime created;
  final DateTime lastSeen;

  final List<Comment> comments;

  final List<Subfile> subfiles;

  FileInfo({
    this.id, this.networkId,
    this.name, this.otherNames, this.hashes, this.links,
    this.size, this.downloaded,
    this.sources, this.clients,
    this.state, this.priority,
    this.format,
    this.created, this.lastSeen,
    this.comments,
    this.subfiles
  });

  String toString() => "${this.name} (${this.size}, ${this.completed.toStringAsFixed(2)}%)";
}