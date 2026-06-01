class Staff {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String position;
  final bool isSpecialist;
  final bool onCall;
  final String? pager;
  final String phone;

  const Staff({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.position,
    required this.isSpecialist,
    required this.onCall,
    this.pager,
    required this.phone,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json["id"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      email: json["email"],
      gender: json["gender"],
      position: json["position"],
      isSpecialist: (json["is_specialist"] == 1),
      onCall: (json["on_call"] == 1),
      pager: json["pager"],
      phone: json["phone"],
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
