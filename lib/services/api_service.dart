import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class ApiService extends ChangeNotifier {
  static const _baseUrl = 'https://chatrizz-production.up.railway.app';
  static const _tokenKey = 'auth_token';

  String? _token;
  int _credits = 0;
  bool _loading = false;

  String? get token => _token;
  int get credits => _credits;
  bool get loading => _loading;
  bool get isSignedIn => _token != null;

  ApiService({String? initialToken}) {
    _token = initialToken;
    if (_token != null) {
      refreshCredits();
    }
    notifyListeners();
  }

  Future<void> _saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    notifyListeners();
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '1025432805110-d1f2gcrn3p9ic3qmfnatfskcf81dts4f.apps.googleusercontent.com',
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _loading = false;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        _loading = false;
        notifyListeners();
        return false;
      }

      final res = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      if (res.statusCode != 200) {
        _loading = false;
        notifyListeners();
        return false;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _token = data['token'] as String;
      _credits = data['user']['credits'] as int;
      await _saveToken(_token);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<int?> refreshCredits() async {
    if (_token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/credits'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _credits = data['credits'] as int;
        notifyListeners();
        return _credits;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deductCredits(int amount) async {
    if (_token == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/credits/deduct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'amount': amount}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _credits = data['credits'] as int;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addCredits(int amount) async {
    if (_token == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/credits/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'amount': amount}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _credits = data['credits'] as int;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (_token == null) return false;
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/user'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        await signOut();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    _token = null;
    _credits = 0;
    await _saveToken(null);
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    notifyListeners();
  }
}
