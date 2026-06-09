import 'dart:ui';

enum BodyZones {
  none,
  head,
  face,
  forehead,
  neck,
  shoulder,
  chest,
  back,
  abdomen,
  buttocks,
  genitals,
  armpit,
  brachium,
  forearm,
  wrist,
  hand,
  hip,
  thigh,
  calf,
  shin,
  knee,
  foot
}

enum HeadZones { none, skull, eye, ear, nose, mouth, jaw, cheek, temple, chin }

enum HandZones { none, palm, dorsum, thumb, pointer, middle, ring, little, wristJoint }

enum FootZones { none, heel, sole, instep, ball, bigToe, secondToe, thirdToe, fourthToe, littleToe, ankleJoint }

enum ZoneMap{body, head, hand, foot}

class Zone {
  Path get shape =>
      Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(br.dx, tl.dy)..lineTo(br.dx, br.dy)..lineTo(tl.dx, br.dy)
  ..close();
  bool isIn(double dx,double dy) => shape.contains(Offset(dx, dy));
  final Offset tl;
  final Offset br;
  final String name;
  final String latin;

  Zone({required this.tl, required this.br, required this.name, required this.latin});
}

double dx = 0.0;
double dy = 0.0;
Map<BodyZones, Zone> bodyZones = {
  BodyZones.none: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "none", latin:""),
  BodyZones.head: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "head", latin:"cephalon"),
  BodyZones.forehead: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "forehead", latin:"frons"),
  BodyZones.face: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "face", latin:"facies"),
  BodyZones.neck: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "neck", latin:"cervicis"),
  BodyZones.shoulder: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "shoulder", latin:"humero"),
  BodyZones.chest: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "chest", latin:"thorax"),
  BodyZones.back: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "back", latin:"dorsum"),
  BodyZones.abdomen: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "abdomen", latin:"abdominis"),
  BodyZones.buttocks: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "buttocks", latin:"gluteus"),
  BodyZones.brachium: Zone(tl: Offset(dx, dy), br: Offset(dx, dy), name: "upper arm", latin:"brachium"),
  BodyZones.armpit: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "armpit", latin:"axilla"),
  BodyZones.forearm: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "forearm", latin:"Antebrachium"),
  BodyZones.wrist: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "wrist", latin:"carpus"),
  BodyZones.hand: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "hand", latin:"manus"),
  BodyZones.hip: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "hip", latin:"coxal"),
  BodyZones.thigh: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "thigh", latin:"femur"),
  BodyZones.knee: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "knee", latin:"patella"),
  BodyZones.shin: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "shin", latin:"tibia"),
  BodyZones.calf: Zone( tl: Offset(dx, dy), br: Offset(dx, dy), name: "calf", latin:"sura"),
  BodyZones.foot: Zone(tl: Offset(dx, dy), br: Offset(dx, dy), name: "foot", latin:"pes"),
};

Map<HeadZones, Zone> headZones = {
  HeadZones.none: Zone( name: "none", latin: "", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.skull: Zone( name: "skull", latin: "cranium", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.eye: Zone( name: "eye", latin: "oculus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.ear: Zone( name: "ear", latin: "auris", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.nose: Zone( name: "nose", latin: "nasus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.mouth: Zone(  name: "mouth", latin: "os", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.jaw: Zone( name: "jaw", latin: "mandibula", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.cheek: Zone( name: "cheek", latin: "bucca", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.temple: Zone( name: "temple", latin: "tempora", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HeadZones.chin: Zone( name: "chin", latin: "mentum", tl: Offset(dx, dy), br: Offset(dx, dy)),
};

Map<HandZones, Zone> handZones = {
  HandZones.none: Zone( name: "none", latin: "", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.palm: Zone( name: "palm", latin: "palma", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.dorsum: Zone( name: "dorsum", latin: "dorsum manus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.thumb: Zone( name: "thumb", latin: "pollex", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.pointer: Zone( name: "index finger", latin: "index", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.middle: Zone( name: "middle finger", latin: "digitus medius", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.ring: Zone( name: "ring finger", latin: "digitus annularis", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.little: Zone( name: "little finger", latin: "digitus minimus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  HandZones.wristJoint: Zone( name: "wrist joint", latin: "articulatio radiocarpalis", tl: Offset(dx, dy), br: Offset(dx, dy)),
};

Map<FootZones, Zone> footZones = {
  FootZones.none: Zone( name: "none", latin: "", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.heel: Zone(name: "heel", latin: "calcaneus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.sole: Zone( name: "sole", latin: "planta", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.instep: Zone( name: "instep", latin: "instita", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.ball: Zone( name: "ball of foot", latin: "caput metatarsale", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.bigToe: Zone( name: "big toe", latin: "hallux", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.secondToe: Zone( name: "second toe", latin: "digitus secundus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.thirdToe: Zone( name: "third toe", latin: "digitus tertius", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.fourthToe: Zone( name: "fourth toe", latin: "digitus quartus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.littleToe: Zone( name: "little toe", latin: "digitus minimus", tl: Offset(dx, dy), br: Offset(dx, dy)),
  FootZones.ankleJoint: Zone( name: "ankle joint", latin: "articulatio talocruralis", tl: Offset(dx, dy), br: Offset(dx, dy)),
};

