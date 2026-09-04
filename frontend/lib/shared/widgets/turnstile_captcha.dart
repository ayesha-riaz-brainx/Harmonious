import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:slot_1_tasks/core/config/turnstile_config.dart';

class TurnstileCaptcha extends StatefulWidget {
  const TurnstileCaptcha({
    super.key,
    required this.onToken,
    this.onExpired,
    this.onError,
  });

  final ValueChanged<String> onToken;
  final VoidCallback? onExpired;
  final VoidCallback? onError;

  @override
  State<TurnstileCaptcha> createState() => TurnstileCaptchaState();
}

class TurnstileCaptchaState extends State<TurnstileCaptcha> {
  static const _channelName = 'TurnstileChannel';
  static const _expiredToken = '__expired__';
  static const _errorToken = '__error__';

  late final WebViewController _controller;
  int _reloadNonce = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        _channelName,
        onMessageReceived: (message) {
          final token = message.message;
          if (token == _expiredToken) {
            widget.onExpired?.call();
            return;
          }
          if (token == _errorToken) {
            widget.onError?.call();
            return;
          }
          widget.onToken(token);
        },
      )
      ..loadHtmlString(_htmlForSiteKey(TurnstileConfig.siteKey!));
  }

  void reset() {
    setState(() => _reloadNonce += 1);
    _controller.loadHtmlString(_htmlForSiteKey(TurnstileConfig.siteKey!));
  }

  String _htmlForSiteKey(String siteKey) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background: transparent;
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 70px;
      }
    </style>
  </head>
  <body>
    <div
      class="cf-turnstile"
      data-sitekey="$siteKey"
      data-theme="dark"
      data-callback="onTurnstileSuccess"
      data-expired-callback="onTurnstileExpired"
      data-error-callback="onTurnstileError"
    ></div>
    <script>
      function onTurnstileSuccess(token) {
        $_channelName.postMessage(token);
      }
      function onTurnstileExpired() {
        $_channelName.postMessage('$_expiredToken');
      }
      function onTurnstileError() {
        $_channelName.postMessage('$_errorToken');
      }
    </script>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (!TurnstileConfig.isConfigured) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      key: ValueKey(_reloadNonce),
      height: 74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
