enum WardId {
  emergencyDepartment,
  intensiveCareUnit,
  cardiacCareUnit,
  neonatalIntensiveCareUnit,
  pediatricIntensiveCareUnit,
  surgicalIntensiveCareUnit,
  medicalWard,
  surgicalWard,
  orthopedicWard,
  maternityWard,
  deliveryWard,
  postpartumWard,
  oncologyWard,
  neurologyWard,
  cardiologyWard,
  psychiatricWard,
  geriatricWard,
  pediatricWard,
  burnUnit,
  recoveryRoom,
  operatingRoom,
  radiologyImaging,
  dialysisUnit,
  rehabilitationUnit,
  ambulatorySurgeryCenter,
  respiratoryCareUnit,
  infectiousDiseaseWard,
  stepDownUnit,
  hospiceWard,
  palliativeCareUnit,
  observationUnit,
  shortStayUnit,
  traumaUnit,
  transplantationUnit,
}

class Ward {
  final WardId id;
  final String name;

  const Ward({required this.id, required this.name});

  factory Ward.fromJson(Map<String, dynamic> json) {
    int rawId = json['id'];
    return Ward(
      id: WardId.values[rawId],
      name: json['name'],
    );
  }
}

class WardsFactory {
  // Using int as the key (id) for fast O(1) lookups
  final Map<WardId, Ward> wards;

  WardsFactory(this.wards);

  factory WardsFactory.fromJson(List<dynamic> jsonList) {
    Map<WardId, Ward> tempMap = {};

    for (var item in jsonList) {
      final ward = Ward.fromJson(item);
      tempMap[ward.id] = ward;
    }

    return WardsFactory(tempMap);
  }

  // Helper to get a name by ID easily
  String getWardName(WardId id) => wards[id]?.name ?? "Unknown Ward";
}