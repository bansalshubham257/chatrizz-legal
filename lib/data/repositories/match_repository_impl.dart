import 'dart:async';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';
import 'package:chatrizz/data/models/match_model.dart';
import 'package:chatrizz/domain/entities/match.dart';
import 'package:chatrizz/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  final LocalDataSource _localDataSource;
  final StreamController<List<MatchEntity>> _controller =
      StreamController<List<MatchEntity>>.broadcast();

  MatchRepositoryImpl(this._localDataSource) {
    _localDataSource.changeNotifier.addListener(_onDataChange);
  }

  void _onDataChange() {
    _controller.add(_getMatchesSync());
  }

  List<MatchEntity> _getMatchesSync() {
    return _localDataSource.getMatches()
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Stream<List<MatchEntity>> getMatches() async* {
    yield _getMatchesSync();
    yield* _controller.stream;
  }

  @override
  Future<MatchEntity?> getMatchById(String id) async {
    final model = _localDataSource.getMatchById(id);
    return model?.toEntity();
  }

  @override
  Future<void> addMatch(MatchEntity match) async {
    await _localDataSource.addMatch(MatchModel.fromEntity(match));
  }

  @override
  Future<void> updateMatch(MatchEntity match) async {
    await _localDataSource.updateMatch(MatchModel.fromEntity(match));
  }

  @override
  Future<void> deleteMatch(String id) async {
    await _localDataSource.deleteMatch(id);
  }

  @override
  Future<int> getMatchCount() async {
    return _localDataSource.getMatches().length;
  }

  void dispose() {
    _localDataSource.changeNotifier.removeListener(_onDataChange);
    _controller.close();
  }
}
