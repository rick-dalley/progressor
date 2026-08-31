import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/staff.dart';
import 'package:triage/screens/add_staff_screen.dart';
import 'package:triage/widgets/staff_card_widget.dart';

import '../app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => StaffScreenState();
}

class StaffScreenState extends State<StaffScreen> {
  List<String> staffKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffKeys();
  }

  // Reloads from the database every time this screen opens rather than trusting
  // whatever StaffFactory happened to load at app startup — the one-shot read this
  // used to do left the screen spinning forever if opened before app init finished,
  // and never noticed a staff member added since (or removed by a license wipe).
  Future<void> _loadStaffKeys() async {
    await StaffFactory.instance.reload();
    if (!mounted) return;
    setState(() {
      staffKeys = StaffFactory.instance.getStaffKeys();
      _isLoading = false;
    });
  }

  Future<void> _addStaff() async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddStaffScreen()));
    if (added == true) _loadStaffKeys();
  }

  Future<void> _pickPhoto(StaffMember staffMember) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await DatabaseManager().updateStaffPhoto(id: staffMember.id, photoPath: picked.path);
    await _loadStaffKeys();
  }

  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Staff"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addStaff,
          backgroundColor: AppTheme.deepLogicViolet,
          child: const Icon(Symbols.add, color: AppTheme.clinicalWhite),
        ),
        body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.deepLogicViolet, // Navy indicator for a "smart" feel
              ),
            )
          : staffKeys.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "No staff on file yet. Tap + to add your first staff member.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.deepCharcoal.withValues(alpha: 0.6)),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              // Added top padding for breathing room
              itemCount: staffKeys.length,
              itemBuilder: (context, index) {
                StaffMember? staffMember = StaffFactory.instance.getStaffMember(id: staffKeys[index]);
                staffMember!;
                return StaffIdCard(
                  photoPath: staffMember.photoPath,
                  name: '${staffMember.firstName} ${staffMember.lastName}',
                  position: staffMember.position,
                  department: staffMember.department,
                  clinicName: staffMember.clinicName,
                  specialty: staffMember.specialty,
                  staffId: staffMember.id,
                  hireDate: staffMember.hireDate.year.toString(),
                  phone: staffMember.phone,
                  email: staffMember.email,
                  pager: staffMember.pager,
                  departmentColor: staffMember.color,
                  index: index,
                  onPhotoTap: () => _pickPhoto(staffMember),
                );
              },
            ),
      )
    );
  }
}
