import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dataRevisionProvider =
    NotifierProvider<DataRevisionNotifier, int>(DataRevisionNotifier.new);