import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'image_store.dart';

final imageStoreProvider = Provider<ImageStore>((ref) => ImageStore());