import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;

bool _scriptInjected = false;

Future<void> _ensureScript() async {
  if (js.context.hasProperty('salangaBiometricAvailable')) {
    return;
  }
  if (_scriptInjected) {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return;
  }
  _scriptInjected = true;
  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..src = 'biometric.js?v=3'
    ..async = true;
  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onError.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  html.document.head?.append(script);
  await completer.future.timeout(
    const Duration(seconds: 4),
    onTimeout: () {},
  );
}

bool _isAppleMobile() {
  final ua = html.window.navigator.userAgent;
  final iPhone = ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod');
  final iPadOs = ua.contains('Mac') && (html.window.navigator.maxTouchPoints ?? 0) > 1;
  return iPhone || iPadOs;
}

Future<bool> canUseBiometrics() async {
  await _ensureScript();
  try {
    if (js.context.hasProperty('salangaBiometricAvailable')) {
      final result = await js_util.promiseToFuture<dynamic>(
        js.context.callMethod('salangaBiometricAvailable'),
      );
      if (result == true) return true;
    }
  } catch (_) {}
  if (_isAppleMobile()) return true;
  return js.context.hasProperty('PublicKeyCredential');
}

Future<bool> authenticateBiometrics(String reason) async {
  await _ensureScript();
  try {
    if (!js.context.hasProperty('salangaBiometricAuthenticate')) {
      return false;
    }
    final result = await js_util.promiseToFuture<dynamic>(
      js.context.callMethod('salangaBiometricAuthenticate'),
    );
    return result == true;
  } catch (_) {
    return false;
  }
}

String lastBiometricError() {
  try {
    if (js.context.hasProperty('salangaBiometricLastError')) {
      return js.context['salangaBiometricLastError']?.toString() ?? '';
    }
  } catch (_) {}
  return '';
}

Future<void> clearBiometrics() async {
  try {
    if (js.context.hasProperty('salangaBiometricClear')) {
      js.context.callMethod('salangaBiometricClear');
    }
  } catch (_) {}
}
