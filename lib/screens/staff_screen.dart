import 'package:flutter/material.dart';
import 'package:triage/classes/staff.dart';
import 'package:triage/widgets/staff_card_widget.dart';

import '../app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => StaffScreenState();
}

class StaffScreenState extends State<StaffScreen> {
  List<String> staffKeys = [];

  @override
  void initState() {
    super.initState();
    _loadStaffKeys();
  }

  Future<void> _loadStaffKeys() async {
    // DatabaseManager is a singleton, so this is safe and fast
    staffKeys = StaffFactory.instance.getStaffKeys();
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
        body: staffKeys.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.deepLogicViolet, // Navy indicator for a "smart" feel
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              // Added top padding for breathing room
              itemCount: staffKeys.length,
              itemBuilder: (context, index) {
                StaffMember? staffMember = StaffFactory.instance.getStaffMember(id: staffKeys[index]);
                return StaffIdCard(
                  photoPath: 'photoPath',
                  name: '${staffMember?.firstName} ${staffMember?.lastName}',
                  position: staffMember!.position,
                  department: staffMember.department,
                  staffId: staffMember.id,
                  hireDate: staffMember.hireDate.year.toString(),
                  phone: staffMember.phone,
                  email: staffMember.email,
                  pager: staffMember.pager,
                  departmentColor: staffMember.color,
                  index: index,
                );
              },
            ),
      )
    );
  }
}
