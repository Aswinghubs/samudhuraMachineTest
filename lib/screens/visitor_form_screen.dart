import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';

class VisitorFormScreen extends StatefulWidget {
  const VisitorFormScreen({super.key, this.visitor});

  final Visitor? visitor;

  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _purposeController = TextEditingController();

  String _visitorType = 'Customer';
  String _project = 'Project A';
  bool _saving = false;

  bool get _isEditing => widget.visitor != null;

  @override
  void initState() {
    super.initState();

    final visitor = widget.visitor;
    if (visitor != null) {
      _nameController.text = visitor.name;
      _mobileController.text = visitor.mobile;
      _emailController.text = visitor.email ?? '';
      _purposeController.text = visitor.purpose;
      _visitorType = visitor.visitorType;
      _project = visitor.project;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || !RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _saveVisitor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final existing = widget.visitor;
    final visitor = Visitor(
      id: existing?.id ?? '',
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      visitorType: _visitorType,
      project: _project,
      purpose: _purposeController.text.trim(),
      status: existing?.status ?? 'Registered',
      createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
      checkInTime: existing?.checkInTime,
      checkOutTime: existing?.checkOutTime,
    );

    try {
      final provider = context.read<VisitorProvider>();

      final saved = existing == null
          ? await provider.registerVisitor(visitor)
          : await provider.editVisitor(visitor);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Visitor registered successfully'
                : 'Visitor updated successfully',
          ),
        ),
      );

      Navigator.pop(context, saved);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save visitor: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Visitor' : 'Register Visitor'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                _isEditing
                    ? 'Update visitor information'
                    : 'Enter the visitor information below',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Visitor Name *', Icons.person_outline),
                validator: (v) => _requiredValidator(v, 'Visitor name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _decoration(
                  'Mobile Number *',
                  Icons.phone,
                ).copyWith(counterText: ''),
                validator: _validateMobile,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(
                  'Email (optional)',
                  Icons.email_outlined,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visitorType,
                decoration: _decoration('Visitor Type', Icons.badge_outlined),
                items: const ['Customer', 'Vendor', 'Other']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _visitorType = v);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _project,
                decoration: _decoration('Project', Icons.apartment),
                items: const ['Project A', 'Project B', 'Project C']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _project = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Purpose of Visit *', Icons.edit_note),
                validator: (v) => _requiredValidator(v, 'Purpose'),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveVisitor,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : _isEditing
                        ? 'Save Changes'
                        : 'Register Visitor',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
