import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/lost_person_repository.dart';
import '../repositories/ghat_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/facility_repository.dart';
import '../models/lost_person.dart';
import '../models/ghat.dart';
import '../models/user_profile.dart';
import '../models/facility.dart';

// Repository Providers
final lostPersonRepositoryProvider = Provider((ref) => LostPersonRepository());
final ghatRepositoryProvider = Provider((ref) => GhatRepository());
final userRepositoryProvider = Provider((ref) => UserRepository());
final facilityRepositoryProvider = Provider((ref) => FacilityRepository());

// Lost Persons Stream Provider
final lostPersonsStreamProvider = StreamProvider<List<LostPerson>>((ref) {
  final repository = ref.watch(lostPersonRepositoryProvider);
  return repository.getLostPersonsStream();
});

// Ghats Stream Provider
final ghatsStreamProvider = StreamProvider<List<Ghat>>((ref) {
  final repository = ref.watch(ghatRepositoryProvider);
  return repository.getGhatsStream();
});

// Facilities Stream Provider
final facilitiesStreamProvider = StreamProvider<List<Facility>>((ref) {
  final repository = ref.watch(facilityRepositoryProvider);
  return repository.getFacilities();
});

// Facilities by Type Provider
final facilitiesByTypeProvider =
    StreamProvider.family<List<Facility>, FacilityType>((ref, type) {
      final repository = ref.watch(facilityRepositoryProvider);
      return repository.getFacilitiesByType(type);
    });

// Current User Profile Provider
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUserProfile();
});

// Lost Person Search Provider
final lostPersonSearchProvider =
    StreamProvider.family<List<LostPerson>, String>((ref, query) {
      final repository = ref.watch(lostPersonRepositoryProvider);
      return repository.searchByName(query);
    });

// Ghats by Crowd Level Provider
final ghatsByCrowdLevelProvider = StreamProvider.family<List<Ghat>, CrowdLevel>(
  (ref, level) {
    final repository = ref.watch(ghatRepositoryProvider);
    return repository.getGhatsByCrowdLevel(level);
  },
);
