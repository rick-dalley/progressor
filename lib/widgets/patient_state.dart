import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/database_manager.dart';
import 'package:triage/classes/phase_state_handlers.dart';

Map<String, IconData> eventIcons = {
"ED_ARRIV" : Symbols.check_in_out,
"ED_AMBUL": Symbols.ambulance,
"ED_POLIC": Symbols.local_police,
"ED_INTAK": Symbols.medical_information,
"ID_ANONY": Symbols.person_off,
"ID_MERGE": Symbols.person_check,
"TR_START": Symbols.stethoscope,
"TR_COMPL": Symbols.stethoscope_check,
"TR_REASS": Symbols.stethoscope_arrow,
"DC_LWBS": Symbols.run_circle,
"ED_ALLOC": Symbols.short_stay,
"MD_ASSES": Symbols.medical_mask,
"VT_LOGGD": Symbols.vital_signs,
"CL_NOTES" : Symbols.clinical_notes,
"ED_RELOC": Symbols.moving_beds,
"LB_ORDER": Symbols.fluid_balance,
"LB_DRAWN": Symbols.labs,
"LB_HEMOL": Symbols.hematology,
"LB_RESUL": Symbols.lab_profile,
"IM_ORDER":Symbols.skeleton,
"IM_START": Symbols.radiology,
"IM_REJCT": Symbols.radiology, //add an xbadge
"IM_INTER": Symbols.radiology, //add a magnifying glass
"MD_ADMIN": Symbols.admin_meds,
"PR_PERFM": Symbols.procedure,
"BL_TRANS": Symbols.fluid,
"MH_DETAIN":Symbols.psychiatry_sharp,
"RE_START": Symbols.shield_lock,
"RE_TERMN":Symbols.shield,
"IS_OLATN": Symbols.safety_divider,
"PO_POWER":Symbols.balance,
"SEC_INCI":Symbols.admin_panel_settings,
"CS_REQU":Symbols.person_add,
"CS_ARRIV": Symbols.person,
"CS_DECIS": Symbols.person_check,
"DP_DECIS": Symbols.arrow_split,
"WD_REQU":Symbols.contact_support,
"WD_ALLOC":Symbols.ward,
"WD_REPOR":Symbols.assignment,
"ED_BOARD":Symbols.short_stay,
"ED_DEPAR":Symbols.moving_beds,
"OR_TRANS":Symbols.surgical,
"IC_TRANS":Symbols.diversity_1,
"WD_ARRIV":Symbols.inpatient,
"DC_INSTR": Symbols.developer_guide,
"DC_CLEAR": Symbols.door_open,
"DC_COMPL": Symbols.home,
"DC_AMA": Symbols.person_cancel,
"DC_ELOPD": Symbols.luggage,
"DC_SHEL": Symbols.night_shelter,
"DC_EXTRN": Symbols.local_police,
"HSP_TRNS": Symbols.local_hospital,
"DC_PASTR": Symbols.family_home,
"PT_DECEAS": Symbols.deceased,
"DC_CORON": Symbols.deceased
};

Map<PatientStatePhase, IconData> patientStateIcons = {
  PatientStatePhase.preHospitalAndIntake: Symbols.emergency,
  PatientStatePhase.assessmentAndBedTracking: Symbols.conditions,
  PatientStatePhase.diagnosticsAndInterventions: Symbols.diagnosis,
  PatientStatePhase.safetyAndLegalInterventions: Symbols.security,
  PatientStatePhase.consultationsAndDecisions: Symbols.stethoscope,
  PatientStatePhase.inpatientAdmissionPathway: Symbols.bed,
  PatientStatePhase.dischargePathway: Symbols.airport_shuttle,
};


class PatientStateWidget extends StatefulWidget {
  final List<String> prompts; // [previous, current, next]

  const PatientStateWidget({super.key, required this.prompts});

  @override
  State<PatientStateWidget> createState() => _PatientStateWidgetState();
}

class _PatientStateWidgetState extends State<PatientStateWidget> {
  late PageController _promptController;
  late Phase activePhase;
  late IconData activeIcon;
  late List<String> prompts = widget.prompts;

  @override
  void initState() {
    super.initState();
    // Start on index 1 (the 'current' prompt)
    int randomNumber = Random().nextInt(6);
    PatientStatePhase activeStatePhase = PatientStatePhase.values[randomNumber];
    activeIcon = patientStateIcons[activeStatePhase] ?? Symbols.local_police;
    activePhase = (DatabaseManager().phases[activeStatePhase] ?? DatabaseManager().phases[PatientStatePhase.unknown])!;
    prompts[1] = activePhase.label;
    _promptController = PageController(initialPage: 1, viewportFraction: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final List<Event> eventList = activePhase.events?.values.toList() ?? [];
    return SizedBox(
      height: 60, // Fixed height for the row
      child: Row(
        children: [
          // Left Side: 50% width for the scrollable prompts
          SizedBox(height: 16),
          Expanded(
            flex: 1,
            child: PageView.builder(
              controller: _promptController,
              itemCount: widget.prompts.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Row(
                    children: [
                      Icon(activeIcon),
                      const SizedBox(width: 8), // Added a little spacing for a cleaner UI
                      Expanded( // This is the crucial fix
                        child: Text(
                          widget.prompts[index],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Right Side: 50% width for horizontal icon list
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: eventList.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final event = eventList[index];
                  final IconData iconData = eventIcons[event.id] ?? Symbols.unknown_document;
                  return SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      iconData,
                      size: 32,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
