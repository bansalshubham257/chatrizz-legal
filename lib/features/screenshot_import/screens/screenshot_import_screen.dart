import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/services/ocr_service.dart';

class ScreenshotImportScreen extends StatefulWidget {
  final String matchId;

  const ScreenshotImportScreen({super.key, required this.matchId});

  @override
  State<ScreenshotImportScreen> createState() => _ScreenshotImportScreenState();
}

class _ScreenshotImportScreenState extends State<ScreenshotImportScreen> {
  File? _image;
  String? _extractedText;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _image = File(file.path));
      await _processImage(File(file.path));
    }
  }

  Future<void> _processImage(File image) async {
    setState(() => _isProcessing = true);
    try {
      final ocrService = context.read<OcrService>();
      final result = await ocrService.extractText(image);
      setState(() => _extractedText = result.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Chat Screenshot'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!, height: 180, fit: BoxFit.contain),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: AppColors.textTertiary),
                            const SizedBox(height: 8),
                            Text('Tap to select chat screenshot',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            if (_extractedText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.text_snippet, color: AppColors.purple, size: 18),
                        SizedBox(width: 6),
                        Text('Extracted Text',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_extractedText!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _extractedText),
                icon: const Icon(Icons.check),
                label: const Text('Import Messages'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
