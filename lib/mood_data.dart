import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class MoodData {
  static const String _moodKey = 'moods';

  Future<void> saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final moods = await getMoods();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    moods[today] = mood;

    await prefs.setString(_moodKey, json.encode(moods));
  }

  Future<Map<String, String>> getMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final moodsString = prefs.getString(_moodKey) ?? '{}';
    return Map<String, String>.from(json.decode(moodsString));
  }

  Future<List<String>> getWeeklyMoods() async {
    final moods = await getMoods();
    final now = DateTime.now();
    final weeklyMoods = <String>[];

    for (var i = 6; i >= 0; i--) {
      final day = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      if (moods.containsKey(day)) {
        weeklyMoods.add(moods[day]!);
      }
    }
    return weeklyMoods;
  }

  Future<List<String>> getMonthlyMoods() async {
    final moods = await getMoods();
    final now = DateTime.now();
    final monthlyMoods = <String>[];

    for (var i = 0; i < 30; i++) {
      final day = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      if (moods.containsKey(day)) {
        monthlyMoods.add(moods[day]!);
      }
    }
    return monthlyMoods;
  }
}
