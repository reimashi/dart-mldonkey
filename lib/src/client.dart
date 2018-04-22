import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:size_type/size_type.dart';
import 'package:logging/logging.dart';
import 'package:mldonkey/src/types/byte_array_reader.dart';

import 'package:mldonkey/src/states/setting-option.dart';
import 'package:mldonkey/src/states/server-info.dart';
import 'package:mldonkey/src/states/connection-state.dart';
import 'package:mldonkey/src/states/host-state.dart';
import 'package:mldonkey/src/states/network-info.dart';
import 'package:mldonkey/src/states/client-stats.dart';
import 'package:mldonkey/src/states/file-state.dart';
import 'package:mldonkey/src/states/file-format.dart';
import 'package:mldonkey/src/states/download-file-info.dart';
import 'package:mldonkey/src/states/shared-file-info.dart';
import 'package:mldonkey/src/states/subfile.dart';
import 'package:mldonkey/src/states/comment.dart';

import 'package:mldonkey/src/types/gui-string.dart';
import 'package:mldonkey/src/types/gui-addr.dart';
import 'package:mldonkey/src/types/gui-list.dart';
import 'package:mldonkey/src/types/gui-file-state.dart';
import 'package:mldonkey/src/types/gui-file-format.dart';
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

  Map<String, String> _options = {};
  Map<String, String> get options =>
      new Map<String, String>.from(this._options);

  ClientStats _stats = null;
  ClientStats get stats => this._stats == null ? null : this._stats.clone();
  final StreamController<ClientStats> _onStatsUpdateCtrl =
      new StreamController<ClientStats>.broadcast();
  Stream<ClientStats> get onStatsUpdate => this._onStatsUpdateCtrl.stream;

  // Downloading files
  Map<int, DownloadFileInfo> _downloadFiles = {};
  List<DownloadFileInfo> get downloadFiles =>
      new List<DownloadFileInfo>.from(this._downloadFiles.values);
  final StreamController<DownloadFileInfo> _onDownloadFileUpdateCtrl =
      new StreamController<DownloadFileInfo>.broadcast();
  Stream<DownloadFileInfo> get onDownloadFileUpdate =>
      this._onDownloadFileUpdateCtrl.stream;

  // Uploading files
  Map<int, SharedFileInfo> _uploadFiles = {};
  List<SharedFileInfo> get uploadFiles =>
      new List<SharedFileInfo>.from(this._uploadFiles.values);
  final StreamController<SharedFileInfo> _onUploadFileUpdateCtrl =
      new StreamController<SharedFileInfo>.broadcast();
  Stream<SharedFileInfo> get onUploadFileUpdate =>
      this._onUploadFileUpdateCtrl.stream;

  // Networks from download (Emule, kad...)
  List<NetworkInfo> _networks = [];
  List<NetworkInfo> get networksInfo =>
      new List<NetworkInfo>.from(this._networks);
  final StreamController<NetworkInfo> _onNetworkInfoUpdateCtrl =
      new StreamController<NetworkInfo>.broadcast();
  Stream<NetworkInfo> get onNetworkInfoUpdate =>
      this._onNetworkInfoUpdateCtrl.stream;

  // Servers, if network need it
  Map<int, ServerInfo> _servers = {};
  List<ServerInfo> get serversInfo =>
      new List<ServerInfo>.from(this._servers.values);
  final StreamController<ServerInfo> _onServerInfoUpdateCtrl =
      new StreamController<ServerInfo>.broadcast();
  Stream<ServerInfo> get onServerInfoUpdate =>
      this._onServerInfoUpdateCtrl.stream;

  // Settings of the control panel
  Map<String, SettingOption> _settings = {};
  List<SettingOption> get settings =>
      new List<SettingOption>.from(this._settings.values);
  final StreamController<SettingOption> _onSettingUpdateCtrl =
      new StreamController<SettingOption>.broadcast();
  Stream<SettingOption> get onSettingUpdate => this._onSettingUpdateCtrl.stream;

  // Console messages
  final StreamController<String> _onConsoleMessageCtrl =
      new StreamController<String>.broadcast();
  Stream<String> get onConsoleMessage => this._onConsoleMessageCtrl.stream;

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

  List<int> _buffer = null;
  void _handleMsg(List<int> data) {
    if (this._buffer == null) this._buffer = [];
    this._buffer.addAll(data);
    return this._parseMsg(data);
  }

  void _parseMsg(List<int> data) {
    ByteArrayReader buffer =
        new ByteArrayReader(data, Endianness.LITTLE_ENDIAN);

    int msgSize = buffer.readInt32();

    // If all message is inside the buffer
    if (msgSize <= buffer.length) {
      List<int> msgData = buffer.readBytes(msgSize);
      ByteArrayReader msgReader =
          new ByteArrayReader(msgData, Endianness.LITTLE_ENDIAN);

      //print("Size: ${msgReader.length}");
      int opcode = msgReader.readInt16();

      Future fut = null;
      switch (opcode) {
        case RecvOpCode.OptionsInfo:
          fut = this._handleMsgOptionsInfo(msgReader);
          break;
        case RecvOpCode.CoreProtocol:
          fut = this._handleMsgCoreProtocol(msgReader);
          break;
        case RecvOpCode.NetworkInfo:
          fut = this._handleMsgNetworkInfo(msgReader);
          break;
        case RecvOpCode.ClientStats:
          fut = this._handleMsgClientStats(msgReader);
          break;
        case RecvOpCode.FileInfo:
          fut = this._handleMsgFileInfo(msgReader);
          break;
        case RecvOpCode.FileDownloadUpdate:
          fut = this._handleMsgFileDownloadUpdate(msgReader);
          break;
        case RecvOpCode.ConsoleMessage:
          fut = this._handleMsgConsoleMessage(msgReader);
          break;
        case RecvOpCode.AddSectionOption:
          fut = this._handleMsgAddSectionOption(msgReader);
          break;
        case RecvOpCode.AddPluginOption:
          fut = this._handleMsgAddSectionOption(msgReader, true);
          break;
        case RecvOpCode.SharedFileInfo:
          fut = this._handleMsgSharedFileInfo(msgReader);
          break;
        case RecvOpCode.ServerInfo:
          fut = this._handleMsgServerInfo(msgReader);
          break;
        default:
          print("Unknown code: ${opcode}");
          this._handleMsgUnknown(msgReader);
      }

      fut?.catchError((err) {
        msgReader.seek(0);
        _log.severe("Error data: ${msgReader.toString(hexadecimal: true)}. msgSize: ${msgSize}");
      });

      if (buffer.length > msgSize + 4) {
        this._parseMsg(buffer.readBytes(buffer.length - (msgSize + 4)));
      }
    }
  }

  Future _handleMsgOptionsInfo(ByteArrayReader data) async {
    this._options.addAll(GuiList.readMapStringString(data));
  }

  Future _handleMsgServerInfo(ByteArrayReader data) async {
    var readHostState = (ByteArrayReader data) {
      int state = data.readInt8();

      switch (state) {
        case 1:
          return new HostState(ConnectionState.Connecting);
        case 2:
          return new HostState(ConnectionState.ConnectedInitiating);
        case 4:
          return new HostState(ConnectionState.Connected);
        case 6:
          return new HostState(ConnectionState.NewHost);
        case 7:
          return new HostState(ConnectionState.RemovedHost);
        case 8:
          return new HostState(ConnectionState.BlackListed);
        case 10:
          return new HostState(ConnectionState.ConnectedAndUnknown);
        case 3:
          return new HostState(
              ConnectionState.ConnectedDownloading, data.readInt32());
        case 5:
          return new HostState(
              ConnectionState.ConnectedQueued, data.readInt32());
        case 9:
          return new HostState(
              ConnectionState.NotConnectedQueued, data.readInt32());
        case 0:
        default:
          return new HostState(ConnectionState.NotConnected);
      }
    };

    var parsedServerInfo = new ServerInfo(
        data.readInt32(),
        data.readInt32(),
        GuiAddr.read(data),
        data.readInt16(),
        data.readInt32(),
        GuiList.readTags(data),
        data.readInt64(),
        data.readInt64(),
        readHostState(data),
        GuiString.read(data),
        GuiString.read(data),
        data.readInt8() != 0,
        GuiString.read(data),
        data.readInt64(),
        data.readInt64(),
        data.readInt64(),
        data.readInt64(),
        data.readInt32());

    this._servers[parsedServerInfo.id] = parsedServerInfo;
    this._onServerInfoUpdateCtrl.add(parsedServerInfo);
  }

  Future _handleMsgConsoleMessage(ByteArrayReader data) async {
    this._onConsoleMessageCtrl.add(GuiString.read(data).trim());
  }

  Future _handleMsgAddSectionOption(ByteArrayReader data,
      [plugin = false]) async {
    var parsedOpt = new SettingOption(
        GuiString.read(data),
        GuiString.read(data),
        GuiString.read(data),
        GuiString.read(data),
        GuiString.read(data),
        GuiString.read(data),
        GuiString.read(data),
        data.readInt8() != 0,
        plugin);

    this._settings[parsedOpt.name] = parsedOpt;
    this._onSettingUpdateCtrl.add(parsedOpt);
  }

  Future _handleMsgSharedFileInfo(ByteArrayReader data) async {
    var parsedInfo = new SharedFileInfo(
        id: data.readInt32(),
        networkId: data.readInt32(),
        name: GuiString.read(data),
        size: new Size(data.readInt64()),
        uploaded: new Size(data.readInt64()),
        requests: data.readInt32());

    this._uploadFiles[parsedInfo.id] = parsedInfo;
    this._onUploadFileUpdateCtrl.add(parsedInfo);
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
    int now = (new DateTime.now()).millisecondsSinceEpoch;

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
    FileFormat format = GuiFileFormat.read(data);
    String preferredName = GuiString.read(data);
    int lastSeen = data.readInt32();
    int priority = data.readInt32();
    String comment = GuiString.read(data);
    List<String> links = GuiList.readStrings(data);
    List<Subfile> subfiles = GuiList.readSubfiles(data);

    List<Comment> fileComments = [new Comment(2130706433, 0, "", 0, comment)];

    if (this._rProtocolVersion > 40) {
      String fileFormat = GuiString.read(data);
      fileComments.addAll(GuiList.readComments(data));
      String fileUser = GuiString.read(data);
      String fileGroup = GuiString.read(data);
    }

    DownloadFileInfo finfo = new DownloadFileInfo(
        id: fileid,
        networkId: netid,
        name: preferredName.length > 0 ? preferredName : names.first,
        otherNames: names,
        hashes: {"md4": md4},
        links: links,
        size: size,
        downloaded: downloaded,
        sources: sources,
        clients: clients,
        state: state,
        priority: priority,
        format: format,
        created: new DateTime.fromMillisecondsSinceEpoch(now - fileAge),
        lastSeen: new DateTime.fromMillisecondsSinceEpoch(now - lastSeen),
        comments: fileComments,
        subfiles: subfiles);

    this._downloadFiles[finfo.id] = finfo;
    this._onDownloadFileUpdateCtrl.add(finfo);
  }

  Future _handleMsgFileDownloadUpdate(ByteArrayReader data) async {
    int fileId = data.readInt32();

    if (this._downloadFiles.containsKey(fileId)) {
      int now = (new DateTime.now()).millisecondsSinceEpoch;
      this._downloadFiles[fileId].update(
          new Size(data.readInt64()),
          data.readFloat32(),
          new DateTime.fromMillisecondsSinceEpoch(now - data.readInt32()));
      this._onDownloadFileUpdateCtrl.add(this._downloadFiles[fileId]);
    } else {
      this._log.warning("FileDownloadUpdate of unknown file ${fileId}");
    }
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
