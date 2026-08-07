import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';

/// Ephemeral personal companion chat. Session only — not saved.
class AiChatPage extends StatefulWidget {
  const AiChatPage({
    super.key,
    this.coach = 'Life Coach',
  });

  final String coach;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  static const _coaches = <(String, IconData, Color)>[
    ('Life Coach', Icons.auto_awesome_rounded, AppColors.lavender),
    ('Nutrition Coach', Icons.restaurant_rounded, AppColors.mint),
    ('Fitness Coach', Icons.fitness_center_rounded, AppColors.coral),
    ('Mental Wellness Coach', Icons.psychology_rounded, AppColors.sky),
    ('Goal Coach', Icons.flag_rounded, AppColors.amber),
    ('Habit Coach', Icons.eco_rounded, AppColors.aqua),
  ];

  final _api = FeatureService();
  final _message = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _recorder = AudioRecorder();

  final List<_ChatMessage> _messages = [];
  late String _coach;
  bool _sending = false;
  bool _listening = false;
  bool _transcribing = false;
  String? _voicePath;

  @override
  void initState() {
    super.initState();
    _coach = widget.coach;
  }

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    _focus.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    _message.clear();

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: 'user', content: text));
    });
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m.content.isNotEmpty)
          .map((m) => {'role': m.role, 'content': m.content, 'coach': _coach})
          .toList();
      final prior = history.length > 1
          ? history.sublist(0, history.length - 1)
          : <Map<String, String>>[];

      final data = await _api.post('ai/chat', {
        'message': text,
        'coach': _coach,
        'history': prior,
        'persist': false,
      });
      if (!mounted) return;
      final reply = Map<String, dynamic>.from(data['message'] as Map? ?? {});
      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            content: reply['content']?.toString() ?? 'I’m here with you.',
          ),
        );
        _sending = false;
      });
      _scrollToBottom();
      _focus.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            content: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      });
    }
  }

  Future<void> _toggleVoice() async {
    if (_transcribing || _sending) return;

    if (_listening) {
      await _stopAndTranscribe();
      return;
    }

    final permitted = await _recorder.hasPermission();
    if (!permitted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for voice chat.'),
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'harmonious_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    if (!mounted) return;
    setState(() {
      _listening = true;
      _voicePath = path;
    });
  }

  Future<void> _stopAndTranscribe() async {
    final path = await _recorder.stop() ?? _voicePath;
    if (!mounted) return;
    setState(() {
      _listening = false;
      _transcribing = true;
    });

    try {
      if (path == null || !File(path).existsSync()) {
        throw Exception('No audio recorded.');
      }
      final bytes = await File(path).readAsBytes();
      if (bytes.length < 800) {
        throw Exception('Clip too short — hold the mic and speak a bit longer.');
      }

      final data = await _api.post('ai/transcribe', {
        'audio_base64': base64Encode(bytes),
        'mime_type': 'audio/mp4',
        'file_name': 'voice.m4a',
      });
      if (!mounted) return;
      final text = data['text']?.toString().trim() ?? '';
      if (text.isEmpty) {
        throw Exception('Could not understand that. Try again.');
      }
      setState(() {
        _message.text = text;
        _message.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        _transcribing = false;
      });
      _focus.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() => _transcribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      final stale = path ?? _voicePath;
      if (stale != null) {
        try {
          final file = File(stale);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      _voicePath = null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _selectCoach(String coach) {
    if (coach == _coach) return;
    setState(() => _coach = coach);
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your companion'),
              Text(
                'Private · not saved to history',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _CoachStrip(
              coaches: _coaches,
              selected: _coach,
              onSelected: _selectCoach,
            ),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(coach: _coach)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_sending && index == _messages.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _TypingDots(),
                            ),
                          );
                        }
                        return _Bubble(message: _messages[index]);
                      },
                    ),
            ),
            _Composer(
              controller: _message,
              focusNode: _focus,
              listening: _listening,
              transcribing: _transcribing,
              sending: _sending,
              onMic: _toggleVoice,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachStrip extends StatelessWidget {
  const _CoachStrip({
    required this.coaches,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, IconData, Color)> coaches;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        itemCount: coaches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final coach = coaches[index];
          final active = coach.$1 == selected;
          final label = coach.$1.replaceAll(' Coach', '');
          return ChoiceChip(
            selected: active,
            onSelected: (_) => onSelected(coach.$1),
            avatar: Icon(
              coach.$2,
              size: 16,
              color: active ? AppColors.background : coach.$3,
            ),
            label: Text(label),
            selectedColor: coach.$3.withValues(alpha: 0.85),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: active ? coach.$3 : AppColors.surfaceBorder,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.background : AppColors.textPrimary,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.role, required this.content});
  final String role;
  final String content;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.coach});
  final String coach;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lavender.withValues(alpha: 0.16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.lavenderBright,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your $coach is ready',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Switch coaches above anytime. Ask about habits, food, workouts, mood, or goals — this session stays private.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.lavender.withValues(alpha: 0.22)
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.lavender.withValues(alpha: 0.35)
                : AppColors.surfaceBorder,
          ),
        ),
        child: Text(message.content, style: const TextStyle(height: 1.45)),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.listening,
    required this.transcribing,
    required this.sending,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool listening;
  final bool transcribing;
  final bool sending;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final busy = sending || transcribing;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: busy ? null : onMic,
              style: IconButton.styleFrom(
                backgroundColor: listening
                    ? AppColors.coral.withValues(alpha: 0.18)
                    : AppColors.background,
              ),
              icon: transcribing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color:
                          listening ? AppColors.coral : AppColors.lavenderBright,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                enabled: !transcribing,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: transcribing
                      ? 'Transcribing with AI…'
                      : listening
                          ? 'Recording… tap mic to stop'
                          : 'Message…',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: busy ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.lavender,
                foregroundColor: AppColors.background,
              ),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
