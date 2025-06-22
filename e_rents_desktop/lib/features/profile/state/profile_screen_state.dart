import 'package:flutter/material.dart';

class ProfileScreenState extends ChangeNotifier {
  bool _isEditing = false;
  bool _isSaving = false;

  bool get isEditing => _isEditing;
  bool get isSaving => _isSaving;

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void cancelEditing() {
    _isEditing = false;
    notifyListeners();
  }

  void setSaving(bool saving) {
    if (_isSaving != saving) {
      _isSaving = saving;
      notifyListeners();
    }
  }

  void onSaveCompleted() {
    _isEditing = false;
    _isSaving = false;
    notifyListeners();
  }
}
