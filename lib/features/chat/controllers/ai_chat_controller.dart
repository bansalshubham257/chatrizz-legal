import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:chatrizz/domain/repositories/ai_repository.dart';
import 'package:chatrizz/services/ocr_service.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/services/api_service.dart';

class AiChatController extends ChangeNotifier {
  final AiRepository _aiRepository;
  final OcrService _ocrService;
  final LocalDataSource _localDataSource;
  final ApiService _apiService;

  File? _screenshot;
  String? _extractedText;
  String? _aiResult;
  bool _isProcessing = false;
  bool _isGenerating = false;
  bool _needsCredits = false;
  String? _error;
  String _conversationType = 'Stranger (Relationship)';
  String _responseStyle = 'Funny';
  List<String> _categories = ['Funny', 'Flirty', 'Bold'];
  VoidCallback? _apiListener;

  AiChatController({
    required AiRepository aiRepository,
    required OcrService ocrService,
    required LocalDataSource localDataSource,
    required ApiService apiService,
  })  : _aiRepository = aiRepository,
        _ocrService = ocrService,
        _localDataSource = localDataSource,
        _apiService = apiService {
    _apiListener = () => notifyListeners();
    _apiService.addListener(_apiListener!);
    _loadCategories();
  }

  void _loadCategories() {
    final user = _localDataSource.getUser();
    if (user != null && user.categories.isNotEmpty) {
      _categories = user.categories;
      if (!_categories.contains(_responseStyle)) {
        _responseStyle = _categories.first;
      }
    }
  }

  File? get screenshot => _screenshot;
  String? get extractedText => _extractedText;
  String? get aiResult => _aiResult;
  bool get isProcessing => _isProcessing;
  bool get isGenerating => _isGenerating;
  bool get needsCredits => _needsCredits;
  String? get error => _error;
  int get credits => _apiService.credits;
  String get conversationType => _conversationType;
  String get responseStyle => _responseStyle;
  List<String> get categories => List.unmodifiable(_categories);

  void setConversationType(String type) {
    _conversationType = type;
    notifyListeners();
  }

  void setResponseStyle(String style) {
    _responseStyle = style;
    notifyListeners();
  }

  Future<void> pickScreenshot() async {
    final file = await _ocrService.pickImage();
    if (file == null) return;

    await _processScreenshot(file);
  }

  Future<void> loadScreenshotFromPath(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    await _processScreenshot(file);
  }

  Future<void> _processScreenshot(File file) async {
    _screenshot = file;
    _extractedText = null;
    _aiResult = null;
    _error = null;
    _isProcessing = true;
    notifyListeners();

    try {
      final result = await _ocrService.extractText(_screenshot!);
      _extractedText = result.text;
    } catch (e) {
      _error = 'OCR failed: $e';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> generateIdeas() async {
    if (_extractedText == null || _extractedText!.isEmpty) return;

    if (_apiService.credits <= 0) {
      _needsCredits = true;
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _aiResult = null;
    _error = null;
    _needsCredits = false;
    notifyListeners();

    try {
      final user = _localDataSource.getUser();
      final language = user?.language ?? 'English';

      final result = await _aiRepository.generateScreenshotIdeas(
        AiCoachRequest(
          screenshotText: _extractedText!,
          conversationType: _conversationType,
          responseStyle: _responseStyle,
          userSide: 'right',
          language: language,
        ),
      );
      _aiResult = result;

      await _apiService.deductCredits(1);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clear() {
    _screenshot = null;
    _extractedText = null;
    _aiResult = null;
    _error = null;
    _needsCredits = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_apiListener != null) {
      _apiService.removeListener(_apiListener!);
    }
    super.dispose();
  }
}
