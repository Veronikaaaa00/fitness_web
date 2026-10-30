import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_token_store.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import '../repositories/auth_repository.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._prefs, this._api, this._tokens);

  static const _kToken = 'fitness_auth_token';
  static const _kUser = 'fitness_auth_user';

  /// Выход по неактивности.
  static const inactivityTimeout = Duration(minutes: 3);

  /// Предупреждение до выхода по неактивности.
  static const inactivityWarning = Duration(seconds: 30);

  final SharedPreferences _prefs;
  final AuthRepository _api;
  final AuthTokenStore _tokens;

  AppUser? _user;
  var _ready = false;

  AppUser? get user => _user;
  Role? get role => _user?.role;
  bool get isAuthenticated => _user != null && (_tokens.accessToken ?? '').isNotEmpty;
  bool get ready => _ready;

  Future<void> restore() async {
    final token = _prefs.getString(_kToken);
    if (token == null || token.isEmpty) {
      _ready = true;
      notifyListeners();
      return;
    }
    _tokens.setTokens(access: token);
    try {
      _user = await _api.me();
      await _persist();
    } catch (_) {
      await logout();
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final result = await _api.login(email: email, password: password);
    _user = result.user;
    await _persist();
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final result = await _api.register(
      email: email,
      password: password,
      fullName: fullName,
    );
    _user = result.user;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _api.clearLocal();
    await _prefs.remove(_kToken);
    await _prefs.remove(_kUser);
    notifyListeners();
  }

  Future<void> _persist() async {
    final token = _tokens.accessToken;
    if (token != null) await _prefs.setString(_kToken, token);
  }
}
