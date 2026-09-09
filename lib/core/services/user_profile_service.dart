import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileState {
  const UserProfileState({required this.loading, this.displayName, this.notice});

  const UserProfileState.initial()
    : loading = true,
      displayName = null,
      notice = null;

  final bool loading;
  final String? displayName;
  final String? notice;

  String get effectiveDisplayName {
    final candidate = (displayName ?? '').trim();
    if (candidate.isNotEmpty) return candidate;
    return 'Pengguna Youneka';
  }

  UserProfileState copyWith({
    bool? loading,
    String? displayName,
    String? notice,
    bool clearDisplayName = false,
    bool clearNotice = false,
  }) {
    return UserProfileState(
      loading: loading ?? this.loading,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  static const String _displayNameKey = 'youneka_display_name_v1';

  final ValueNotifier<UserProfileState> state = ValueNotifier(
    const UserProfileState.initial(),
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final displayName = prefs.getString(_displayNameKey);
    state.value = state.value.copyWith(
      loading: false,
      displayName: displayName,
    );
  }

  Future<bool> saveDisplayName(String input) async {
    final displayName = input.trim();
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, displayName);
    state.value = state.value.copyWith(
      displayName: displayName,
      clearNotice: true,
    );
    return true;
  }
}
