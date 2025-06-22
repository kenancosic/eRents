import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/repositories/maintenance_repository.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;

class MaintenanceFormState extends ChangeNotifier {
  final MaintenanceRepository _repository;
  final MaintenanceIssue? _initialIssue;

  late MaintenanceIssue _issue;
  List<erents.ImageInfo> _images = [];
  bool _isLoading = false;
  String? _errorMessage;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController categoryController;

  MaintenanceFormState(
    this._repository,
    this._initialIssue, {
    int? propertyId,
    int? tenantId,
  }) : titleController = TextEditingController(
         text: _initialIssue?.title ?? '',
       ),
       descriptionController = TextEditingController(
         text: _initialIssue?.description ?? '',
       ),
       categoryController = TextEditingController(
         text: _initialIssue?.category ?? '',
       ) {
    if (_initialIssue != null) {
      _issue = _initialIssue!.copyWith();
      _images =
          _initialIssue!.imageIds
              .map((id) => erents.ImageInfo(id: id, url: '/Image/$id'))
              .toList();
    } else {
      _issue = MaintenanceIssue.empty().copyWith(
        propertyId: propertyId,
        tenantId: tenantId,
        createdAt: DateTime.now(),
      );
    }
    _addListeners();
  }

  void _addListeners() {
    titleController.addListener(() {
      _issue = _issue.copyWith(title: titleController.text);
    });
    descriptionController.addListener(() {
      _issue = _issue.copyWith(description: descriptionController.text);
    });
    categoryController.addListener(() {
      _issue = _issue.copyWith(category: categoryController.text);
    });
  }

  MaintenanceIssue get issue => _issue;
  List<erents.ImageInfo> get images => _images;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updatePriority(IssuePriority priority) {
    _issue = _issue.copyWith(priority: priority);
    notifyListeners();
  }

  void updateIsTenantComplaint(bool isComplaint) {
    _issue = _issue.copyWith(isTenantComplaint: isComplaint);
    notifyListeners();
  }

  void updateImages(List<erents.ImageInfo> updatedImages) {
    _images = updatedImages;
    final imageIds =
        updatedImages
            .map((img) => img.id)
            .where((id) => id != null && id > 0)
            .cast<int>()
            .toList();
    _issue = _issue.copyWith(imageIds: imageIds);
    notifyListeners();
  }

  Future<MaintenanceIssue?> save() async {
    if (!formKey.currentState!.validate()) {
      _errorMessage = 'Please fix the errors before saving.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_issue.maintenanceIssueId > 0) {
        final updatedItem = await _repository.update(
          _issue.maintenanceIssueId.toString(),
          _issue,
        );
        return updatedItem;
      } else {
        final newItem = await _repository.create(_issue);
        return newItem;
      }
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
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}
