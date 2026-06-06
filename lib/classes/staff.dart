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
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {

    return StaffMember(
      id: json["id"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      email: json["email"] ?? "",
      gender: json["gender"],
      position: json["position"] ?? "",
      hireDate: DateTime.now().subtract(Duration(days: 365)),
      isSpecialist: (json["is_specialist"] == 1),
      onCall: (json["on_call"] == 1),
      pager: json["pager"] ?? "",
      phone: json["phone"] ?? "",
      color: DepartmentColors.purple,
      department: "Mental Health",
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

  // Call this whenever you add/remove staff to invalidate the cache
  void _invalidateCache() {
    _cachedKeys = null;
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

  // 5. Easy access
  StaffMember? getStaffMember({required String id}) => staff[id];

  Map<String, StaffMember> get allStaff => Map.unmodifiable(staff);

}
