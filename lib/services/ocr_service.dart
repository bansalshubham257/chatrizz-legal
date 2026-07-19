import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:chatrizz/core/utils/logger.dart';

class OcrService {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer();

  Future<File?> pickImage() async {
    try {
      final xFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return null;
      return File(xFile.path);
    } catch (e) {
      Logger.e('Error picking image', error: e);
      return null;
    }
  }

  Future<OcrResult> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognisedText = await _recognizer.processImage(inputImage);
      return _parseConversation(recognisedText);
    } catch (e) {
      Logger.e('OCR error', error: e);
      return OcrResult(text: '', messages: []);
    }
  }

  Future<ProfileData> extractProfileData(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognisedText = await _recognizer.processImage(inputImage);
      return _parseProfile(recognisedText);
    } catch (e) {
      Logger.e('Profile OCR error', error: e);
      return ProfileData(name: '', age: null, bio: '', interests: []);
    }
  }

  OcrResult _parseConversation(RecognizedText recognisedText) {
    final rawText = recognisedText.text;
    Logger.i('OCR raw: $rawText');
    
    if (recognisedText.blocks.isEmpty) {
      return OcrResult(text: rawText, messages: []);
    }

    double maxWidth = 0;
    for (final block in recognisedText.blocks) {
      if (block.boundingBox.right > maxWidth) {
        maxWidth = block.boundingBox.right.toDouble();
      }
    }

    final messages = <ParsedMessage>[];
    
    for (final block in recognisedText.blocks) {
      final text = block.text.trim();
      if (text.isEmpty || _isTimestamp(text)) continue;

      final sender = block.boundingBox.center.dx > (maxWidth / 2) ? 'me' : 'them';
      
      if (messages.isNotEmpty) {
        final lastMsg = messages.last;
        if (lastMsg.sender == sender) {
          final updatedMessages = List<ParsedMessage>.from(messages);
          updatedMessages[updatedMessages.length - 1] = ParsedMessage(
            sender: sender, 
            text: '${lastMsg.text}\n$text'
          );
          messages.clear();
          messages.addAll(updatedMessages);
          continue;
        }
      }
      
      messages.add(ParsedMessage(sender: sender, text: text));
    }

    Logger.i('OCR parsed (${messages.length} msgs): $messages');
    return OcrResult(text: rawText, messages: messages);
  }

  ProfileData _parseProfile(RecognizedText recognisedText) {
    final blocks = recognisedText.blocks;
    if (blocks.isEmpty) return ProfileData(name: '', age: null, bio: '', interests: []);

    final sortedBlocks = List<TextBlock>.from(blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    String name = '';
    int? age;
    String bio = '';
    List<String> interests = [];

    for (final block in sortedBlocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      if (name.isEmpty && !text.toLowerCase().contains('bio') && !text.toLowerCase().contains('interest')) {
        name = text;
        break;
      }
    }

    for (final block in sortedBlocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      if (RegExp(r'^\d{1,2}$').hasMatch(text)) {
        age = int.tryParse(text);
        if (age != null) break;
      }
    }

    for (final block in sortedBlocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      final lower = text.toLowerCase();
      if (lower.contains('interest')) {
        if (text.contains(':')) {
          final parts = text.split(':');
          interests.addAll(parts[1].split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        }
      } else if (lower.contains('bio')) {
        if (text.contains(':')) {
          bio = text.split(':').last.trim();
        }
      } else if (text != name && (age == null || text != age.toString())) {
        if (text.contains(',')) {
          interests.addAll(text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        } else if (text.length > 20) {
          bio = bio.isEmpty ? text : '$bio\n$text';
        }
      }
    }

    return ProfileData(name: name, age: age, bio: bio, interests: interests);
  }

  bool _isTimestamp(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('am') || lower.contains('pm')) return true;
    if (lower.contains('today') || lower.contains('yesterday')) return true;
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(line)) return true;
    return false;
  }

  void dispose() {
    _recognizer.close();
  }
}

class ParsedMessage {
  final String sender;
  final String text;

  const ParsedMessage({required this.sender, required this.text});

  @override
  String toString() => '$sender: $text';
}

class OcrResult {
  final String text;
  final List<ParsedMessage> messages;

  const OcrResult({required this.text, required this.messages});
}

class ProfileData {
  final String name;
  final int? age;
  final String bio;
  final List<String> interests;

  const ProfileData({
    required this.name,
    this.age,
    required this.bio,
    required this.interests,
  });
}
