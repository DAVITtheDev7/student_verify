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
    required String name,
    required String surname,
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
        "სახელი": officialText.contains(name),
        "გვარი": officialText.contains(surname),
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
}
