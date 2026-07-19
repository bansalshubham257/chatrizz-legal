import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:chatrizz/app/theme/app_colors.dart';
import 'package:chatrizz/domain/entities/match.dart';
import 'package:chatrizz/domain/repositories/match_repository.dart';
import 'package:chatrizz/services/ocr_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  _AddMatchScreenState() : super();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Match'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purple,
          labelColor: AppColors.purpleLight,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(icon: Icon(Icons.edit_outlined), text: 'Manual'),
            Tab(icon: Icon(Icons.document_scanner_outlined), text: 'Scan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ManualEntryForm(),
          _ScanProfileScreen(),
        ],
      ),
    );
  }
}

class _ManualEntryForm extends StatefulWidget {
  @override
  State<_ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<_ManualEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  final _uuid = const Uuid();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestsController,
              decoration: const InputDecoration(
                labelText: 'Interests (comma separated)',
                prefixIcon: Icon(Icons.interests_outlined),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMatch,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Match'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final interests = _interestsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final age = int.tryParse(_ageController.text.trim());

    final match = MatchEntity(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      age: age,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      interests: interests,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<MatchRepository>().addMatch(match);
    if (mounted) Navigator.pop(context);
  }
}

class _ScanProfileScreen extends StatefulWidget {
  @override
  State<_ScanProfileScreen> createState() => _ScanProfileScreenState();
}

class _ScanProfileScreenState extends State<_ScanProfileScreen> {
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
      final ocr = context.read<OcrService>();
      final result = await ocr.extractText(image);
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

  Future<void> _createMatch() async {
    if (_extractedText == null || _extractedText!.isEmpty) return;

    final lines = _extractedText!
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String name = '';
    final bioParts = <String>[];
    final interests = <String>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (name.isEmpty && line.length < 30 && !lower.contains('bio') &&
          !lower.contains('interest') && !line.contains(',')) {
        name = line;
      } else if (lower.contains('interest') || line.contains(',')) {
        interests.addAll(line.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      } else {
        bioParts.add(line);
      }
    }

    if (name.isEmpty && lines.isNotEmpty) name = lines.first;

    final match = MatchEntity(
      id: const Uuid().v4(),
      name: name,
      bio: bioParts.isNotEmpty ? bioParts.join(' ') : null,
      interests: interests,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.read<MatchRepository>().addMatch(match);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                          Text('Tap to select profile screenshot',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          if (_extractedText != null && _extractedText!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_extractedText!,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createMatch,
              icon: const Icon(Icons.favorite),
              label: const Text('Create Match from Screenshot'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
