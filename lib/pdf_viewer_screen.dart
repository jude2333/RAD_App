import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'api_service.dart';
import 'patient_list.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerPage extends StatefulWidget {
  final String file_path;
  final String accession_no;
  final String approve_status;
  final String radiology_id;
  final String emp_name;

  const PdfViewerPage({
    super.key,
    required this.file_path,
    required this.accession_no,
    required this.approve_status,
    required this.radiology_id,
    required this.emp_name,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfControllerPinch? _pdfController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.file_path));
      final bytes = response.bodyBytes;
      final filename = basename(widget.file_path);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(file.path),
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading PDF: $e');
    }
  }

  Future<void> _onApprove(BuildContext context) async {
    await APIService.updateData({
      "id": widget.radiology_id,
      "accession_no": widget.accession_no,
      "user": widget.emp_name,
      "type": "approve",
    });
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PatientList()),
    );
  }

  Future<void> _onDeny(BuildContext context) async {
    TextEditingController reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          content: SizedBox(
            width: 520, // Slightly wider, adjust as you like
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Hold Reason",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent[700],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(height: 0.4, color: Colors.grey),
                const SizedBox(height: 12),

                // Text field with fixed height and expanded width
                SizedBox(
                  height: 70,
                  width: double.infinity,
                  child: TextField(
                    controller: reasonController,
                    expands: true,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Enter a reason",
                      hintStyle: const TextStyle(),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blueAccent[600] ?? Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  Navigator.pop(context, reason);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      print(widget.emp_name);
      await APIService.updateData({
        "id": widget.radiology_id,
        "accession_no": widget.accession_no,
        "type": "hold",
        "user": widget.emp_name,
        "reason": result,
      });
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PatientList()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if ((widget.approve_status == "") ||
                    widget.approve_status == "2")
                  ElevatedButton(
                    onPressed: () => _onApprove(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Approve",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => _onDeny(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    "Hold",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading || _pdfController == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      PdfViewPinch(controller: _pdfController!),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: FutureBuilder<PdfDocument>(
                          future: _pdfController!.document,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            final totalPages = snapshot.data!.pagesCount;
                            return ValueListenableBuilder<int?>(
                              valueListenable: _pdfController!.pageListenable,
                              builder: (context, page, _) {
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Page ${page ?? 1} of $totalPages',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
