import 'package:meta/meta.dart';
import 'package:size_type/size_type.dart';
import 'file-state.dart';
import 'file-format.dart';
import 'comment.dart';
import 'subfile.dart';
import 'file-info.dart';

class DownloadFileInfo extends FileInfo {
  final List<String> otherNames;
  final Map<String, List<int>> hashes;
  final List<String> links;

  Size _downloaded;
  Size get downloaded => this._downloaded;
  double get completed => (downloaded.Bytes * 100) / size.Bytes;

  double _downloadRate = 0.0;
  double get downloadRate => this._downloadRate;

  final int sources;
  final int clients;

  final FileState state;
  final int priority;

  final FileFormat format;

  final DateTime created;
  DateTime _lastSeen;
  DateTime get lastSeen => this._lastSeen;

  final List<Comment> comments;

  final List<Subfile> subfiles;

  DownloadFileInfo(
      {int id,
      int networkId,
      String name,
      this.otherNames,
      this.hashes,
      this.links,
      Size size,
      Size downloaded,
      this.sources,
      this.clients,
      this.state,
      this.priority,
      this.format,
      this.created,
      DateTime lastSeen,
      this.comments,
      this.subfiles})
      : this._downloaded = downloaded,
        this._lastSeen = lastSeen,
        super(id, networkId, name, size);

  @visibleForOverriding
  void update(Size downloaded, double downloadRate, DateTime lastSeen) {
    this._downloaded = downloaded;
    this._downloadRate = downloadRate;
    this._lastSeen = lastSeen;
  }

  String toString() =>
      "${this.name} (${this.size}, ${this.completed.toStringAsFixed(2)}%)";
}
