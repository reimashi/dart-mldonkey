import 'dart:io';

class Addr {
  final InternetAddress address;
  final int geoip;
  final bool blocked;

  Addr(this.address, this.geoip, this.blocked);
}
