part of flutter_realm;

final _uuid = Uuid();

Map<String, dynamic> _asStringKeyedMap(Map<dynamic, dynamic> map) {
  if (map == null) return null;
  if (map is Map<String, dynamic>) {
    return map;
  } else {
    return Map<String, dynamic>.from(map);
  }
}

class QueryResult {
  final int count;
  final List result;
  QueryResult({this.count, this.result});

  factory QueryResult.fromMap(Map<String, dynamic> map) {
    return QueryResult(
      count: map['count'],
      result: map['results'],
    );
  }
}

class Realm {
  final _channel = MethodChannelTransport(_uuid.v4());
  final _unsubscribing = Set<String>();

  String get id => _channel.realmId;

  Realm._() {
    _channel.methodCallStream.listen(_handleMethodCall);
  }

  static Future<Realm> open(Configuration configuration) async {
    final realm = Realm._();
    await realm._invokeMethod('initialize', configuration.toMap());
    return realm;
  }

  static Future<Realm> asyncOpenWithConfiguration({
    @required String syncServerURL,
    bool fullSynchronization = false,
  }) async {
    final realm = Realm._();
    await realm._invokeMethod('asyncOpenWithConfiguration', {
      'syncServerURL': syncServerURL,
      'fullSynchronization': fullSynchronization,
    });
    return realm;
  }

  static Future<Realm> syncOpenWithConfiguration({
    @required String syncServerURL,
    bool fullSynchronization = false,
  }) async {
    final realm = Realm._();
    await realm._invokeMethod('syncOpenWithConfiguration', {
      'syncServerURL': syncServerURL,
      'fullSynchronization': fullSynchronization,
    });
    return realm;
  }

  void _handleMethodCall(MethodCall call) {
    switch (call.method) {
      case 'onResultsChange':
        final subscriptionId = call.arguments['subscriptionId'];
        if (_unsubscribing.contains(subscriptionId)) {
          return;
        }

        if (subscriptionId == null ||
            !_subscriptions.containsKey(subscriptionId)) {
          throw ('Unknown subscriptionId: [$subscriptionId]. Call: $call');
        }
        // ignore: close_sinks
        final controller = _subscriptions[subscriptionId];
        controller.value =
            QueryResult.fromMap(_asStringKeyedMap(call.arguments));
        break;
      default:
        throw ('Unknown method: $call');
        break;
    }
  }

  Future<void> deleteAllObjects() => _channel.invokeMethod('deleteAllObjects');

  static Future<void> reset() => MethodChannelTransport.reset();

  void close() {
    final ids = _subscriptions.keys.toList();
    for (final subscriptionId in ids) {
      _unsubscribe(subscriptionId);
    }
    _subscriptions.clear();
  }

  Future<T> _invokeMethod<T>(String method, [dynamic arguments]) =>
      _channel.invokeMethod(method, arguments);

  final Map<String, BehaviorSubject<QueryResult>> _subscriptions = {};

  Future<List> allObjects(String className) =>
      _invokeMethod('allObjects', {'\$': className});

  Stream<QueryResult> subscribeAllObjects(String className) {
    final subscriptionId =
        'subscribeAllObjects:' + className + ':' + _uuid.v4();

    final controller = BehaviorSubject<QueryResult>(onCancel: () {
      _unsubscribe(subscriptionId);
    });

    _subscriptions[subscriptionId] = controller;
    _invokeMethod('subscribeAllObjects', {
      '\$': className,
      'subscriptionId': subscriptionId,
    });

    return controller;
  }

  Stream<QueryResult> subscribeObjects(Query query, {int limit = -1}) {
    final subscriptionId =
        'subscribeObjects:' + query.className + ':' + _uuid.v4();

    // ignore: close_sinks
    final controller = BehaviorSubject<QueryResult>(onCancel: () {
      _unsubscribe(subscriptionId);
    });

    _subscriptions[subscriptionId] = controller;
    _invokeMethod('subscribeObjects', {
      '\$': query.className,
      'predicate': query._container,
      'subscriptionId': subscriptionId,
      'limit': limit
    });

    return controller.stream;
  }

  Future<QueryResult> objects(Query query,
      {int limit = -1, String orderBy, bool ascending = true}) async {
    final map = await _invokeMethod('objects', {
      '\$': query.className,
      'predicate': query._container,
      'limit': limit,
      'orderBy': orderBy,
      'ascending': ascending
    });
    return QueryResult.fromMap(_asStringKeyedMap(map));
  }

  Future<Map<String, dynamic>> createObject(
      String className, Map<String, dynamic> object) async {
    final map = await _invokeMethod(
        'createObject', <String, dynamic>{'\$': className}..addAll(object));
    return _asStringKeyedMap(map);
  }

  Future<Map<String, dynamic>> object(String className,
      {@required dynamic primaryKey}) async {
    final map = await _invokeMethod('object', {
      '\$': className,
      'primaryKey': primaryKey,
    });
    return _asStringKeyedMap(map);
  }

  Future _unsubscribe(String subscriptionId) async {
    if (!_subscriptions.containsKey(subscriptionId)) {
      return;
    }
    _subscriptions[subscriptionId].close();
    _subscriptions.remove(subscriptionId);

    _unsubscribing.add(subscriptionId);
    await _invokeMethod('unsubscribe', {'subscriptionId': subscriptionId});
    _unsubscribing.remove(subscriptionId);
  }

  Future<Map<String, dynamic>> update(String className,
      {@required dynamic primaryKey,
      @required Map<String, dynamic> value}) async {
    assert(value['uuid'] == null);
    final map = await _invokeMethod('updateObject', {
      '\$': className,
      'primaryKey': primaryKey,
      'value': value,
    });
    return _asStringKeyedMap(map);
  }

  Future delete(String className, {@required dynamic primaryKey}) {
    return _invokeMethod('deleteObject', {
      '\$': className,
      'primaryKey': primaryKey,
    });
  }

  Future<int> deleteRecording(
      {@required dynamic primaryKey, String scheduleId}) {
    return _invokeMethod('deleteRecording',
        {'primaryKey': primaryKey, 'scheduleId': scheduleId});
  }

  Future<int> deleteAllRecordings(
      {@required List<String> primaryKeys, String scheduleId}) {
    return _invokeMethod('deleteAllRecordings',
        {'primaryKeys': primaryKeys, 'scheduleId': scheduleId});
  }

  Future<QueryResult> getRecordingIdsForScheduleIds(List<String> scheduleIds,
      {String orderBy, bool ascending = true}) async {
    final map = await _invokeMethod('getRecordingIdsForScheduleIds', {
      'scheduleIds': scheduleIds,
      'orderBy': orderBy,
      'ascending': ascending
    });
    return QueryResult.fromMap(_asStringKeyedMap(map));
  }

  Future<QueryResult> getRecordingIdsForSchedule(String scheduleId,
      {String orderBy, bool ascending = true}) async {
    final map = await _invokeMethod('getRecordingIdsForSchedule',
        {'scheduleId': scheduleId, 'orderBy': orderBy, 'ascending': ascending});
    return QueryResult.fromMap(_asStringKeyedMap(map));
  }

  Future<QueryResult> getScheduleIdsWithRecordings(List<String> scheduleIds,
      {String orderBy, bool ascending = true}) async {
    final map = await _invokeMethod('getScheduleIdsWithRecordings', {
      'scheduleIds': scheduleIds,
      'orderBy': orderBy,
      'ascending': ascending
    });
    return QueryResult.fromMap(_asStringKeyedMap(map));
  }

  Future<QueryResult> getAllScheduleIds(
      {int limit = -1, String orderBy, bool ascending = true}) async {
    final map = await _invokeMethod('getAllScheduleIds',
        {'limit': limit, 'orderBy': orderBy, 'ascending': ascending});
    return QueryResult.fromMap(_asStringKeyedMap(map));
  }

  Future<String> filePath() => _invokeMethod('filePath');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Realm && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Query {
  final String className;

  List _container = <dynamic>[];

  Query(this.className);

  Query greaterThan(String field, dynamic value) =>
      _pushThree('greaterThan', field, value);

  Query greaterThanOrEqualTo(String field, dynamic value) =>
      _pushThree('greaterThanOrEqualTo', field, value);

  Query lessThan(String field, dynamic value) =>
      _pushThree('lessThan', field, value);

  Query lessThanOrEqualTo(String field, dynamic value) =>
      _pushThree('lessThanOrEqualTo', field, value);

  Query equalTo(String field, dynamic value) =>
      _pushThree('equalTo', field, value);

  Query contains(String field, String value) =>
      _pushThree('contains', field, value);

  Query isIn(String field, List value) => _pushThree('in', field, value);

  Query notEqualTo(String field, dynamic value) =>
      _pushThree('notEqualTo', field, value);

  Query _pushThree(String operator, dynamic left, dynamic right) {
    _container.add([operator, left, right]);
    return this;
  }

  Query _pushOne(String operator) {
    _container.add([operator]);
    return this;
  }

  Query and() => this.._pushOne('and');

  Query or() => this.._pushOne('or');

  @override
  String toString() {
    return 'RealmQuery{className: $className, _container: $_container}';
  }
}

class Configuration {
  final String inMemoryIdentifier;
  final Uint8List encryptionKey;

  const Configuration({this.inMemoryIdentifier, this.encryptionKey});

  Map<String, dynamic> toMap() => {
        'inMemoryIdentifier': inMemoryIdentifier,
        'encryptionKey': encryptionKey
      };

  static const Configuration defaultConfiguration = const Configuration();
}
