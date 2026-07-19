import 'package:chatrizz/domain/entities/memory.dart';

abstract class MemoryRepository {
  Stream<List<MemoryEntity>> getMemories(String matchId);
  Future<void> addMemory(MemoryEntity memory);
  Future<void> deleteMemory(String id);
  Future<void> deleteMemoriesForMatch(String matchId);
  Future<String> generateSummary(String matchId);
  Future<void> autoGenerateMemories(String matchId);
}
