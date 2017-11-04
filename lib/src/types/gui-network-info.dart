import 'package:mldonkey/src/types/network-flags.dart';

class GuiNetworkInfo {
  int id;
  String name;
  bool enabled;
  String configFilename;
  int uploaded;
  int downloaded;
  int connected;
  List<NetworkFlags> flags;
}