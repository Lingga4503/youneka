import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;

import '../../../app/firebase/firebase_runtime_options.dart';
import 'mentor_access_service.dart';

enum MentorAiBackend { serverEnforced, geminiDeveloperApi }

class MentorAiAvailability {
  const MentorAiAvailability({
    required this.isReady,
    required this.statusLabel,
    this.notice,
    this.backend,
  });

  final bool isReady;
  final String statusLabel;
  final String? notice;
  final MentorAiBackend? backend;
}

class MentorAiClient {
  MentorAiClient._({required this.backend, this.geminiChat});

  static const String systemPrompt = '''
Kamu adalah Andrew, mentor anti-prokrastinasi untuk anak muda Indonesia.
Kepribadianmu: hangat, energik, to-the-point, kadang pakai humor ringan.
Kamu membantu user:
- Memecah tugas besar jadi langkah kecil yang bisa langsung dikerjakan
- Mengatasi rasa malas dan prokrastinasi dengan teknik seperti Pomodoro, time-blocking
- Memberikan motivasi yang spesifik dan realistis (bukan klise)
- Memonitor jadwal dan target belajar

Aturan respons:
- Jawab dalam Bahasa Indonesia yang casual dan ramah
- Respons singkat dan langsung (maksimal 4 kalimat)
- Kalau user galau/stuck, langsung kasih 1 langkah konkret yang bisa dilakukan sekarang
- Jangan panjang lebar kecuali diminta menjelaskan detail
- Panggil user dengan "kamu" bukan "Anda"
''';

  final MentorAiBackend backend;
  final gai.ChatSession? geminiChat;

  static MentorAiAvailability availability() {
    final accessState = MentorAccessService.instance.state.value;
    if (accessState.loading) {
      return const MentorAiAvailability(
        isReady: false,
        statusLabel: 'Menyiapkan AI...',
      );
    }

    if (!accessState.firebaseReady) {
      return MentorAiAvailability(
        isReady: false,
        statusLabel: 'Konfigurasi AI dibutuhkan',
        notice: accessState.notice,
      );
    }

    if (!accessState.isSignedIn) {
      return const MentorAiAvailability(
        isReady: false,
        statusLabel: 'Mulai dengan Google',
      );
    }

    if (accessState.quota != null) {
      return MentorAiAvailability(
        isReady: true,
        statusLabel: 'Online - Firebase AI',
        backend: MentorAiBackend.serverEnforced,
        notice: accessState.notice,
      );
    }

    if (kDebugMode && AppFirebaseRuntimeOptions.geminiApiKey.isNotEmpty) {
      return const MentorAiAvailability(
        isReady: true,
        statusLabel: 'Online - Gemini API (dev)',
        backend: MentorAiBackend.geminiDeveloperApi,
        notice: 'Mode dev aktif. Production tetap harus lewat Cloud Functions.',
      );
    }

    return MentorAiAvailability(
      isReady: false,
      statusLabel: 'Menunggu data akun AI',
      notice: accessState.notice,
    );
  }

  factory MentorAiClient.create() {
    final availability = MentorAiClient.availability();
    if (availability.backend == MentorAiBackend.serverEnforced) {
      return MentorAiClient._(backend: MentorAiBackend.serverEnforced);
    }

    if (availability.backend == MentorAiBackend.geminiDeveloperApi) {
      final model = gai.GenerativeModel(
        model: AppFirebaseRuntimeOptions.mentorAiModel,
        apiKey: AppFirebaseRuntimeOptions.geminiApiKey,
        systemInstruction: gai.Content.system(systemPrompt),
        generationConfig: gai.GenerationConfig(
          temperature: 0.82,
          maxOutputTokens: 320,
        ),
      );
      return MentorAiClient._(
        backend: MentorAiBackend.geminiDeveloperApi,
        geminiChat: model.startChat(),
      );
    }

    throw StateError('Mentor AI backend belum siap.');
  }

  Future<MentorUsageEnvelope> sendMessage({
    required String text,
    required List<Map<String, String>> history,
  }) async {
    switch (backend) {
      case MentorAiBackend.serverEnforced:
        return MentorAccessService.instance.sendMentorMessage(
          message: text,
          history: history,
        );
      case MentorAiBackend.geminiDeveloperApi:
        final response = await geminiChat!.sendMessage(gai.Content.text(text));
        final quota =
            MentorAccessService.instance.state.value.quota ??
            MentorQuotaStatus(
              plan: MentorPlan.free,
              premiumStatus: MentorPremiumStatus.inactive,
              limit: 10,
              used: 0,
              remaining: 10,
              resetAt: DateTime.now().add(const Duration(days: 1)),
            );
        return MentorUsageEnvelope(
          reply: response.text ?? 'Hmm, coba ulangi pertanyaan kamu ya.',
          quota: quota,
        );
    }
  }
}
