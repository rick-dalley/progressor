import 'package:triage/classes/database_manager.dart';

enum DepartmentColors { blue, green, cyan, purple }

class StaffMember {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String position;
  final DateTime hireDate;
  final bool isSpecialist;
  final bool onCall;
  final String department;
  final String? pager;
  final String phone;
  final DepartmentColors color;
  // Null for anyone who hasn't set a real photo yet (the license holder's own
  // auto-seeded record, or any staff member added by hand) — StaffIdCard shows an
  // empty avatar + pencil affordance in that case instead of a demo stock photo.
  final String? photoPath;
  // What onboarding actually collected for the license holder (clinic + specialty) —
  // real staff-record data, not the hardcoded demo "department" banner below.
  final String? clinicName;
  final String? specialty;

  const StaffMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.position,
    required this.hireDate,
    required this.isSpecialist,
    required this.onCall,
    this.pager,
    required this.color,
    required this.department,
    required this.phone,
    this.photoPath,
    this.clinicName,
    this.specialty,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {

    return StaffMember(
      id: json["id"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      email: json["email"] ?? "",
      gender: json["gender"] ?? "",
      position: json["position"] ?? "",
      hireDate: DateTime.now().subtract(Duration(days: 365)),
      isSpecialist: (json["is_specialist"] == 1),
      onCall: (json["on_call"] == 1),
      pager: json["pager"] ?? "",
      phone: json["phone"] ?? "",
      color: DepartmentColors.purple,
      department: "Mental Health",
      photoPath: json["photo_path"],
      clinicName: json["clinic_name"],
      specialty: json["specialty"],
    );
  }

  // Helper to convert back to Map for your SQLite insert methods
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "gender": gender,
      "position": position,
      "is_specialist": isSpecialist ? 1 : 0,
      "on_call": onCall ? 1 : 0,
      "pager": pager,
      "phone": phone,
      "photo_path": photoPath,
      "clinic_name": clinicName,
      "specialty": specialty,
    };
  }
}

class StaffFactory {
  // 1. Private constructor
  StaffFactory._();

  // 2. The single instance
  static final StaffFactory instance = StaffFactory._();

  // 3. Cached storage
  Map<String, StaffMember> staff = {};
  List<String>? _cachedKeys;

  List<String> getStaffKeys() {
    // Cache the list to avoid heap allocation on every rebuild
    _cachedKeys ??= staff.keys.toList();
    return _cachedKeys!;
  }

  // 4. Initialization method (call this once at app startup)
  Future<void> initialize() async {
    dynamic staffData = await DatabaseManager().getStaff();
    if (staffData == null) {
       return;
    }
    for (var item in staffData) {
       StaffMember member = StaffMember.fromJson(item);
       staff[member.id] = member;
    }
  }

  // Re-reads from the database, dropping every entry currently cached — needed
  // after a license wipe replaces the whole staff table (initialize() alone only
  // adds/overwrites by id, so a wiped fake colleague would linger in memory forever
  // since nothing ever removes a key that vanished from the database).
  Future<void> reload() async {
    staff.clear();
    _cachedKeys = null;
    await initialize();
  }

  // 5. Easy access
  StaffMember? getStaffMember({required String id}) => staff[id];

  Map<String, StaffMember> get allStaff => Map.unmodifiable(staff);

}
