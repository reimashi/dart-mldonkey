import 'connection-state.dart';

class HostState {
  final ConnectionState connectionState;
  final int rank;

  HostState(this.connectionState, [this.rank = 0]);
}
