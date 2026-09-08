import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:slot_1_tasks/core/config/api_config.dart';
import 'package:slot_1_tasks/core/config/turnstile_config.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';

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

  WebViewController? _controller;
  bool _failed = false;
  String _status = 'Loading security check…';
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _createControllerAndLoad();
  }

  Uri get _captchaUri {
    final siteKey = TurnstileConfig.siteKey ?? '';
    return Uri.parse('${ApiConfig.baseUrl}/auth/turnstile.html').replace(
      queryParameters: {'sitekey': siteKey},
    );
  }

  void _createControllerAndLoad() {
    final generation = ++_loadGeneration;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E0E12))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted || generation != _loadGeneration) return;
            setState(() {
              _failed = false;
              _status = 'Loading security check…';
            });
          },
          onPageFinished: (_) {
            if (!mounted || generation != _loadGeneration) return;
            setState(() => _status = '');
          },
          onWebResourceError: (error) {
            if (!mounted || generation != _loadGeneration) return;
            debugPrint('Turnstile WebView error: ${error.description}');
            setState(() {
              _failed = true;
              _status =
                  'Unable to connect to website. Check your internet and try again.';
            });
            widget.onError?.call();
          },
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host ?? '';
            if (host.isEmpty ||
                host.contains('cloudflare') ||
                host.contains('harmonious.onrender.com') ||
                host == 'localhost' ||
                host == '10.0.2.2') {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        _channelName,
        onMessageReceived: (message) {
          if (!mounted || generation != _loadGeneration) return;
          final token = message.message;
          if (token == _expiredToken) {
            setState(() {
              _failed = true;
              _status = 'Security check expired. Tap Retry.';
            });
            widget.onExpired?.call();
            return;
          }
          if (token == _errorToken) {
            setState(() {
              _failed = true;
              _status =
                  'Unable to connect to website. Tap Retry, or verify Cloudflare hostnames.';
            });
            // Do NOT auto-reload here — that causes the blinking loop.
            widget.onError?.call();
            return;
          }
          setState(() {
            _failed = false;
            _status = '';
          });
          widget.onToken(token);
        },
      );

    _controller = controller;
    controller.loadRequest(_captchaUri);
  }

  void reset() {
    if (!mounted) return;
    setState(() {
      _failed = false;
      _status = 'Loading security check…';
    });
    _createControllerAndLoad();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!TurnstileConfig.isConfigured) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 92,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: const Color(0xFF0E0E12),
              child: _controller == null
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : WebViewWidget(controller: _controller!),
            ),
          ),
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _failed ? AppColors.coral : AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        if (_failed) ...[
          TextButton(
            onPressed: reset,
            child: const Text(
              'Retry security check',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}
