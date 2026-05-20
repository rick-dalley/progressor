import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// A type-safe container representing the extracted demographic fields
/// from a North American (AAMVA compliant) ID card or Driver's License.
class ParsedIdData {
  final String rawPayload;
  final String idNumber;     // DAQ
  final String lastName;     // DCS (or DAA)
  final String firstName;    // DAC (or DAA)
  final String middleName;   // DAD (or DAA)
  final String streetAddress;// DAG
  final String city;         // DAI
  final String province;     // DAJ
  final String postalCode;   // DAK
  final DateTime? dateOfBirth; // DBB
  final DateTime? expiryDate;  // DBA

  ParsedIdData({
    required this.rawPayload,
    required this.idNumber,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.streetAddress,
    required this.city,
    required this.province,
    required this.postalCode,
    this.dateOfBirth,
    this.expiryDate,
  });

  @override
  String toString() {
    return 'ParsedIdData(Name: $firstName $lastName, ID: $idNumber, DOB: ${dateOfBirth?.toIso8601String().substring(0, 10)})';
  }
}

/// A dedicated service engine to scan static image files for PDF417 matrix symbols
/// and compile the raw data blocks into native, type-safe data structures.
class Pdf417IdScannerService {
  // Instantiating the underlying C++ scanning core restricted purely to PDF417 format geometry
  final BarcodeScanner _scanner = BarcodeScanner(formats: [BarcodeFormat.pdf417]);

  /// Scans a file path for a PDF417 barcode.
  /// Returns a [ParsedIdData] instance if successful, or [null] if no legible barcode is found.
  Future<ParsedIdData?> scanImageFile(String filePath) async {
    final File imageFile = File(filePath);
    if (!await imageFile.exists()) {
      debugPrint("IdScannerService Error: Target file path does not exist: $filePath");
      return null;
    }

    final inputImage = InputImage.fromFilePath(filePath);

    try {
      // Execute the native visual analysis pipeline
      final List<Barcode> detectedBarcodes = await _scanner.processImage(inputImage);

      if (detectedBarcodes.isEmpty) {
        debugPrint("IdScannerService: No PDF417 barcodes matching required geometry parameters found.");
        return null;
      }

      // Grab the primary target matrix
      final Barcode primaryBarcode = detectedBarcodes.first;
      final String? rawPayload = primaryBarcode.rawValue;

      if (rawPayload == null || rawPayload.trim().isEmpty) {
        debugPrint("IdScannerService: Barcode structure detected but raw data channel read empty.");
        return null;
      }

      // Drop the raw character stream straight into our specialized subfile engine
      return _parseAamvaPayload(rawPayload);

    } catch (e) {
      debugPrint("IdScannerService Critical Exception: Failed to decode target frame context: $e");
      return null;
    }
  }

  /// Internal processing layer to parse out the field boundaries
  /// matching the AAMVA Data Design specifications.
  ParsedIdData _parseAamvaPayload(String rawText) {
    // Standard driver license records split lines using a standard line break or carriage return
    final List<String> dataLines = rawText.split(RegExp(r'[\r\n]+'));

    String idNumber = '';
    String lastName = '';
    String firstName = '';
    String middleName = '';
    String street = '';
    String city = '';
    String prov = '';
    String post = '';
    DateTime? dob;
    DateTime? expiry;

    for (var rawLine in dataLines) {
      final String line = rawLine.trim();
      if (line.length < 4) continue; // Skip unpopulated noise rows or header markers

      // Every operational element ID inside an AAMVA subfile has a 3-character designator code
      final String elementId = line.substring(0, 3).toUpperCase();
      final String elementValue = line.substring(3).trim();

      switch (elementId) {
        case 'DAQ': // Unique Identification/License Number
          idNumber = elementValue;
          break;
        case 'DCS': // Dynamic Last Name Field
          lastName = elementValue;
          break;
        case 'DAC': // Dynamic First Name Field
          firstName = elementValue;
          break;
        case 'DAD': // Dynamic Middle Name Field
          middleName = elementValue;
          break;
        case 'DAG': // Street Unit Delivery Info
          street = elementValue;
          break;
        case 'DAI': // Municipality/City Context
          city = elementValue;
          break;
        case 'DAJ': // State / Provincial Region Designation (e.g. 'BC')
          prov = elementValue;
          break;
        case 'DAK': // Postal Code / ZIP Code String
          post = elementValue;
          break;
        case 'DBB': // Date of Birth (AAMVA Standard: YYYYMMDD)
          dob = _parseAamvaDate(elementValue);
          break;
        case 'DBA': // Identification Document Expiration Date (YYYYMMDD)
          expiry = _parseAamvaDate(elementValue);
          break;
        case 'DAA':
        // Catch-all structural fallback: Some legacy jurisdictions map names as a comma-separated stream
        // e.g., DAALASTNAME,FIRSTNAME,MIDDLENAME
          final nameParts = elementValue.split(',');
          if (nameParts.isNotEmpty) lastName = nameParts[0].trim();
          if (nameParts.length > 1) firstName = nameParts[1].trim();
          if (nameParts.length > 2) middleName = nameParts[2].trim();
          break;
      }
    }

    return ParsedIdData(
      rawPayload: rawText,
      idNumber: idNumber,
      lastName: lastName,
      firstName: firstName,
      middleName: middleName,
      streetAddress: street,
      city: city,
      province: prov,
      postalCode: post,
      dateOfBirth: dob,
      expiryDate: expiry,
    );
  }

  /// Helper to safely process the fixed-width date patterns from the barcode
  DateTime? _parseAamvaDate(String rawDateString) {
    final cleanString = rawDateString.replaceAll(RegExp(r'\D'), ''); // Strip potential structural slashes
    if (cleanString.length != 8) return null;

    final int? year = int.tryParse(cleanString.substring(0, 4));
    final int? month = int.tryParse(cleanString.substring(4, 6));
    final int? day = int.tryParse(cleanString.substring(6, 8));

    if (year != null && month != null && day != null) {
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  /// Explicit destructor hook to release low-level memory footprint bindings
  void dispose() {
    _scanner.close();
  }
}