import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:http/http.dart';
import 'package:mldonkey/src/types/byte_array_reader.dart';

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
    ByteArrayReader msg = new ByteArrayReader(data, Endianness.LITTLE_ENDIAN);
    _log.info("RECV <= " + msg.toString(hexadecimal: true));

    int size = msg.readInt32();
    int opcode = msg.readInt16();

    switch(opcode) {
      case RecvOpCode.CoreProtocol: this._handleMsgCoreProtocol(msg); break;
      case RecvOpCode.NetworkInfo: this._handleMsgNetworkInfo(msg); break;
      default: this._handleMsgUnknown(msg);
    }
  }

  Future _handleMsgCoreProtocol(ByteArrayReader data) async {
    this._rProtocolVersion = data.readInt32();

    if (data.length == 20) { // Older versions
      this._cMaxOpcode = data.readInt32();
      this._rMaxOpcode = data.readInt32();
    }

    await this._sendMsgProtocolVersion();
    await this._sendMsgGuiInterestedInSources(true);
    await this._sendMsgGuiPassWord(this._user, this._password);
  }

  Future _handleMsgNetworkInfo(ByteArrayReader data) async {
    int id = data.readInt32();
    String netname = GuiString.read(data);
    print("${id} - ${netname}");
  }

  void _handleMsgUnknown(ByteArrayReader data) {
    _log.info("[MlDonkey] Unknown message " + data.toString(hexadecimal: true));
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

    _log.info("SEND => " + new ByteArrayReader(msg).toString(hexadecimal: true));
    this._socket.add(msg);
    return this._socket.flush();
  }

  static Future<Client> connect(host, int port) async {
    return Socket.connect(host, port)
        .then((socket) {
      return new Client._fromSocket(socket);
    });
  }
}
