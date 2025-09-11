

import 'package:flutter/material.dart';

class PillValidationHelper {
  static String? validatePillName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter medicine name';
    }
    if (value.trim().length < 2) {
      return 'Medicine name must be at least 2 characters';
    }
    return null;
  }

  static String? validateTime(TimeOfDay? time) {
    if (time == null) {
      return 'Please select reminder time';
    }
    return null;
  }

  static String? validateTypes(List<String>? types) {
    if (types == null || types.isEmpty) {
      return 'Please select at least one medicine type';
    }
    return null;
  }

  static String? validateDosage(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      // Optional validation for dosage format
      if (value.trim().length < 1) {
        return 'Please enter valid dosage';
      }
    }
    return null;
  }

  static String? validateInterval(int? interval) {
    if (interval != null && interval <= 0) {
      return 'Interval must be greater than 0';
    }
    return null;
  }

  static Map<String, String> validatePillData({
    required String pillName,
    required TimeOfDay? time,
    required List<String>? types,
    String? dosage,
    int? interval,
  }) {
    Map<String, String> errors = {};

    final nameError = validatePillName(pillName);
    if (nameError != null) errors['pillName'] = nameError;

    final timeError = validateTime(time);
    if (timeError != null) errors['time'] = timeError;

    final typesError = validateTypes(types);
    if (typesError != null) errors['types'] = typesError;

    final dosageError = validateDosage(dosage);
    if (dosageError != null) errors['dosage'] = dosageError;

    final intervalError = validateInterval(interval);
    if (intervalError != null) errors['interval'] = intervalError;

    return errors;
  }

  static bool isValidPillData({
    required String pillName,
    required TimeOfDay? time,
    required List<String>? types,
    String? dosage,
    int? interval,
  }) {
    final errors = validatePillData(
      pillName: pillName,
      time: time,
      types: types,
      dosage: dosage,
      interval: interval,
    );
    return errors.isEmpty;
  }
}