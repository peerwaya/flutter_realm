part of flutter_realm;

final MethodChannel _realmMethodChannel =
    const MethodChannel('plugins.it_nomads.com/flutter_realm')
      ..setMethodCallHandler(MethodChannelTransport._handleMethodCall);

class MethodChannelTransport {
  final String realmId;
  final MethodChannel _channel;

  MethodChannelTransport(this.realmId, [MethodChannel channel])
      : _channel = channel ?? _realmMethodChannel;

  Stream<MethodCall> get methodCallStream =>
      _methodCallController.stream.where(_equalRealmId);

  Future<T> invokeMethod<T>(String method, [Map<String, dynamic> arguments]) =>
      _channel.invokeMethod<T>(method, _addRealmId(arguments));

  Map _addRealmId(Map<String, dynamic> arguments) {
    return {...arguments, 'realmId': realmId};
  }

  bool _equalRealmId(MethodCall call) => call.arguments['realmId'] == realmId;

  // ignore: close_sinks
  static final _methodCallController = StreamController<MethodCall>.broadcast();

  static Future<dynamic> _handleMethodCall(MethodCall call) {
    _methodCallController.add(call);
    return null;
  }

  static Future<void> reset() => _realmMethodChannel.invokeMethod('reset');
}
