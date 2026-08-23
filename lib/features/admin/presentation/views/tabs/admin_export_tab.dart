import 'package:flutter/material.dart';

class AdminExportTab extends StatelessWidget {
  const AdminExportTab({
    required this.onExportExcel,
    required this.onExportPdf,
    super.key,
  });

  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'تصدير قوائم الطلاب والنقاط إلى Excel أو PDF.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onExportExcel,
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('تصدير Excel'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onExportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('تصدير PDF'),
        ),
      ],
    );
  }
}
