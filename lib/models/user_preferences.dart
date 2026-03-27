import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 2)
class UserPreferences extends HiveObject {
  @HiveField(0)
  bool hasCompletedOnboarding;

  @HiveField(1)
  List<String> favouriteSingerIds;  // e.g. ['arijit', 'taylor', 'bts']

  @HiveField(2)
  DateTime onboardingCompletedAt;

  UserPreferences({
    this.hasCompletedOnboarding = false,
    this.favouriteSingerIds = const [],
    required this.onboardingCompletedAt,
  });
}
