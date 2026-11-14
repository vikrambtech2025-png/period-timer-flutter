import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/alarm_service.dart';

final storageService = StorageService();
final authService = AuthService(storageService);
final alarmService = AlarmService();