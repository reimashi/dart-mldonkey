import 'dart:io';
import 'dart:typed_data';
import 'package:mldonkey/src/states/addr.dart';
import 'gui-string.dart';
import 'byte_array_reader.dart';

import 'package:logging/logging.dart';

class GuiAddr {
  static Logger _log = new Logger("Address");

  static Addr read(ByteArrayReader data) {
    int type = data.readInt8();

    switch(type) {
      case 1:
        int geoIp = data.readInt8();
        String host = GuiString.read(data);
        int blocked = data.readInt8();
        return new Addr(new InternetAddress(host), geoIp, blocked != 0);
      case 0:
      default:
        ByteData ip = new ByteData(4);
        ip.setInt32(0, data.readInt32());
        int geoIp = data.readInt8();
        int blocked = data.readInt8();
        return new Addr(new InternetAddress("${ip.getUint8(3)}.${ip.getUint8(2)}.${ip.getUint8(1)}.${ip.getUint8(0)}"), geoIp, blocked != 0);
    }
  }
}