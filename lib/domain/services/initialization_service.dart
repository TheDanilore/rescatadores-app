import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

class InitializationService {
  Future<void> initialize() async {
    try {
      // Configure Firestore for offline work
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Initialize date formatting in Spanish in the background
      await Future.microtask(() async {
        await initializeDateFormatting('es', null);
      });
    } catch (e) {
      print('Initialization Service Error: $e');
      // Decide whether to rethrow based on the criticality of the error
      rethrow;
    }
  }
}
