// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? getWebLocalStorageToken() {
  try {
    return html.window.localStorage['aaroha_device_token'];
  } catch (e) {
    return null;
  }
}

void saveWebLocalStorageToken(String token) {
  try {
    html.window.localStorage['aaroha_device_token'] = token;
  } catch (e) {
    // Ignore if localStorage is disabled
  }
}
