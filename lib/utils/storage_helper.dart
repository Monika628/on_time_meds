import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/pill_model.dart';

class Storage {
  static const _key = 'pill_reminders';

  static Future<void> savePills(List<PillModel> pills, String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = pills.map((pill) => pill.toJson()).toList();
    await prefs.setString('${_key}_$userEmail', jsonEncode(jsonList));
  }

  static Future<void> savePill(List<PillModel> pills) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = pills.map((pill) => pill.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  static Future<List<PillModel>> getPills() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((item) => PillModel.fromJson(item)).toList();
  }

  static Future<void> addPill(PillModel pill) async {
    final pills = await getPills();
    pills.add(pill);
    await savePill(pills);
  }

  static Future<void> updatePill(PillModel updatedPill) async {
    final pills = await getPills();
    final index = pills.indexWhere((p) => p.id == updatedPill.id);
    if (index != -1) {
      pills[index] = updatedPill;
      await savePill(pills);
    }
  }

  static Future<void> deletePill(int id) async {
    final pills = await getPills();
    pills.removeWhere((p) => p.id == id);
    await savePill(pills);
  }
}
