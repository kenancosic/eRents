import 'package:flutter/material.dart';

/// A generic form screen template that provides common functionality for creating
/// and editing items with comprehensive validation and submission lifecycle management.
///
/// This template follows Material 3 design principles optimized for desktop UI.
class FormScreen<T> extends StatefulWidget {
  /// The title to display in the app bar
  final String title;

  /// The initial item for the form (null for create mode)
  final T? initialItem;

  /// Function to build the form fields
  final Widget Function(
    BuildContext context,
    T? item,
    GlobalKey<FormState> formKey,
  )
  formBuilder;

  /// Function to validate the form
  final String? Function(T item)? validator;

  /// Function to submit the form data
  final Future<bool> Function(T item) onSubmit;

  /// Function to build a new item from form data
  final T Function() createNewItem;

  /// Function to update an existing item with form data
  ///
  /// This function is used when editing an existing item to create a new
  /// instance with updated values from the form. It's only used when
  /// initialItem is not null (edit mode) and the function is provided.
  final T Function(T item)? updateItem;

  /// Whether to show a save button
  final bool showSaveButton;

  /// Custom save button text
  final String saveButtonText;

  /// Whether to show a reset button
  final bool showResetButton;

  /// Custom reset button text
  final String resetButtonText;

  /// Whether to automatically validate the form
  final bool autovalidate;

  /// Whether to enable form field focus traversal
  final bool enableFocusTraversal;

  /// Custom submit button builder
  final Widget Function(BuildContext context, VoidCallback onSubmit)?
  submitButtonBuilder;

  /// Custom validation error handler
  final void Function(String error)? onValidationError;

  const FormScreen({
    super.key,
    required this.title,
    this.initialItem,
    required this.formBuilder,
    this.validator,
    required this.onSubmit,
    required this.createNewItem,
    this.updateItem,
    this.showSaveButton = true,
    this.saveButtonText = 'Save',
    this.showResetButton = true,
    this.resetButtonText = 'Reset',
    this.autovalidate = false,
    this.enableFocusTraversal = true,
    this.submitButtonBuilder,
    this.onValidationError,
  });

  @override
  State<FormScreen<T>> createState() => _FormScreenState<T>();
}

class _FormScreenState<T> extends State<FormScreen<T>> {
  late T _item;
  late GlobalKey<FormState> _formKey;
  bool _isSubmitting = false;
  String _errorMessage = '';
  bool _autovalidateMode = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _item = widget.initialItem ?? widget.createNewItem();
    _autovalidateMode = widget.autovalidate;
  }

  void _onSubmit() async {
    setState(() {
      _errorMessage = '';
    });

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Update the item with form data if in edit mode and updateItem is provided
        T updatedItem = _item;
        if (widget.initialItem != null && widget.updateItem != null) {
          updatedItem = widget.updateItem!(_item);
        }

        // Validate the item if a validator is provided
        if (widget.validator != null) {
          final validationError = widget.validator!(updatedItem);
          if (validationError != null) {
            if (widget.onValidationError != null) {
              widget.onValidationError!(validationError);
            }
            setState(() {
              _errorMessage = validationError;
              _isSubmitting = false;
            });
            return;
          }
        }

        final success = await widget.onSubmit(updatedItem);
        if (success && mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    } else {
      setState(() {
        _autovalidateMode = true;
      });
    }
  }

  void _onReset() {
    setState(() {
      _item = widget.initialItem ?? widget.createNewItem();
      _errorMessage = '';
      _autovalidateMode = false;
    });
    _formKey.currentState?.reset();
  }

  void _updateItem(T newItem) {
    setState(() {
      _item = newItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: _buildActions()),
      body: _buildBody(),
    );
  }

  List<Widget> _buildActions() {
    final actions = <Widget>[];

    if (widget.showResetButton) {
      actions.add(
        TextButton(
          onPressed: _isSubmitting ? null : _onReset,
          child: Text(widget.resetButtonText),
        ),
      );
    }

    if (widget.showSaveButton) {
      if (widget.submitButtonBuilder != null) {
        actions.add(widget.submitButtonBuilder!(context, _onSubmit));
      } else {
        actions.add(
          ElevatedButton(
            onPressed: _isSubmitting ? null : _onSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.saveButtonText),
          ),
        );
      }
    }

    return actions;
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.formBuilder(context, _item, _formKey),
            ),
          ),
        ],
      ),
    );
  }
}
