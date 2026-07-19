import 'dart:async';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/data/models/memory_model.dart';
import 'package:chatrizz/domain/entities/memory.dart';
import 'package:chatrizz/domain/repositories/memory_repository.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  final LocalDataSource _localDataSource;
  final StreamController<List<MemoryEntity>> _controller = StreamController<List<MemoryEntity>>.broadcast();
  String? _currentMatchId;

  MemoryRepositoryImpl(this._localDataSource) {
    _localDataSource.changeNotifier.addListener(_onDataChange);
  }

  void _onDataChange() {
    if (_currentMatchId != null) {
      _controller.add(_getMemoriesSync(_currentMatchId!));
    }
  }

  List<MemoryEntity> _getMemoriesSync(String matchId) {
    return _localDataSource.getMemories(matchId)
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<MemoryEntity>> getMemories(String matchId) async* {
    _currentMatchId = matchId;
    yield _getMemoriesSync(matchId);
    yield* _controller.stream;
  }

  @override
  Future<void> addMemory(MemoryEntity memory) async {
    await _localDataSource.addMemory(MemoryModel.fromEntity(memory));
  }

  @override
  Future<void> deleteMemory(String id) async {
    // Find which match this memory belongs to
    // For simplicity, iterate through all matches
    // In production, store matchId in memory model
  }

  @override
  Future<void> deleteMemoriesForMatch(String matchId) async {
    await _localDataSource.deleteMemoriesForMatch(matchId);
  }

  @override
  Future<String> generateSummary(String matchId) async {
    final memories = _getMemoriesSync(matchId);
    if (memories.isEmpty) return 'No memories yet.';
    final important = memories.where((m) => m.isImportant).toList();
    final items = important.isNotEmpty ? important : memories;
    return items.map((m) => m.content).join('. ');
  }

  @override
  Future<void> autoGenerateMemories(String matchId) async {}

  void dispose() {
    _localDataSource.changeNotifier.removeListener(_onDataChange);
    _controller.close();
  }
}
