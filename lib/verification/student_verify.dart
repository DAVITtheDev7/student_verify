import 'dart:io';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class StudentVerify {
  static Future<File?> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  static Future<String?> readPdfText(File pdfFile) async {
    try {
      return await ReadPdfText.getPDFtext(pdfFile.path);
    } catch (e) {
      return null;
    }
  }

  static String? extractVerificationLink(String pdfText) {
    final regex = RegExp(
      r'https:\/\/portal\.bsu\.edu\.ge\/doc\.php\?key=[^\s]+',
    );
    final match = regex.firstMatch(pdfText);
    return match?.group(0);
  }

  static Future<Map<String, dynamic>> verifyStudentFromPdf({
    required File localPdf,
    required String id,
  }) async {
    final localText = await readPdfText(localPdf);
    if (localText == null || localText.isEmpty) {
      return {
        "success": false,
        "reason": "ატვირთული PDF-დან ტექსტის წაკითხვა ვერ მოხერხდა",
      };
    }

    final link = extractVerificationLink(localText);
    if (link == null) {
      return {
        "success": false,
        "reason": "ვერიფიკაციის ლინკი PDF-ში ვერ მოიძებნა",
      };
    }

    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode != 200) {
        return {"success": false, "reason": "ოფიციალური PDF ვერ მოიძებნა"};
      }

      final tempFile = File("${Directory.systemTemp.path}/official.pdf");
      await tempFile.writeAsBytes(response.bodyBytes);

      final officialText = await readPdfText(tempFile);
      if (officialText == null || officialText.isEmpty) {
        return {"success": false, "reason": "ოფიციალური PDF ვერ წაიკითხა"};
      }

      final conditions = {
        "პირადი ნომერი": officialText.contains(id),
        "'სტუდენტი'": officialText.contains("სტუდენტი"),
      };

      final missing = conditions.entries
          .where((entry) => entry.value == false)
          .map((entry) => entry.key)
          .toList();

      return {
        "success": missing.isEmpty,
        "reason": missing.isEmpty
            ? "სტუდენტი ვერიფიცირებულია"
            : "ვერ მოიძებნა: ${missing.join(', ')}",
      };
    } catch (e) {
      return {"success": false, "reason": "შეცდომა: $e"};
    }
  }

  static Map<String, String?> extractStudentData(String text) {
    final nameRegex = RegExp(r"ეძლევა\s([ა-ჰ\s]+)ს\s\(");
    final nameMatch = nameRegex.firstMatch(text);
    final name = nameMatch?.group(1)?.trim();

    final idRegex = RegExp(r"პირადი ნომერი:\s(\d+)");
    final idMatch = idRegex.firstMatch(text);
    final id = idMatch?.group(1);

    final birthRegex = RegExp(r"დაბადების თარიღი:\s([\d\.]+)");
    final birthMatch = birthRegex.firstMatch(text);
    final birthday = birthMatch?.group(1);

    return {"name": name, "id": id, "birthday": birthday};
  }

  static bool isPdfValid(String text) {
    final regex = RegExp(r'ცნობა ძალაშია.*?(\d{2}\.\d{2}\.\d{4})-მდე');
    final match = regex.firstMatch(text);
    if (match == null) return false;

    final dateParts = match.group(1)!.split('.');
    final expiryDate = DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[0]), // day
    );

    final today = DateTime.now();
    return today.isBefore(expiryDate) || today.isAtSameMomentAs(expiryDate);
  }
}
