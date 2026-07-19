import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class OverlayService extends ChangeNotifier {
  static const _channel = MethodChannel('com.chatrizz/overlay');

  bool _isRunning = false;
  bool _permissionGranted = false;
  String? _lastScreenshotPath;

  bool get isRunning => _isRunning;
  bool get permissionGranted => _permissionGranted;
  String? get lastScreenshotPath => _lastScreenshotPath;

  void Function(int amount)? onCreditUsed;

  OverlayService() {
    _channel.setMethodCallHandler(_handleMethodCall);
    _checkPendingScreenshot();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScreenshotCaptured':
        _lastScreenshotPath = call.arguments as String?;
        notifyListeners();
      case 'onCreditUsed':
        onCreditUsed?.call(2);
        notifyListeners();
      case 'onOverlayDismissed':
        _isRunning = false;
        notifyListeners();
    }
  }

  Future<void> _checkPendingScreenshot() async {
    try {
      final path = await _channel.invokeMethod<String>('getPendingScreenshot');
      if (path != null && path.isNotEmpty) {
        _lastScreenshotPath = path;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> checkPermission() async {
    try {
      _permissionGranted = await _channel.invokeMethod('checkOverlayPermission') ?? false;
      notifyListeners();
      return _permissionGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  Future<bool> start() async {
    try {
      await deductPendingCredits();
      final granted = await checkPermission();
      if (!granted) return false;

      await _channel.invokeMethod('setCategories', {'categories': _categories});
      await _channel.invokeMethod('setGroqApiKey', {'apiKey': _groqApiKey});
      await _channel.invokeMethod('startOverlay');
      _isRunning = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isRunning = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setCategories(List<String> categories) async {
    _categories = categories;
    if (_isRunning) {
      try {
        await _channel.invokeMethod('setCategories', {'categories': categories});
      } catch (_) {}
    }
  }

  Future<void> deductPendingCredits() async {
    try {
      final total = await _channel.invokeMethod<int>('getPendingCreditDeductions') ?? 0;
      if (total > 0) {
        onCreditUsed?.call(total);
        await _channel.invokeMethod('clearPendingCreditDeductions');
        notifyListeners();
      }
    } catch (_) {}
  }

  String _groqApiKey = '';

  List<String> _categories = ['Funny', 'Flirty', 'Bold', 'General', 'Casual'];

  List<String> get categories => List.unmodifiable(_categories);

  void setGroqApiKey(String key) {
    _groqApiKey = key;
  }

  Future<void> clearPendingCredits() async {
    try {
      await _channel.invokeMethod('clearPendingCreditDeductions');
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await deductPendingCredits();
      await _channel.invokeMethod('stopOverlay');
    } catch (_) {}
    _isRunning = false;
    notifyListeners();
  }

  void clearScreenshot() {
    _lastScreenshotPath = null;
    notifyListeners();
  }
}
