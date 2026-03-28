import 'package:flutter/material.dart';

import '../data/mentor_access_service.dart';
import '../data/mentor_ai_client.dart';

const Color _appWhite = Color(0xFFFAFDFF);
const Color _accentBlue = Color(0xFF4A72B8);
const Color _bubbleUser = Color(0xFFDCE8FF);
const Color _bubbleAndrew = Color(0xFFFFFFFF);
const Color _textMain = Color(0xFF0F172A);
const Color _textMuted = Color(0xFF64748B);
const Color _premiumGold = Color(0xFFFFD77B);

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
    this.isLoading = false,
  });

  final bool isAndrew;
  final String message;
  final String time;
  final bool isLoading;
}

class _MentorChatPopupDialogState extends State<MentorChatPopupDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MentorAccessService _access = MentorAccessService.instance;

  MentorAiClient? _client;
  bool _isTyping = false;

  final List<_MentorBubbleMessage> _messages = const [
    _MentorBubbleMessage(
      isAndrew: true,
      message:
          'Halo! Saya Andrew, mentor anti-prokrastinasi kamu.\n\nCeritain yuk, tugas apa yang lagi kamu tunda hari ini?',
      time: '',
    ),
  ].toList();

  @override
  void initState() {
    super.initState();
    _access.state.addListener(_syncClient);
    _syncClient();
  }

  @override
  void dispose() {
    _access.state.removeListener(_syncClient);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncClient() {
    final availability = MentorAiClient.availability();
    if (!mounted) return;
    setState(() {
      if (availability.isReady) {
        _client ??= MentorAiClient.create();
      } else {
        _client = null;
      }
    });
  }

  String _nowTime() {
    final t = TimeOfDay.now();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  List<Map<String, String>> _buildHistoryPayload() {
    final compactMessages = _messages
        .where((message) => !message.isLoading && message.time.isNotEmpty)
        .skip((_messages.length - 8).clamp(0, _messages.length))
        .map(
          (message) => <String, String>{
            'role': message.isAndrew ? 'model' : 'user',
            'text': message.message,
          },
        )
        .toList();
    return compactMessages;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final accessState = _access.state.value;
    if (text.isEmpty || _isTyping || _client == null || !accessState.canChat) {
      return;
    }

    final userTime = _nowTime();
    setState(() {
      _messages.add(
        _MentorBubbleMessage(isAndrew: false, message: text, time: userTime),
      );
      _messages.add(
        const _MentorBubbleMessage(
          isAndrew: true,
          message: '',
          time: '',
          isLoading: true,
        ),
      );
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final reply = await _client!.sendMessage(
        text: text,
        history: _buildHistoryPayload(),
      );
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _MentorBubbleMessage(
            isAndrew: true,
            message: reply.reply,
            time: _nowTime(),
          ),
        );
        _isTyping = false;
      });
      await _access.refresh();
    } catch (error, stackTrace) {
      debugPrint('Mentor send failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          _MentorBubbleMessage(
            isAndrew: true,
            message:
                _access.state.value.notice ??
                'Waduh, mentor lagi gangguan. Coba lagi sebentar ya.',
            time: _nowTime(),
          ),
        );
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.clamp(320.0, 430.0);
    final height = size.height * 0.76;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ValueListenableBuilder<MentorAccessState>(
      valueListenable: _access.state,
      builder: (context, accessState, _) {
        final availability = MentorAiClient.availability();
        final canSend = _client != null && !_isTyping && accessState.canChat;
        final showOnboardingGate =
            accessState.firebaseReady && !accessState.isSignedIn;

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 90 + bottomInset,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x330B1220),
                        blurRadius: 32,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        _MentorHeader(
                          title: 'Mentor Andrew',
                          subtitle: _headerSubtitle(accessState, availability),
                        ),
                        if (showOnboardingGate)
                          Expanded(
                            child: _MentorOnboardingGate(
                              loading: accessState.loading,
                              onLoginTap: accessState.loading
                                  ? null
                                  : _access.signInWithGoogle,
                            ),
                          )
                        else ...[
                          if (accessState.notice != null ||
                              availability.notice != null)
                            _MentorNoticeBanner(
                              message:
                                  accessState.notice ?? availability.notice!,
                              emphasizeWarning: true,
                            ),
                          if (accessState.quota?.remaining == 0)
                            _MentorActionPanel(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Kuota AI habis',
                              subtitle:
                                  'Reset ${_formatResetAt(accessState.quota!.resetAt)} WIB atau upgrade premium untuk 500 chat per bulan.',
                              primaryLabel:
                                  accessState.premiumProduct?.price == null
                                  ? 'Upgrade Premium'
                                  : 'Upgrade ${accessState.premiumProduct!.price}',
                              onPrimaryTap: accessState.canPurchase
                                  ? () async {
                                      await _access.purchasePremium();
                                    }
                                  : null,
                              secondaryLabel: 'Restore',
                              onSecondaryTap: _access.restorePurchases,
                            )
                          else
                            _QuotaStrip(quota: accessState.quota),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) {
                                final msg = _messages[i];
                                if (msg.isLoading) {
                                  return const _TypingIndicator();
                                }
                                return _MessageBubble(
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
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    enabled: canSend,
                                    minLines: 1,
                                    maxLines: 3,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: canSend
                                        ? (_) => _sendMessage()
                                        : null,
                                    decoration: InputDecoration(
                                      hintText: _inputHint(accessState),
                                      hintStyle: TextStyle(
                                        color: !canSend
                                            ? _textMuted
                                            : _isTyping
                                            ? _accentBlue
                                            : _textMuted,
                                        fontSize: 13,
                                      ),
                                      filled: true,
                                      fillColor: _appWhite,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD5DDEF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: FilledButton(
                                      onPressed: canSend ? _sendMessage : null,
                                      style: FilledButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: canSend
                                            ? _accentBlue
                                            : const Color(0xFFB0BDD4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.send_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _headerSubtitle(
    MentorAccessState accessState,
    MentorAiAvailability availability,
  ) {
    if (!accessState.isSignedIn) return 'Mulai dengan Google';
    final quota = accessState.quota;
    if (quota == null) return availability.statusLabel;
    final window = quota.isPremium ? 'bulan ini' : 'hari ini';
    return '${quota.planLabel} - ${quota.remaining} chat tersisa $window';
  }

  String _inputHint(MentorAccessState state) {
    if (!state.isSignedIn) {
      return 'Login Google untuk mulai chat';
    }
    if (state.quota?.remaining == 0) {
      return 'Kuota AI habis untuk periode ini';
    }
    if (_isTyping) {
      return 'Andrew sedang mengetik...';
    }
    if (_client == null) {
      return 'AI sedang disiapkan...';
    }
    return 'Tulis pesan untuk Andrew...';
  }

  String _formatResetAt(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _MentorOnboardingGate extends StatelessWidget {
  const _MentorOnboardingGate({
    required this.loading,
    required this.onLoginTap,
  });

  final bool loading;
  final Future<void> Function()? onLoginTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12111827),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masuk untuk mulai dengan Andrew',
                style: TextStyle(
                  color: _textMain,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Andrew akan menyimpan riwayatmu, menghitung 10 chat gratis per hari, dan menyiapkan premium kalau nanti kamu butuh.',
                style: TextStyle(color: _textMuted, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 18),
              const _OnboardingBullet(
                icon: Icons.auto_awesome_rounded,
                title: '10 chat gratis per hari',
                subtitle:
                    'Cukup untuk mulai ngobrol, pecah tugas, dan cari arah.',
              ),
              const SizedBox(height: 10),
              const _OnboardingBullet(
                icon: Icons.history_rounded,
                title: 'Riwayat tetap tersimpan',
                subtitle: 'Andrew bisa lanjut dari percakapanmu sebelumnya.',
              ),
              const SizedBox(height: 10),
              const _OnboardingBullet(
                icon: Icons.workspace_premium_rounded,
                title: 'Siap untuk premium nanti',
                subtitle:
                    'Kalau kuota habis, kamu bisa upgrade tanpa pindah akun.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onLoginTap == null
                      ? null
                      : () => onLoginTap!.call(),
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    loading ? 'Menghubungkan akun...' : 'Lanjut dengan Google',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Nanti saja'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FD),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preview Andrew',
                style: TextStyle(
                  color: _accentBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '"Kalau tugasmu terasa besar, kita pecah jadi langkah 10 menit dulu. Yang penting mulai, bukan sempurna."',
                style: TextStyle(color: _textMain, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingBullet extends StatelessWidget {
  const _OnboardingBullet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _accentBlue.withAlpha(24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _accentBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MentorHeader extends StatelessWidget {
  const _MentorHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A5FA8), Color(0xFF5B84CC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _appWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFDCE8FF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: _appWhite),
          ),
        ],
      ),
    );
  }
}

class _MentorNoticeBanner extends StatelessWidget {
  const _MentorNoticeBanner({
    required this.message,
    required this.emphasizeWarning,
  });

  final String message;
  final bool emphasizeWarning;

  @override
  Widget build(BuildContext context) {
    final background = emphasizeWarning
        ? const Color(0xFFFFF4DB)
        : const Color(0xFFEAF2FD);
    final border = emphasizeWarning
        ? const Color(0xFFF6C66B)
        : const Color(0xFFC8D9F7);
    final textColor = emphasizeWarning
        ? const Color(0xFF7C4A03)
        : const Color(0xFF274976);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        style: TextStyle(color: textColor, fontSize: 12, height: 1.4),
      ),
    );
  }
}

class _MentorActionPanel extends StatelessWidget {
  const _MentorActionPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final Future<void> Function()? onPrimaryTap;
  final String? secondaryLabel;
  final Future<void> Function()? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _premiumGold.withAlpha(80),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _accentBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textMain,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _textMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onPrimaryTap == null
                    ? null
                    : () => onPrimaryTap!.call(),
                child: Text(primaryLabel),
              ),
              if (secondaryLabel != null)
                TextButton(
                  onPressed: onSecondaryTap == null
                      ? null
                      : () => onSecondaryTap!.call(),
                  child: Text(secondaryLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotaStrip extends StatelessWidget {
  const _QuotaStrip({required this.quota});

  final MentorQuotaStatus? quota;

  @override
  Widget build(BuildContext context) {
    if (quota == null) return const SizedBox.shrink();
    final progress = quota!.limit == 0 ? 0.0 : quota!.used / quota!.limit;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                quota!.isPremium ? 'Premium Plan' : 'Free Plan',
                style: const TextStyle(
                  color: _textMain,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${quota!.remaining} chat',
                style: const TextStyle(
                  color: _accentBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFD5E1F3),
              valueColor: const AlwaysStoppedAnimation<Color>(_accentBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isAndrew,
    required this.message,
    required this.time,
  });

  final bool isAndrew;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAndrew ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: isAndrew ? _bubbleAndrew : _bubbleUser,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isAndrew ? 4 : 18),
            bottomRight: Radius.circular(isAndrew ? 18 : 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12111827),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: _textMain,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                time,
                style: const TextStyle(color: _textMuted, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _bubbleAndrew,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12111827),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final offset = i / 3.0;
              final value = ((_animation.value - offset).abs() < 0.5)
                  ? _animation.value
                  : 0.3;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _accentBlue.withAlpha(
                    (value * 255).round().clamp(60, 255),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
