import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class PwaInstall {
  PwaInstall._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();
  static var _listening = false;

  static Stream<void> get onAvailabilityChanged {
    _ensureListening();
    return _controller.stream;
  }

  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    html.window.addEventListener('salanga-install-available', (_) {
      _controller.add(null);
    });
  }

  static bool get isSupported => true;

  static bool get isStandalone => _readBool('salangaIsStandalone');

  static bool get canPrompt => _readBool('salangaCanInstall');

  static bool get isIos => _readBool('salangaIsIos');

  static bool get isAndroid => _readBool('salangaIsAndroid');

  static bool get shouldShowHelp =>
      !isStandalone && (canPrompt || isIos || isAndroid);

  static Future<bool> prompt() async {
    _ensureListening();
    final promise = js.context.callMethod('salangaPromptInstall');
    final result = await _promiseToFuture(promise);
    return result == true;
  }

  static bool _readBool(String property) {
    _ensureListening();
    return js.context[property] == true;
  }

  static Future<dynamic> _promiseToFuture(dynamic promise) {
    final completer = Completer<dynamic>();
    promise.callMethod('then', [
      js_util.allowInterop((value) {
        if (!completer.isCompleted) completer.complete(value);
      }),
    ]);
    promise.callMethod('catch', [
      js_util.allowInterop((error) {
        if (!completer.isCompleted) completer.completeError(error);
      }),
    ]);
    return completer.future;
  }
}
