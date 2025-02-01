import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final templateProvider = FutureProvider((ref) async {
  return apiService.getTemplates();
});
