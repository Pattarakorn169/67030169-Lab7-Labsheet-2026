import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing_draft.dart';
import '../services/gemini_vision_service.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _image;

  ListingDraft? _draft;

  // ร่างประกาศฉบับสุดท้ายที่ผู้ใช้ยืนยันแล้ว
  ListingDraft? _confirmedDraft;

  bool _isAnalyzing = false;

  String? _errorMessage;

  // ช่องกรอกข้อมูลที่ AI แนะนำ
  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _categoryController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // =========================
  // เลือกรูปภาพสินค้า
  // =========================
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _image = File(pickedFile.path);

      _draft = null;
      _errorMessage = null;

      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  // =========================
  // วิเคราะห์รูปด้วย Gemini
  // =========================
  Future<void> _analyzeImage() async {
    if (_image == null) {
      setState(() {
        _errorMessage = 'กรุณาเลือกรูปภาพสินค้าก่อน';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _draft = null;
      _errorMessage = null;
    });

    try {
      final result =
          await GeminiVisionService().analyzeProductImage(_image!);

      if (!mounted) {
        return;
      }

      setState(() {
        _draft = result;
        _isAnalyzing = false;

        // นำข้อมูลจาก AI มาใส่ในช่องที่แก้ไขได้
        _titleController.text = result.title;
        _categoryController.text = result.category;
        _descriptionController.text = result.description;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  // =========================
  // ยืนยันร่างประกาศ
  // =========================
  void _confirmDraft() {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    // ตรวจสอบว่ากรอกครบหรือไม่
    if (title.isEmpty ||
        category.isEmpty ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณากรอกข้อมูลให้ครบทุกช่อง',
          ),
        ),
      );
      return;
    }

    // สร้างร่างประกาศจากค่าปัจจุบันใน TextField
    final finalDraft = ListingDraft(
      title: title,
      category: category,
      description: description,
    );

    setState(() {
      // เก็บร่างฉบับสุดท้ายไว้ใน State
      _confirmedDraft = finalDraft;

      // ล้างฟอร์มเพื่อเริ่มประกาศใหม่
      _image = null;
      _draft = null;
      _errorMessage = null;

      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกร่างประกาศเรียบร้อยแล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =========================
            // แสดงรูปภาพสินค้า
            // =========================
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // =========================
            // ปุ่มเลือกรูปภาพ
            // =========================
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text(
                'เลือกรูปภาพสินค้า',
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // ปุ่ม AI
            // =========================
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeImage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'ให้ AI ช่วยแนะนำ',
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // สถานะกำลังวิเคราะห์
            // =========================
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'AI กำลังวิเคราะห์ภาพสินค้า...',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

            // =========================
            // สถานะ Error
            // =========================
            if (_errorMessage != null && !_isAnalyzing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                  ),
                ),
              ),

            // =========================
            // ฟอร์มตรวจทานและแก้ไข
            // =========================
            if (_draft != null && !_isAnalyzing)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'ตรวจทานและแก้ไขข้อมูล',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'ข้อมูลที่ AI แนะนำสามารถแก้ไขได้ก่อนยืนยัน',
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // ชื่อประกาศ
                      // =========================
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อประกาศ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =========================
                      // หมวดหมู่
                      // =========================
                      TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'หมวดหมู่',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =========================
                      // คำบรรยาย
                      // =========================
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'คำบรรยาย',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // ปุ่มยืนยัน
                      // =========================
                      ElevatedButton.icon(
                        onPressed: _confirmDraft,
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'ยืนยันร่างประกาศ',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // =========================
            // แสดงร่างที่ยืนยันล่าสุด
            // =========================
            if (_confirmedDraft != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ร่างประกาศที่ยืนยันล่าสุด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'ชื่อประกาศ: ${_confirmedDraft!.title}',
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'หมวดหมู่: ${_confirmedDraft!.category}',
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'คำบรรยาย: ${_confirmedDraft!.description}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}