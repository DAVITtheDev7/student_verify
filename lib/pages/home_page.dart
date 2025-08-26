import 'dart:io';
import 'package:flutter/material.dart';
import 'package:student_verify/verification/student_verify.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _idController = TextEditingController();

  File? _pdfFile;
  String _result = "";

  Future<void> _pickPdfFile() async {
    final file = await StudentVerify.pickPdfFile();
    setState(() {
      _pdfFile = file;
    });
  }

  Future<void> _verifyStudent() async {
    if (_idController.text.trim().isEmpty) {
      setState(() {
        _result = "❌ გთხოვთ შეიყვანოთ პირადი ნომერი!";
      });
      return;
    }

    if (_pdfFile == null) {
      setState(() {
        _result = "❌ გთხოვთ ატვირთოთ უნივერსიტეტის ცნობა (PDF)!";
      });
      return;
    }

    setState(() {
      _result = "⏳ გთხოვთ დაელოდოთ...";
    });
    final result = await StudentVerify.verifyStudentFromPdf(
      localPdf: _pdfFile!,
      id: _idController.text.trim(),
    );

    if (result["success"]) {
      setState(() {
        _result = "✅ ვერიფიკაცია წარმატებულია!";
      });
    } else {
      setState(() {
        _result = "❌ ვერიფიკაცია წარუმატებელია!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BSU - ვერიფიკაცია"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "პირადი ნომერი",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 11,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickPdfFile,
                icon: Icon(
                  Icons.picture_as_pdf,
                  color: _pdfFile == null ? Colors.black : Colors.white,
                ),
                label: Text(
                  _pdfFile == null ? "ატვირთეთ ცნობა (PDF)" : "ფაილი არჩეულია",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _pdfFile == null ? Colors.black : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: _pdfFile == null
                      ? Colors.white
                      : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyStudent,
                child: const Text("ვერიფიკაცია"),
              ),
              const SizedBox(height: 20),
              Text(
                _result,
                style: TextStyle(
                  fontSize: 16,
                  color: _result.contains("✅") ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
