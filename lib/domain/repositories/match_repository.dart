import 'package:chatrizz/domain/entities/match.dart';

abstract class MatchRepository {
  Stream<List<MatchEntity>> getMatches();
  Future<MatchEntity?> getMatchById(String id);
  Future<void> addMatch(MatchEntity match);
  Future<void> updateMatch(MatchEntity match);
  Future<void> deleteMatch(String id);
  Future<int> getMatchCount();
}
