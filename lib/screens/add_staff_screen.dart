import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';

import '../app_theme.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _clinicController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pagerController = TextEditingController();
  bool _isSpecialist = false;
  bool _onCall = false;
  bool _saving = false;

  bool get _canSave => _firstNameController.text.trim().isNotEmpty && _lastNameController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _clinicController.dispose();
    _specialtyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pagerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    await DatabaseManager().addStaffMember(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      position: _positionController.text.trim(),
      clinicName: _clinicController.text.trim(),
      specialty: _specialtyController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      pager: _pagerController.text.trim(),
      isSpecialist: _isSpecialist,
      onCall: _onCall,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Staff Member")),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(labelText: "First Name"),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: "Last Name"),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16.0),
          TextField(controller: _positionController, decoration: const InputDecoration(labelText: "Position")),
          const SizedBox(height: 16.0),
          TextField(controller: _clinicController, decoration: const InputDecoration(labelText: "Clinic / Employer")),
          const SizedBox(height: 16.0),
          TextField(controller: _specialtyController, decoration: const InputDecoration(labelText: "Specialty")),
          const SizedBox(height: 16.0),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: "Phone"),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _pagerController,
            decoration: const InputDecoration(labelText: "Pager"),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8.0),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Specialist"),
            value: _isSpecialist,
            onChanged: (value) => setState(() => _isSpecialist = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("On call"),
            value: _onCall,
            onChanged: (value) => setState(() => _onCall = value),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _canSave && !_saving ? _save : null,
            style: ElevatedButton.styleFrom(
              fixedSize: const Size.fromHeight(50),
              backgroundColor: AppTheme.deepLogicViolet,
              foregroundColor: AppTheme.clinicalWhite,
            ),
            icon: const Icon(Symbols.save),
            label: Text(_saving ? "Saving..." : "Save"),
          ),
        ],
      ),
    );
  }
}
