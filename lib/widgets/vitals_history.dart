import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:triage/widgets/vitals_trend_gaph.dart';
import '../classes/database_manager.dart';
import '../classes/vitals.dart';
import '../screens/vitals_capture_screen.dart';

class VitalsHistoryView extends StatefulWidget {
  final String patientUuid;
  final CurrentVitalsRecord? vitals;
  final VoidCallback onAddedVitals;
  const VitalsHistoryView({super.key, required this.patientUuid, required this.vitals, required this.onAddedVitals});

  @override
  State<StatefulWidget> createState() => VitalsHistoryViewState();
}

class VitalsHistoryViewState extends State<VitalsHistoryView> {
  late Future<List<VitalsRecord>> history;
  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  @override
  void initState() {
    super.initState();
    history = getVitals();
  }

  Future<List<VitalsRecord>> getVitals() async {
    final rawData = await DatabaseManager().getPatientVitalsHistory(patientUuid: widget.patientUuid);
    return VitalsHistoryBuilder(json: rawData).history;
  }

  void showAddVitalsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Allows the modal to grow beyond 50% screen height
      backgroundColor: Colors.transparent,
      // Let the container handle the color
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        // Opens at 90% of screen height
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // A small handle to indicate the modal is draggable
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),

                Expanded(
                  child: VitalsCaptureScreen(
                    onAddVitals: (sys, dia, pulse, ox, temp) {
                      // 1. POP THE SHEET INSTANTLY: Use the modalContext from your showModalBottomSheet
                      Navigator.pop(context);

                      // 2. RUN THE DATABASE/STATE WORK
                      addVitals(
                        patientUuid: widget.patientUuid,
                        systolic: sys,
                        diastolic: dia,
                        pulse: pulse,
                        spo2: ox,
                        temperature: temp,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> addVitals({
    String? patientUuid,
    int? systolic,
    int? diastolic,
    int? pulse,
    double? spo2,
    double? temperature,
  }) async {
    if (patientUuid == null) return;
    int newSystolic = systolic ?? 0;
    int newDiastolic = diastolic ?? 0;
    int newPulse = pulse ?? 0;
    double newSpo2 = spo2 ?? 0;
    double newTemperature = temperature ?? 0;
    // Strict Machine Guard
    bool isBatchComplete = newSystolic > 0 && newDiastolic > 0 && newPulse > 0 && newSpo2 > 0 && newTemperature > 0;
    if (!isBatchComplete) return;

    // Disk I/O Pass
    await DatabaseManager().insertVitalsBatch(
      patientUuid: patientUuid,
      systolic: newSystolic,
      diastolic: newDiastolic,
      pulse: newPulse,
      spo2: newSpo2,
      temperature: newTemperature,
    );

    setState(() {
      history = getVitals();
    });

    widget.onAddedVitals.call();
  }

  @override
  Widget build(BuildContext context) {
    final double notchPadding = MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top : 47.0;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: notchPadding)),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          primary: true,
          title: const Text("Vital Signs"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showAddVitalsModal(context);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<VitalsRecord>>(
            future: history,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              final history = snapshot.data!;
              return Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // The graph widget we built earlier
                    VitalsTrendGraph(history: history),
                    const SizedBox(height: 24),
                    Text(
                      "READINGS",
                      style: GoogleFonts.inclusiveSans(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        // No horizontal scroll view here
                        child: DataTable(
                          // Important: Add this to ensure the table takes up full width
                          // without trying to be "infinitely wide"
                          dataRowMinHeight: 48,
                          columnSpacing: 10,
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('BP')),
                            DataColumn(label: Text('Pulse')),
                            DataColumn(label: Text('SpO2')),
                            DataColumn(label: Text('Temp')),
                          ],
                          rows: history.map((vital) {
                            return DataRow(
                              cells: [
                                DataCell(Text(formatter.format(vital.recordedAt ?? DateTime.now()))),
                                DataCell(Text("${vital.sys?.value.toInt()}/${vital.dia?.value.toInt()}")),
                                DataCell(Text("${vital.pulse?.value.toInt()}")),
                                DataCell(Text("${vital.o2?.value.toInt()}%")),
                                DataCell(Text("${vital.temp?.value.toStringAsFixed(1)}°C")),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
