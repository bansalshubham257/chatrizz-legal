import 'package:flutter_test/flutter_test.dart';
import 'package:chatrizz/main.dart';
import 'package:chatrizz/data/datasources/local/local_datasource.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final localDataSource = LocalDataSource();
    await localDataSource.init();
    await tester.pumpWidget(ChatRizzApp(localDataSource: localDataSource));
  });
}
