import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';

import 'package:mldonkey/src/types/gui-string.dart';
import 'package:mldonkey/src/types/gui-network-info.dart';
import 'package:mldonkey/src/types/op-codes.dart';

class Client {
  final Logger _log = new Logger("Mldonkey Client");

  static const int PROTOCOL_VERSION = 41;

  Socket _socket;

  String _user;
  String _password;

  int _rProtocolVersion;
  int _rMaxOpcode = 0;
  int _cMaxOpcode = 0;

  Client._fromSocket(Socket sock, [String user = "admin", String password = ""]) {
    this._user = user;
    this._password = password;

    sock.listen(this._handleMsg,
        onError: (err) { print(err); },
        onDone: () {
          print("Done");
          sock.destroy();
        });

    this._socket = sock;
  }

  void _handleMsg(List<int> data) {
    _log.info("RECV <= " + _toHex(data));

    Uint8List li = new Uint8List.fromList(data);
    ByteData bd = li.buffer.asByteData();

    int size = bd.getInt32(0, Endianness.LITTLE_ENDIAN);
    int opcode = bd.getUint16(4, Endianness.LITTLE_ENDIAN);

    switch(opcode) {
      case RecvOpCode.CoreProtocol: this._handleMsgCoreProtocol(li.skip(5).toList()); break;
      case RecvOpCode.NetworkInfo: this._handleMsgNetworkInfo(li.skip(5).toList()); break;
      default: this._handleMsgUnknown(li.skip(5).toList());
    }
  }

  Future _handleMsgCoreProtocol(List<int> data) async {
    Uint8List li = new Uint8List.fromList(data);
    ByteData bd = li.buffer.asByteData();

    this._rProtocolVersion = bd.getInt32(0, Endianness.LITTLE_ENDIAN);

    if (data.length == 12) {
      this._cMaxOpcode = bd.getInt32(4, Endianness.LITTLE_ENDIAN);
      this._rMaxOpcode = bd.getInt32(8, Endianness.LITTLE_ENDIAN);
    }

    await this._sendMsgProtocolVersion();
    await this._sendMsgGuiInterestedInSources(true);
    await this._sendMsgGuiPassWord(this._user, this._password);
  }

  Future _handleMsgNetworkInfo(List<int> data) async {

  }

  void _handleMsgUnknown(List<int> data) {
    _log.info("[MlDonkey] Unknown message " + _toHex(data));
  }

  Future _sendMsgProtocolVersion() async {
    Uint8List headRaw = new Uint8List(4);
    ByteData head = headRaw.buffer.asByteData();
    head.setInt32(0, PROTOCOL_VERSION, Endianness.LITTLE_ENDIAN);

    return this._sendMsg(SendOpCode.ProtocolVersion, headRaw);
  }

  Future _sendMsgGuiInterestedInSources(bool enabled) async {
    return this._sendMsg(SendOpCode.InterestedInSources, [ enabled ? 1 : 0 ]);
  }

  Future _sendMsgGuiPassWord(String user, String password) async {
    GuiString fUser = new GuiString.fromString(user);
    GuiString fPassword = new GuiString.fromString(password);

    return this._sendMsg(SendOpCode.PassWord, new List.from(fPassword.bytes)..addAll(fUser.bytes));
  }

  Future _sendMsg(int opcode, List<int> content) async {
    Uint8List headRaw = new Uint8List(6);
    ByteData head = headRaw.buffer.asByteData();

    head.setInt32(0, content.length + 2, Endianness.LITTLE_ENDIAN);
    head.setInt16(4, opcode, Endianness.LITTLE_ENDIAN);

    List<int> msg = new List.from(headRaw)..addAll(content);

    _log.info("SEND => " + _toHex(msg));
    this._socket.add(msg);
    return this._socket.flush();
  }

  static Future<Client> connect(host, int port) async {
    return Socket.connect(host, port)
        .then((socket) {
      return new Client._fromSocket(socket);
    });
  }

  static String _toHex(List<int> data) {
    String hexstr = "0x";
    String tmp;
    for (num i = 0; i < data.length; i++) {
      tmp = data[i].toRadixString(16);
      hexstr += tmp.length == 1 ? "0" + tmp : tmp;
    }
    return hexstr;
  }
}
