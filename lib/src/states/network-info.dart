import 'package:size_type/size_type.dart';

class NetworkInfo {
  final int id;
  final String name;

  final bool enabled;
  final String configFilename;

  final Size downloaded;
  final Size uploaded;

  final int connectedServers;

  final bool hasServers;
  final bool hasMultinet;
  final bool isVirtual;
  final bool hasSearch;
  final bool hasSupernodes;
  final bool hasUpload;

  final bool hasRooms; // Group chat
  final bool hasChat; // Private chat

  NetworkInfo(this.id, this.name, this.enabled, this.configFilename,
      this.downloaded, this.uploaded, this.connectedServers,
      {this.hasServers,
      this.hasMultinet,
      this.isVirtual,
      this.hasSearch,
      this.hasSupernodes,
      this.hasUpload,
      this.hasRooms,
      this.hasChat});
}
