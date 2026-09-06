import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('chrome.tabs.query')
external void _chromeTabsQuery(JSObject queryInfo, JSFunction callback);

@JS('browser.tabs.query')
external JSPromise _browserTabsQuery(JSObject queryInfo);

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
  try {
    final queryInfo = QueryInfo(active: true, currentWindow: true);

    // Try Firefox WebExtensions API (Promise-based)
    bool hasBrowser = globalContext.hasProperty('browser'.toJS).toDart;
    if (hasBrowser) {
      JSObject browserObj =
          globalContext.getProperty('browser'.toJS) as JSObject;
      if (browserObj.hasProperty('tabs'.toJS).toDart) {
        JSObject tabsObj = browserObj.getProperty('tabs'.toJS) as JSObject;
        if (tabsObj.hasProperty('query'.toJS).toDart) {
          final jsPromise = _browserTabsQuery(queryInfo as JSObject);
          final result = await jsPromise.toDart as JSArray<Tab>?;
          if (result != null && result.toDart.isNotEmpty) {
            return result.toDart.first.url;
          }
        }
      }
    }

    // Try Chrome Extensions API (Callback-based)
    bool hasChrome = globalContext.hasProperty('chrome'.toJS).toDart;
    if (hasChrome) {
      JSObject chromeObj = globalContext.getProperty('chrome'.toJS) as JSObject;
      if (chromeObj.hasProperty('tabs'.toJS).toDart) {
        JSObject tabsObj = chromeObj.getProperty('tabs'.toJS) as JSObject;
        if (tabsObj.hasProperty('query'.toJS).toDart) {
          final completer = Completer<String?>();
          _chromeTabsQuery(
            queryInfo as JSObject,
            (JSArray<Tab>? tabs) {
              try {
                if (tabs != null && tabs.toDart.isNotEmpty) {
                  completer.complete(tabs.toDart.first.url);
                } else {
                  completer.complete(null);
                }
              } catch (e) {
                completer.complete(null);
              }
            }.toJS,
          );
          return await completer.future;
        }
      }
    }
  } catch (e) {
    // Ignore exceptions (e.g. lack of permissions or API errors) and fallback to null
  }

  return null;
}
