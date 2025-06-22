import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/repositories/maintenance_repository.dart';
import 'package:flutter/material.dart';

class MaintenanceStatusUpdateState extends ChangeNotifier {
  final MaintenanceRepository _repository;
  final MaintenanceIssue _initialIssue;

  late IssueStatus _selectedStatus;
  final TextEditingController costController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  MaintenanceStatusUpdateState(this._repository, this._initialIssue) {
    _selectedStatus = _initialIssue.status;
    costController.text = _initialIssue.cost?.toString() ?? '';
    notesController.text = _initialIssue.resolutionNotes ?? '';
  }

  IssueStatus get selectedStatus => _selectedStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasChanges =>
      _selectedStatus != _initialIssue.status ||
      costController.text != (_initialIssue.cost?.toString() ?? '') ||
      notesController.text != (_initialIssue.resolutionNotes ?? '');

  void updateStatus(IssueStatus newStatus) {
    if (_selectedStatus == newStatus) return;
    _selectedStatus = newStatus;
    if (newStatus == IssueStatus.completed && notesController.text.isEmpty) {
      notesController.text = 'Work completed.';
    }
    notifyListeners();
  }

  Future<MaintenanceIssue?> saveChanges() async {
    if (!hasChanges) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedIssue = await _repository.updateIssueStatus(
        _initialIssue.maintenanceIssueId.toString(),
        _selectedStatus,
        resolutionNotes:
            notesController.text.isNotEmpty ? notesController.text : null,
        cost: double.tryParse(costController.text),
      );
      return updatedIssue;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    costController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
