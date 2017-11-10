import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:size_type/size_type.dart';
import 'package:logging/logging.dart';
import 'package:mldonkey/src/types/byte_array_reader.dart';

import 'package:mldonkey/src/states/network-info.dart';
import 'package:mldonkey/src/states/client-stats.dart';
import 'package:mldonkey/src/states/file-state.dart';

import 'package:mldonkey/src/types/gui-string.dart';
import 'package:mldonkey/src/types/gui-list.dart';
import 'package:mldonkey/src/types/gui-file-state.dart';
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

  ClientStats _stats = null;
  ClientStats get stats => this._stats == null ? null : this._stats.clone();
  final StreamController<ClientStats> _onStatsUpdateCtrl =
      new StreamController<ClientStats>.broadcast();
  Stream<ClientStats> get onStatsUpdate => this._onStatsUpdateCtrl.stream;

  List<NetworkInfo> _networks = [];
  List<NetworkInfo> get networksInfo =>
      new List<NetworkInfo>.from(this._networks);
  final StreamController<NetworkInfo> _onNetworkInfoUpdateCtrl =
      new StreamController<NetworkInfo>.broadcast();
  Stream<NetworkInfo> get onNetworkInfoUpdate =>
      this._onNetworkInfoUpdateCtrl.stream;

  Client._fromSocket(Socket sock,
      [String user = "admin", String password = ""]) {
    this._user = user;
    this._password = password;

    sock.listen(this._handleMsg, onError: (err) {
      print(err);
    }, onDone: () {
      print("Done");
      sock.destroy();
    });

    this._socket = sock;
  }

  void _handleMsg(List<int> data) {
    ByteArrayReader msg = new ByteArrayReader(data, Endianness.LITTLE_ENDIAN);

    int size = msg.readInt32();
    int opcode = msg.readInt16();

    switch (opcode) {
      case RecvOpCode.CoreProtocol:
        this._handleMsgCoreProtocol(msg);
        break;
      case RecvOpCode.NetworkInfo:
        this._handleMsgNetworkInfo(msg);
        break;
      case RecvOpCode.ClientStats:
        this._handleMsgClientStats(msg);
        break;
      case RecvOpCode.FileInfo:
        this._handleMsgFileInfo(msg);
        break;
      default:
        print(opcode);
        this._handleMsgUnknown(msg);
    }
  }

  Future _handleMsgCoreProtocol(ByteArrayReader data) async {
    this._rProtocolVersion = data.readInt32();

    if (data.length == 20) {
      // Older versions
      this._cMaxOpcode = data.readInt32();
      this._rMaxOpcode = data.readInt32();
    }

    await this._sendMsgProtocolVersion();
    await this._sendMsgGuiInterestedInSources(true);
    await this._sendMsgGuiPassWord(this._user, this._password);
  }

  Future _handleMsgNetworkInfo(ByteArrayReader data) async {
    int id = data.readInt32();
    String name = GuiString.read(data);
    bool enabled = data.readInt8() == 1;
    String configFilename = GuiString.read(data);
    int uploaded = data.readInt64();
    int downloaded = data.readInt64();
    int connectedServers = data.readInt32();
    List<int> flags = GuiList.readInt16(data);

    NetworkInfo info = new NetworkInfo(id, name, enabled, configFilename,
        new Size(downloaded), new Size(uploaded), connectedServers,
        hasServers: flags.contains(0),
        hasRooms: flags.contains(1),
        hasMultinet: flags.contains(2),
        isVirtual: flags.contains(3),
        hasSearch: flags.contains(4),
        hasChat: flags.contains(5),
        hasSupernodes: flags.contains(6),
        hasUpload: flags.contains(7));

    if (this._networks.map((net) => net.id).contains(id)) {
      this._networks.removeWhere((net) => net.id == id);
    }

    this._networks.add(info);
    this._onNetworkInfoUpdateCtrl.add(info);
  }

  Future _handleMsgClientStats(ByteArrayReader data) async {
    ClientStats stats = new ClientStats(
        new Size(data.readInt64()),
        new Size(data.readInt64()),
        new Size(data.readInt64()),
        data.readInt32(),
        data.readInt32(),
        data.readInt32(),
        data.readInt32(),
        data.readInt32(),
        data.readInt32(),
        data.readInt32());

    // Update stats
    this._stats = stats;
    this._onStatsUpdateCtrl.add(stats);

    // TODO: Update server list
    GuiList.readMapInt32(data);
  }

  Future _handleMsgFileInfo(ByteArrayReader data) async {
    int fileid = data.readInt32();
    int netid = data.readInt32();
    List<String> names = GuiList.readStrings(data);
    List<int> md4 = data.readBytes(16);
    Size size = new Size(data.readInt64());
    Size downloaded = new Size(data.readInt64());
    int sources = data.readInt32();
    int clients = data.readInt32();
    FileState state = GuiFileState.read(data);
    String chunks = GuiString.read(data);
    Map<int, String> availability = GuiList.readMapInt32String(data);
    double downloadSpeed = GuiString.readFloat(data);
    List<int> chunkAges = GuiList.readInt32(data);
    int fileAge = data.readInt32();
    print("Descarga: ${names.first} (${md4})");
    print("Tamaño: (${downloaded}) ${size} \tSources: ${sources} \tAge: ${fileAge}");
    print(size);
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
    return this._sendMsg(SendOpCode.InterestedInSources, [enabled ? 1 : 0]);
  }

  Future _sendMsgGuiPassWord(String user, String password) async {
    GuiString fUser = new GuiString.fromString(user);
    GuiString fPassword = new GuiString.fromString(password);

    return this._sendMsg(SendOpCode.PassWord,
        new List.from(fPassword.bytes)..addAll(fUser.bytes));
  }

  Future _sendMsg(int opcode, List<int> content) async {
    Uint8List headRaw = new Uint8List(6);
    ByteData head = headRaw.buffer.asByteData();

    head.setInt32(0, content.length + 2, Endianness.LITTLE_ENDIAN);
    head.setInt16(4, opcode, Endianness.LITTLE_ENDIAN);

    List<int> msg = new List.from(headRaw)..addAll(content);

    _log.info(
        "SEND => " + new ByteArrayReader(msg).toString(hexadecimal: true));
    this._socket.add(msg);
    return this._socket.flush();
  }

  static Future<Client> connect(host, int port) async {
    return Socket.connect(host, port).then((socket) {
      return new Client._fromSocket(socket);
    });
  }
}
