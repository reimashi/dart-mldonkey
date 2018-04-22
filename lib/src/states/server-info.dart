import 'package:mldonkey/src/states/addr.dart';
import 'package:mldonkey/src/states/host-state.dart';

class ServerInfo {
  final int id;
  final int networkId;
  final Addr address;
  final int port;
  final int score;
  final Map<String, Object> metadata;
  final int users;
  final int maxUsers;
  final int lowIdUsers;
  final int files;
  final HostState connectionState;
  final String name;
  final String description;
  final bool preferred;
  final String version;
  final int softLimit;
  final int hardLimit;
  final int ping;

  ServerInfo(
      this.id,
      this.networkId,
      this.address,
      this.port,
      this.score,
      this.metadata,
      this.users,
      this.files,
      this.connectionState,
      this.name,
      this.description,
      this.preferred,
      this.version,
      this.maxUsers,
      this.lowIdUsers,
      this.softLimit,
      this.hardLimit,
      this.ping);
}
