import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../app/firebase/firebase_bootstrap.dart';

enum MentorPlan { free, premium }

enum MentorPremiumStatus { inactive, active, grace, expired }

class MentorQuotaStatus {
  const MentorQuotaStatus({
    required this.plan,
    required this.premiumStatus,
    required this.limit,
    required this.used,
    required this.remaining,
    required this.resetAt,
    this.premiumUntil,
  });

  final MentorPlan plan;
  final MentorPremiumStatus premiumStatus;
  final int limit;
  final int used;
  final int remaining;
  final DateTime resetAt;
  final DateTime? premiumUntil;

  bool get isPremium => plan == MentorPlan.premium;
  String get planLabel => isPremium ? 'Premium' : 'Free';
}

class MentorAccessState {
  const MentorAccessState({
    required this.loading,
    required this.firebaseReady,
    required this.canPurchase,
    this.displayName,
    this.user,
    this.quota,
    this.notice,
    this.premiumProduct,
    this.purchasePending = false,
  });

  const MentorAccessState.initial()
    : loading = true,
      firebaseReady = false,
      canPurchase = false,
      displayName = null,
      user = null,
      quota = null,
      notice = null,
      premiumProduct = null,
      purchasePending = false;

  final bool loading;
  final bool firebaseReady;
  final bool canPurchase;
  final String? displayName;
  final User? user;
  final MentorQuotaStatus? quota;
  final String? notice;
  final ProductDetails? premiumProduct;
  final bool purchasePending;

  bool get isSignedIn => user != null;
  bool get canChat =>
      firebaseReady &&
      isSignedIn &&
      quota != null &&
      quota!.remaining > 0 &&
      !purchasePending;

  String get effectiveDisplayName {
    final candidate = (displayName ?? user?.displayName ?? '').trim();
    if (candidate.isNotEmpty) return candidate;
    return 'Pengguna Youneka';
  }

  MentorAccessState copyWith({
    bool? loading,
    bool? firebaseReady,
    bool? canPurchase,
    String? displayName,
    User? user,
    MentorQuotaStatus? quota,
    String? notice,
    ProductDetails? premiumProduct,
    bool clearDisplayName = false,
    bool clearUser = false,
    bool clearQuota = false,
    bool clearNotice = false,
    bool clearPremiumProduct = false,
    bool? purchasePending,
  }) {
    return MentorAccessState(
      loading: loading ?? this.loading,
      firebaseReady: firebaseReady ?? this.firebaseReady,
      canPurchase: canPurchase ?? this.canPurchase,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      user: clearUser ? null : (user ?? this.user),
      quota: clearQuota ? null : (quota ?? this.quota),
      notice: clearNotice ? null : (notice ?? this.notice),
      premiumProduct: clearPremiumProduct
          ? null
          : (premiumProduct ?? this.premiumProduct),
      purchasePending: purchasePending ?? this.purchasePending,
    );
  }
}

class MentorUsageEnvelope {
  const MentorUsageEnvelope({required this.reply, required this.quota});

  final String reply;
  final MentorQuotaStatus quota;
}

class MentorServerException implements Exception {
  const MentorServerException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;
}

class MentorAccessService {
  MentorAccessService._();

  static final MentorAccessService instance = MentorAccessService._();

  static const String premiumProductId = 'youneka_ai_premium_monthly';
  static const Duration _mentorRequestTimeout = Duration(seconds: 20);

  final ValueNotifier<MentorAccessState> state = ValueNotifier(
    const MentorAccessState.initial(),
  );

  final InAppPurchase _iap = InAppPurchase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static const String _functionRegion = 'asia-southeast2';

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _initialized = false;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!AppFirebaseBootstrap.isInitialized) {
      state.value = state.value.copyWith(
        loading: false,
        firebaseReady: false,
        notice:
            AppFirebaseBootstrap.statusMessage ??
            'Firebase belum siap untuk AI account.',
      );
      return;
    }

    await _loadBillingCatalog();
    _purchaseSub = _iap.purchaseStream.listen(_handlePurchaseUpdates);
    _authSub = _auth.authStateChanges().listen(_handleAuthChanged);

    await _handleAuthChanged(_auth.currentUser);
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _purchaseSub?.cancel();
    _initialized = false;
  }

  Future<void> signInWithGoogle() async {
    if (!AppFirebaseBootstrap.isInitialized) return;
    state.value = state.value.copyWith(
      loading: true,
      clearNotice: true,
      purchasePending: false,
    );

    try {
      await _googleSignIn.initialize();
      final googleUser = await _googleSignIn.authenticate();
      final auth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      await _auth.signInWithCredential(credential);
    } catch (error) {
      state.value = state.value.copyWith(
        loading: false,
        notice: 'Login Google gagal. Periksa SHA Firebase Auth dan coba lagi.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<bool> saveDisplayName(String input) async {
    final user = _auth.currentUser;
    final displayName = input.trim();
    if (user == null) {
      state.value = state.value.copyWith(
        notice: 'Login Google dulu sebelum mengubah nama.',
      );
      return false;
    }
    if (displayName.isEmpty) {
      state.value = state.value.copyWith(
        notice: 'Nama pengguna tidak boleh kosong.',
      );
      return false;
    }
    if (displayName.length > 40) {
      state.value = state.value.copyWith(
        notice: 'Nama pengguna maksimal 40 karakter.',
      );
      return false;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
      }, SetOptions(merge: true));
      await user.updateDisplayName(displayName);
      state.value = state.value.copyWith(
        user: _auth.currentUser,
        displayName: displayName,
        clearNotice: true,
      );
      return true;
    } catch (_) {
      state.value = state.value.copyWith(
        notice: 'Nama pengguna gagal disimpan. Coba lagi.',
      );
      return false;
    }
  }

  Future<void> refresh() async {
    await _handleAuthChanged(_auth.currentUser);
  }

  Future<bool> purchasePremium() async {
    final product = state.value.premiumProduct;
    if (product == null) {
      state.value = state.value.copyWith(
        notice: 'Paket premium belum tersedia di Play Console.',
      );
      return false;
    }

    final user = _auth.currentUser;
    if (user == null) {
      state.value = state.value.copyWith(
        notice: 'Login Google dulu sebelum membeli premium.',
      );
      return false;
    }

    state.value = state.value.copyWith(
      purchasePending: true,
      clearNotice: true,
    );
    final param = PurchaseParam(productDetails: product);
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      state.value = state.value.copyWith(
        purchasePending: false,
        notice: 'Pembelian premium tidak dapat dimulai.',
      );
    }
    return started;
  }

  Future<void> restorePurchases() async {
    state.value = state.value.copyWith(
      purchasePending: true,
      clearNotice: true,
    );
    await _iap.restorePurchases();
  }

  Future<void> _loadBillingCatalog() async {
    final canPurchase =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        await _iap.isAvailable();

    if (!canPurchase) {
      state.value = state.value.copyWith(
        loading: false,
        firebaseReady: AppFirebaseBootstrap.isInitialized,
        canPurchase: false,
      );
      return;
    }

    final products = await _iap.queryProductDetails({premiumProductId});
    ProductDetails? premiumProduct;
    if (products.productDetails.isNotEmpty) {
      premiumProduct = products.productDetails.first;
    }

    state.value = state.value.copyWith(
      canPurchase: true,
      premiumProduct: premiumProduct,
    );
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (!AppFirebaseBootstrap.isInitialized) return;

    if (user == null) {
      state.value = state.value.copyWith(
        loading: false,
        firebaseReady: true,
        clearDisplayName: true,
        clearUser: true,
        clearQuota: true,
        clearNotice: true,
        purchasePending: false,
      );
      return;
    }

    state.value = state.value.copyWith(
      loading: true,
      firebaseReady: true,
      user: user,
      clearNotice: true,
    );

    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final profileData = profile.data() ?? <String, dynamic>{};
      final displayName = _parseDisplayName(profileData['displayName'], user);
      final plan = _parsePlan(profileData['plan'] as String?);
      final premiumStatus = _parsePremiumStatus(
        profileData['premiumStatus'] as String?,
      );
      final premiumUntil = _timestampToDate(profileData['premiumUntil']);

      final now = DateTime.now().toUtc();
      final jakarta = now.add(const Duration(hours: 7));
      final dailyId = _formatDateId(jakarta);
      final monthlyId = _formatMonthId(jakarta);

      final usageCollection = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('usage');
      final dailyDoc = await usageCollection.doc('daily_$dailyId').get();
      final monthlyDoc = await usageCollection.doc('monthly_$monthlyId').get();

      final limit = plan == MentorPlan.premium ? 500 : 10;
      final used = plan == MentorPlan.premium
          ? (monthlyDoc.data()?['chatCount'] as num?)?.toInt() ?? 0
          : (dailyDoc.data()?['chatCount'] as num?)?.toInt() ?? 0;
      final remaining = (limit - used).clamp(0, limit);
      final resetAt = plan == MentorPlan.premium
          ? DateTime(jakarta.year, jakarta.month + 1, 1)
          : DateTime(jakarta.year, jakarta.month, jakarta.day + 1);

      state.value = state.value.copyWith(
        loading: false,
        firebaseReady: true,
        user: user,
        displayName: displayName,
        quota: MentorQuotaStatus(
          plan: plan,
          premiumStatus: premiumStatus,
          limit: limit,
          used: used,
          remaining: remaining,
          resetAt: resetAt,
          premiumUntil: premiumUntil,
        ),
        notice: remaining == 0
            ? 'Kuota AI habis. Reset ${_formatResetAt(resetAt)} atau upgrade premium.'
            : null,
        purchasePending: false,
      );
    } catch (_) {
      state.value = state.value.copyWith(
        loading: false,
        firebaseReady: true,
        user: user,
        displayName: _parseDisplayName(null, user),
        clearQuota: true,
        notice: 'Gagal memuat status akun AI. Periksa Firestore dan Functions.',
        purchasePending: false,
      );
    }
  }

  Future<MentorUsageEnvelope> sendMentorMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Login Google wajib sebelum mengirim pesan.');
    }

    try {
      final data = await _postFunction('mentorChatSend', <String, dynamic>{
        'message': message,
        'history': history,
      });
      final quotaMap = Map<String, dynamic>.from(data['quota'] as Map);
      final quota = MentorQuotaStatus(
        plan: _parsePlan(quotaMap['plan'] as String?),
        premiumStatus: _parsePremiumStatus(
          quotaMap['premiumStatus'] as String?,
        ),
        limit: (quotaMap['limit'] as num?)?.toInt() ?? 10,
        used: (quotaMap['used'] as num?)?.toInt() ?? 0,
        remaining: (quotaMap['remaining'] as num?)?.toInt() ?? 0,
        resetAt: DateTime.parse(quotaMap['resetAt'] as String).toLocal(),
        premiumUntil: quotaMap['premiumUntil'] == null
            ? null
            : DateTime.tryParse(quotaMap['premiumUntil'] as String)?.toLocal(),
      );

      state.value = state.value.copyWith(
        quota: quota,
        clearNotice: quota.remaining > 0,
        notice: quota.remaining == 0
            ? 'Kuota AI habis. Reset ${_formatResetAt(quota.resetAt)} atau upgrade premium.'
            : null,
      );

      return MentorUsageEnvelope(
        reply:
            data['reply'] as String? ?? 'Andrew lagi bingung. Coba ulangi ya.',
        quota: quota,
      );
    } on MentorServerException catch (error) {
      _applyServerErrorNotice(error);
      rethrow;
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != premiumProductId) continue;

      try {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          final functionName = purchase.status == PurchaseStatus.restored
              ? 'restorePremiumSubscription'
              : 'activatePremiumSubscription';
          await _postFunction(functionName, <String, dynamic>{
            'productId': purchase.productID,
            'purchaseToken': purchase.verificationData.serverVerificationData,
          });
          await refresh();
        } else if (purchase.status == PurchaseStatus.error) {
          state.value = state.value.copyWith(
            notice: purchase.error?.message ?? 'Pembayaran premium gagal.',
            purchasePending: false,
          );
        }
      } on MentorServerException catch (error) {
        state.value = state.value.copyWith(
          notice: error.message,
          purchasePending: false,
        );
      } finally {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }

    state.value = state.value.copyWith(purchasePending: false);
  }

  MentorPlan _parsePlan(String? raw) {
    switch (raw) {
      case 'premium':
        return MentorPlan.premium;
      case 'free':
      default:
        return MentorPlan.free;
    }
  }

  MentorPremiumStatus _parsePremiumStatus(String? raw) {
    switch (raw) {
      case 'active':
        return MentorPremiumStatus.active;
      case 'grace':
        return MentorPremiumStatus.grace;
      case 'expired':
        return MentorPremiumStatus.expired;
      case 'inactive':
      default:
        return MentorPremiumStatus.inactive;
    }
  }

  DateTime? _timestampToDate(Object? value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  String _parseDisplayName(Object? raw, User? user) {
    final firestoreName = (raw as String? ?? '').trim();
    if (firestoreName.isNotEmpty) return firestoreName;
    final authName = (user?.displayName ?? '').trim();
    if (authName.isNotEmpty) return authName;
    return 'Pengguna Youneka';
  }

  String _formatDateId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}$month$day';
  }

  String _formatMonthId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}$month';
  }

  String _formatResetAt(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute WIB';
  }

  Future<Map<String, dynamic>> _postFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const MentorServerException(
        statusCode: 401,
        code: 'unauthenticated',
        message: 'Login Google wajib.',
      );
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const MentorServerException(
        statusCode: 401,
        code: 'session-invalid',
        message: 'Sesi login sudah tidak valid. Silakan login ulang.',
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    try {
      final appCheckToken = await FirebaseAppCheck.instance.getToken();
      if (appCheckToken != null && appCheckToken.isNotEmpty) {
        headers['X-Firebase-AppCheck'] = appCheckToken;
      }
    } catch (_) {
      // App Check remains unenforced in this phase. Missing token is acceptable.
    }

    http.Response response;
    try {
      response = await http
          .post(
            _functionUri(functionName),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_mentorRequestTimeout);
    } on TimeoutException {
      throw const MentorServerException(
        statusCode: 504,
        code: 'timeout',
        message: 'Server mentor terlalu lama merespons.',
      );
    } on http.ClientException {
      throw const MentorServerException(
        statusCode: 503,
        code: 'network-error',
        message: 'Koneksi ke server mentor gagal.',
      );
    }

    final decoded = _decodeJsonBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    }

    final errorMap =
        decoded is Map<String, dynamic> &&
            decoded['error'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(decoded['error'] as Map<String, dynamic>)
        : <String, dynamic>{};

    throw MentorServerException(
      statusCode: response.statusCode,
      code: (errorMap['code'] as String?) ?? 'server-error',
      message:
          (errorMap['message'] as String?) ??
          'Server mentor belum bisa memproses permintaan.',
      details: errorMap['details'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              errorMap['details'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Uri _functionUri(String functionName) {
    final projectId = AppFirebaseBootstrap.app?.options.projectId ?? '';
    if (projectId.isEmpty) {
      throw const MentorServerException(
        statusCode: 500,
        code: 'firebase-misconfigured',
        message: 'Project Firebase belum terbaca di app ini.',
      );
    }

    return Uri.parse(
      'https://$_functionRegion-$projectId.cloudfunctions.net/$functionName',
    );
  }

  Object? _decodeJsonBody(String rawBody) {
    if (rawBody.trim().isEmpty) return null;
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return null;
    }
  }

  void _applyServerErrorNotice(MentorServerException error) {
    if (error.code == 'resource-exhausted' && error.details != null) {
      final detailMap = error.details!;
      final quota = MentorQuotaStatus(
        plan: _parsePlan(detailMap['plan'] as String?),
        premiumStatus: _parsePremiumStatus(
          detailMap['premiumStatus'] as String?,
        ),
        limit: (detailMap['limit'] as num?)?.toInt() ?? 10,
        used: (detailMap['used'] as num?)?.toInt() ?? 10,
        remaining: (detailMap['remaining'] as num?)?.toInt() ?? 0,
        resetAt: DateTime.parse(detailMap['resetAt'] as String).toLocal(),
        premiumUntil: detailMap['premiumUntil'] == null
            ? null
            : DateTime.tryParse(detailMap['premiumUntil'] as String)?.toLocal(),
      );
      state.value = state.value.copyWith(
        quota: quota,
        notice:
            'Kuota AI habis. Reset ${_formatResetAt(quota.resetAt)} atau upgrade premium.',
      );
      return;
    }

    if (error.statusCode == 401) {
      state.value = state.value.copyWith(
        notice: 'Sesi login berakhir. Masuk lagi untuk lanjut chat.',
        purchasePending: false,
      );
      return;
    }

    if (error.statusCode == 412) {
      state.value = state.value.copyWith(
        notice: error.message,
        purchasePending: false,
      );
      return;
    }

    if (error.code == 'network-error' || error.code == 'timeout') {
      state.value = state.value.copyWith(
        notice: error.message,
        purchasePending: false,
      );
      return;
    }

    state.value = state.value.copyWith(
      notice: 'Mentor lagi gangguan sebentar. Coba lagi ya.',
      purchasePending: false,
    );
  }
}
