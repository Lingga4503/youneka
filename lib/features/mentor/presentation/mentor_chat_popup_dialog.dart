import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MentorChatPopupDialog extends StatefulWidget {
  const MentorChatPopupDialog({super.key});

  @override
  State<MentorChatPopupDialog> createState() => _MentorChatPopupDialogState();
}

class _MentorBubbleMessage {
  const _MentorBubbleMessage({
    required this.isAndrew,
    required this.message,
    required this.time,
  });

  final bool isAndrew;
  final String message;
  final String time;
}

class _MentorChatPopupDialogState extends State<MentorChatPopupDialog> {
  static const String _modelKey = 'qwen_model_downloaded';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _downloadTimer;

  bool _modelDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  final List<_MentorBubbleMessage> _messages = <_MentorBubbleMessage>[
    const _MentorBubbleMessage(
      isAndrew: true,
      message: 'Halo lingga! Ceritakan tugas yang lagi kamu tunda.',
      time: '00:49',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadModelStatus();
  }

  @override
  void dispose() {
    _downloadTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadModelStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getBool(_modelKey) ?? false;
    if (!mounted) return;
    setState(() {
      _modelDownloaded = downloaded;
    });
  }

  Future<void> _startDownload() async {
    if (_isDownloading || _modelDownloaded) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });
    _downloadTimer?.cancel();
    _downloadTimer =
        Timer.periodic(const Duration(milliseconds: 220), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = (_downloadProgress + 0.07).clamp(0.0, 1.0);
      setState(() => _downloadProgress = next);
      if (next >= 1) {
        timer.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_modelKey, true);
        if (!mounted) return;
        setState(() {
          _modelDownloaded = true;
          _isDownloading = false;
        });
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_modelDownloaded) return;
    final time = TimeOfDay.now().format(context);
    setState(() {
      _messages.add(
        _MentorBubbleMessage(isAndrew: false, message: text, time: time),
      );
      _messages.add(
        _MentorBubbleMessage(
          isAndrew: true,
          message: 'Oke, kita pecah jadi 1 langkah kecil dulu: mulai 10 menit sekarang.',
          time: time,
        ),
      );
      _messageController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 160,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.clamp(320.0, 430.0);
    final height = size.height * 0.72;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 18, bottom: 18, left: 18),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330B1220),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 68,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A72B8),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mentor Andrew',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFFDCE8FF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                                itemCount: _messages.length,
                                itemBuilder: (_, i) {
                                  final msg = _messages[i];
                                  return _MentorCoachMessage(
                                    isAndrew: msg.isAndrew,
                                    message: msg.message,
                                    time: msg.time,
                                  );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3F6FB),
                                borderRadius:
                                    BorderRadius.vertical(bottom: Radius.circular(20)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      enabled: _modelDownloaded,
                                      minLines: 1,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: 'Tulis pesan untuk Andrew...',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF9DB3D8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: FilledButton(
                                      onPressed: _modelDownloaded ? _sendMessage : null,
                                      style: FilledButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: const Color(0xFF4A72B8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Icon(Icons.send_rounded, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_modelDownloaded) ...[
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(20),
                              ),
                              child: BackdropFilter(
                                filter:
                                    ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
                                child: Container(
                                  color: const Color(0x99E8EEF8),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: width * 0.8,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFD5E1F1)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A0B1220),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_download_rounded,
                                    color: Color(0xFF4A72B8),
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Unduh model Qwen (~0.3 GB) dulu agar mentor bisa membalas offline.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_isDownloading) ...[
                                    LinearProgressIndicator(
                                      value: _downloadProgress,
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(999),
                                      backgroundColor: const Color(0xFFDCE6F5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mengunduh ${(100 * _downloadProgress).round()}%',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ] else
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: _startDownload,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF4A72B8),
                                        ),
                                        child: const Text('Unduh sekarang'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MentorCoachMessage extends StatelessWidget {
  const _MentorCoachMessage({
    required this.isAndrew,
    required this.message,
    required this.time,
  });

  final bool isAndrew;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    final alignment = isAndrew ? Alignment.centerLeft : Alignment.centerRight;
    final background = isAndrew ? Colors.white : const Color(0xFFDCE8FF);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isAndrew ? 4 : 18),
      bottomRight: Radius.circular(isAndrew ? 18 : 4),
    );
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14111827),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

