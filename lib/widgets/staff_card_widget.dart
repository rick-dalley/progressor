import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:triage/classes/staff.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffIdCard extends StatelessWidget {
  // Null (or empty) means this person hasn't set a real photo yet — render an
  // empty avatar with a pencil affordance instead of guessing one, per the
  // 2026-08-30 fix: the license holder's own auto-seeded record used to get a
  // random canned demo face that plainly wasn't them.
  final String? photoPath;
  final String name;
  final String position;
  final String department;
  final String staffId;
  final String hireDate;
  final String phone;
  final String email;
  final String? pager;
  final DepartmentColors departmentColor;
  final int index;
  final VoidCallback? onPhotoTap;
  final String? clinicName;
  final String? specialty;

  const StaffIdCard({
    super.key,
    required this.photoPath,
    required this.name,
    required this.position,
    required this.department,
    required this.staffId,
    required this.hireDate,
    required this.phone,
    required this.email,
    this.pager,
    required this.departmentColor,
    required this.index,
    this.onPhotoTap,
    this.clinicName,
    this.specialty,
  });

  Widget _photo() {
    final path = photoPath;
    final Widget image;
    if (path == null || path.isEmpty) {
      image = Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Symbols.person, color: Colors.black26, size: 48),
      );
    } else if (path.startsWith('assets/')) {
      image = Image.asset(path, width: 100, height: 100, fit: BoxFit.cover);
    } else {
      image = Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover);
    }

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image)),
          if (onPhotoTap != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: GestureDetector(
                onTap: onPhotoTap,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Symbols.edit, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<DepartmentColors, Color> departmentColorList= {DepartmentColors.blue:Colors.blue, DepartmentColors.green:Colors.green, DepartmentColors.cyan:Colors.cyan, DepartmentColors.purple: Colors.purple};

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              height: 40.0,
              width: double.infinity,
              alignment: Alignment.center,
              color: departmentColorList[DepartmentColors.values[index % 4]],
              // A real record carries its own clinic + specialty from onboarding
              // (e.g. "Fraser Health - Psychiatry"); demo staff have neither column
              // set, so they keep the fictional "University Hospital - <department>"
              // banner as before.
              child: Text(
                (clinicName != null && clinicName!.isNotEmpty)
                    ? '$clinicName${(specialty != null && specialty!.isNotEmpty) ? ' - $specialty' : ''}'
                    : "University Hospital - $department",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Photo
                  _photo(),
                  const SizedBox(width: 16),
                  // Right Side: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(position, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text("ID: ${staffId.toUpperCase().substring(0,8)}"),
                        Text("Hired: $hireDate"),
                        const SizedBox(height: 8),
                        // Placeholder for Barcode/QR
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              color: Colors.black12, // Replace with your QR/Barcode widget
                            ),
                            // Was an unconstrained Container in a Row with no
                            // Expanded/Flexible — a long email address (or phone/pager
                            // string) had nowhere to wrap and just overflowed the
                            // card's right edge instead of clipping or wrapping.
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(8.0),
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        final Uri emailLaunchUri = Uri(
                                          scheme: 'mailto',
                                          path: email,
                                          query: 'subject=Hello&body=Regarding your inquiry...', // Optional
                                        );

                                        if (await canLaunchUrl(emailLaunchUri)) {
                                          await launchUrl(emailLaunchUri);
                                        } else {
                                          // Handle the error (e.g., show a snackbar saying no email app is configured)
                                        }
                                      },
                                      child: Text(
                                        email,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                    Text("Ph: $phone", overflow: TextOverflow.ellipsis, maxLines: 1),
                                    // Was `pager != null || pager!.isNotEmpty` — with
                                    // `||`, a null pager still evaluates the right-hand
                                    // pager!.isNotEmpty and throws a null-assertion
                                    // error; this needed `&&` to short-circuit on null.
                                    if (pager != null && pager!.isNotEmpty)
                                      Text("Pg: $pager", overflow: TextOverflow.ellipsis, maxLines: 1),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        )
      ),
    );
  }
}