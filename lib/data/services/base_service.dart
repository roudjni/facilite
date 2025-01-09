// lib/services/base_service.dart

import 'package:facilite/data/database/database_helper.dart';

abstract class BaseService {
  final DatabaseHelper databaseHelper = DatabaseHelper.instance;
}