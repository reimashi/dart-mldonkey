import 'package:size_type/size_type.dart';

class ClientStats {
  final Size totalUploaded;
  final Size totalDownloaded;
  final Size totalShared;

  final int sharedFiles;

  final int tcpUploadRate;
  final int tcpDownloadRate;
  final int udpUploadRate;
  final int udpDownloadRate;
  int get uploadRate => tcpUploadRate + udpUploadRate;
  int get downloadRate => tcpDownloadRate + udpDownloadRate;

  final int downloads;
  final int finished;

  ClientStats(
      this.totalUploaded,
      this.totalDownloaded,
      this.totalShared,
      this.sharedFiles,
      this.tcpUploadRate,
      this.tcpDownloadRate,
      this.udpUploadRate,
      this.udpDownloadRate,
      this.downloads,
      this.finished);

  ClientStats clone() {
    return new ClientStats(
        this.totalUploaded,
        this.totalDownloaded,
        this.totalShared,
        this.sharedFiles,
        this.tcpUploadRate,
        this.tcpDownloadRate,
        this.udpUploadRate,
        this.udpDownloadRate,
        this.downloads,
        this.finished);
  }
}
