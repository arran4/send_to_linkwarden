import 'dart:async';
import 'dart:js_interop';

@JS('chrome.tabs.query')
external void query(JSObject queryInfo, JSFunction callback);

@JS()
@anonymous
extension type Tab._(JSObject _) implements JSObject {
  external String? get url;
  external String? get title;
}

@JS()
@anonymous
extension type QueryInfo._(JSObject _) implements JSObject {
  external factory QueryInfo({bool? active, bool? currentWindow});
}

Future<String?> getCurrentTabUrl() async {
  final completer = Completer<String?>();

  final queryInfo = QueryInfo(active: true, currentWindow: true);

  query(queryInfo as JSObject, (JSArray<Tab> tabs) {
    if (tabs.toDart.isNotEmpty) {
      completer.complete(tabs.toDart.first.url);
    } else {
      completer.complete(null);
    }
  }.toJS);

  return completer.future;
}
