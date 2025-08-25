import 'dart:io';
import 'package:flutter/material.dart';
import 'package:student_verify/verification/student_verify.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
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
    if (_nameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty ||
        _idController.text.trim().isEmpty) {
      setState(() {
        _result = "❌ გთხოვთ შეავსოთ ყველა ველი!";
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
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
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
      appBar: AppBar(
        title: const Text("სტუდენტის ვერიფიკაცია"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "სახელი",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: "გვარი",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "პირადი ნომერი",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickPdfFile,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  _pdfFile == null ? "ატვირთეთ  ცნობა (PDF)" : "ფაილი არჩეულია",
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
