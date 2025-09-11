import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class RingtoneService {
  static AudioPlayer? _previewPlayer;
  static AudioPlayer? _alarmPlayer;

  // Play preview sound for ringtone selection
  static Future<void> playPreviewSound(String assetPath) async {
    try {
      // Stop any existing preview sound
      await stopPreviewSound();

      // Create new player for preview
      _previewPlayer = AudioPlayer();

      // Set volume to a reasonable level for preview
      await _previewPlayer!.setVolume(0.7);

      // Play the sound
      await _previewPlayer!.play(AssetSource(assetPath.replaceFirst('assets/', '')));

      // Provide haptic feedback
      HapticFeedback.selectionClick();
    } catch (e) {
      print('Error playing preview sound: $e');
    }
  }

  // Stop preview sound
  static Future<void> stopPreviewSound() async {
    try {
      if (_previewPlayer != null) {
        await _previewPlayer!.stop();
        await _previewPlayer!.dispose();
        _previewPlayer = null;
      }
    } catch (e) {
      print('Error stopping preview sound: $e');
    }
  }

  // Play alarm sound (for actual alarms)
  static Future<void> playAlarmSound(String assetPath) async {
    try {
      // Stop any existing alarm sound
      await stopAlarmSound();

      // Create new player for alarm
      _alarmPlayer = AudioPlayer();

      // Set volume to maximum for alarm
      await _alarmPlayer!.setVolume(1.0);

      // Set to loop the alarm sound
      await _alarmPlayer!.setReleaseMode(ReleaseMode.loop);

      // Play the alarm sound
      await _alarmPlayer!.play(AssetSource(assetPath.replaceFirst('assets/', '')));

      // Provide strong haptic feedback for alarm
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('Error playing alarm sound: $e');
    }
  }

  // Stop alarm sound
  static Future<void> stopAlarmSound() async {
    try {
      if (_alarmPlayer != null) {
        await _alarmPlayer!.stop();
        await _alarmPlayer!.dispose();
        _alarmPlayer = null;
      }
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }
  }

  // Update pill ringtone in storage/database
  static Future<void> updatePillRingtone(String pillId, String ringtone) async {
    try {
      // TODO: Implement your database/storage update logic here
      // This could be SharedPreferences, SQLite, or any other storage solution

      // Example with SharedPreferences:
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('pill_${pillId}_ringtone', ringtone);

      print('Updated ringtone for pill $pillId to $ringtone');
    } catch (e) {
      print('Error updating pill ringtone: $e');
    }
  }

  // Get available ringtones
  static List<String> getAvailableRingtones() {
    return [
      'Default',
      'Gentle Bell',
      'Medical Alert',
      'Chimes',
      'Buzzer',
      'Melody',
    ];
  }

  // Get asset path for ringtone
  static String getAssetPathForRingtone(String ringtoneName) {
    switch (ringtoneName) {
      case 'Default':
        return 'assets/sounds/default_alarm.mp3';
      case 'Gentle Bell':
        return 'assets/sounds/gentle_bell.mp3';
      case 'Medical Alert':
        return 'assets/sounds/medical_beep.mp3';
      case 'Chimes':
        return 'assets/sounds/chimes.mp3';
      case 'Buzzer':
        return 'assets/sounds/buzzer.mp3';
      case 'Melody':
        return 'assets/sounds/melody.mp3';
      default:
        return 'assets/sounds/default_alarm.mp3';
    }
  }

  // Clean up all audio players (call this when app is closing)
  static Future<void> dispose() async {
    await stopPreviewSound();
    await stopAlarmSound();
  }
}