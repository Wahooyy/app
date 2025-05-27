import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import 'dart:math' as math;

class TicketSupportPage extends StatefulWidget {
  @override
  _TicketSupportPageState createState() => _TicketSupportPageState();
}

class _TicketSupportPageState extends State<TicketSupportPage> {
  final Color _primaryColor = Color(0xFF6200EE);

  // Dummy ticket data
  List<Map<String, dynamic>> _tickets = [
    {
      'title': 'Monitor tidak menyala',
      'category': 'Hardware',
      'subCategory': 'Perbaikan',
      'priority': 'High',
      'status': 'Open',
      'date': '2024-06-01',
    },
    {
      'title': 'Permintaan pemasangan WiFi',
      'category': 'Hardware',
      'subCategory': 'Pemasangan',
      'priority': 'Medium',
      'status': 'Closed',
      'date': '2024-05-28',
    },
    {
      'title': 'Aplikasi error saat login',
      'category': 'Software',
      'subCategory': '',
      'priority': 'Critical',
      'status': 'Open',
      'date': '2024-05-27',
    },
  ];

  // Ticket form fields
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _whatsapp;
  String? _title;
  String? _description;
  String? _category;
  String? _subCategory;
  String? _subSubCategory;
  String? _priority;
  File? _imageFile;

  // Dropdown options
  final List<String> _categories = ['Hardware', 'Software'];
  final List<String> _hardwareSubCategories = ['Perbaikan', 'Pemasangan', 'Penggantian'];
  final List<String> _perbaikanSubSub = ['Komputer', 'Printer', 'Monitor'];
  final List<String> _pemasanganSubSub = ['WiFi', 'Jaringan'];
  final List<String> _penggantianSubSub = ['Mouse', 'Keyboard'];
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  // Add state for comments and technician
  Map<int, List<Map<String, dynamic>>> _ticketComments = {};
  Map<int, String?> _ticketTechnician = {};
  final List<String> _technicians = ['Budi', 'Siti', 'Andi', 'Rina'];
  File? _commentImage;
  final _commentController = TextEditingController();

  void _showCreateTicketSheet() {
    setState(() {
      _name = null;
      _whatsapp = null;
      _title = null;
      _description = null;
      _category = null;
      _subCategory = null;
      _subSubCategory = null;
      _priority = null;
      _imageFile = null;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildTicketForm(),
      ),
    );
  }

  Widget _buildTicketForm() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 28,
            cornerSmoothing: 1,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Buat Tiket Baru',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 18),
              _buildTextField('Nama', (v) => _name = v),
              SizedBox(height: 12),
              _buildTextField('WhatsApp', (v) => _whatsapp = v, keyboardType: TextInputType.phone),
              SizedBox(height: 12),
              _buildTextField('Judul', (v) => _title = v),
              SizedBox(height: 12),
              _buildTextField('Deskripsi', (v) => _description = v, maxLines: 3),
              SizedBox(height: 12),
              // Category
              _buildCustomModalField(
                label: 'Kategori',
                value: _category,
                enabled: true,
                placeholder: 'Pilih Kategori',
                options: _categories,
                onSelected: (val) {
                  setState(() {
                    _category = val;
                    _subCategory = null;
                    _subSubCategory = null;
                  });
                },
              ),
              SizedBox(height: 12),
              // Sub Kategori
              _buildCustomModalField(
                label: 'Sub Kategori',
                value: _subCategory,
                enabled: _category == 'Hardware',
                placeholder: _category == 'Hardware' ? 'Pilih Sub Kategori' : 'Tidak ada sub kategori',
                options: _category == 'Hardware' ? _hardwareSubCategories : [],
                onSelected: (val) {
                  setState(() {
                    _subCategory = val;
                    _subSubCategory = null;
                  });
                },
              ),
              SizedBox(height: 12),
              // Sub Sub Kategori
              _buildCustomModalField(
                label: 'Sub Sub Kategori',
                value: _subSubCategory,
                enabled: _category == 'Hardware' && _subCategory != null,
                placeholder: (_category == 'Hardware' && _subCategory != null) ? 'Pilih Sub Sub Kategori' : 'Tidak ada sub sub kategori',
                options: _category == 'Hardware'
                    ? (_subCategory == 'Perbaikan'
                        ? _perbaikanSubSub
                        : _subCategory == 'Pemasangan'
                            ? _pemasanganSubSub
                            : _subCategory == 'Penggantian'
                                ? _penggantianSubSub
                                : [])
                    : [],
                onSelected: (val) {
                  setState(() {
                    _subSubCategory = val;
                  });
                },
              ),
              SizedBox(height: 12),
              // Priority
              _buildCustomModalField(
                label: 'Prioritas',
                value: _priority,
                enabled: true,
                placeholder: 'Pilih Prioritas',
                options: _priorities,
                onSelected: (val) => setState(() => _priority = val),
              ),
              SizedBox(height: 12),
              _buildImagePicker(),
              SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 14,
                        cornerSmoothing: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // Add ticket to list (dummy)
                      setState(() {
                        _tickets.insert(0, {
                          'title': _title,
                          'category': _category,
                          'subCategory': _subCategory,
                          'subSubCategory': _subSubCategory,
                          'priority': _priority,
                          'status': 'Open',
                          'date': DateTime.now().toString().substring(0, 10),
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Kirim Tiket', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
      onSaved: onSaved,
    );
  }

  Widget _buildImagePicker() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // TODO: Implement image picker
            },
            child: SizedBox(
              height: 110,
              child: CustomPaint(
                painter: _DottedSmoothBorderPainter(
                  color: Colors.grey.shade300,
                  borderRadius: 14,
                  dotSpacing: 6,
                  dotRadius: 1.5,
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 14,
                    cornerSmoothing: 1,
                  ),
                  child: Container(
                    color: Colors.white,
                    child: _imageFile == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(HugeIcons.strokeRoundedImage01, color: _primaryColor, size: 32),
                                SizedBox(height: 8),
                                Text('Upload Foto', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
                                SizedBox(height: 4),
                                Text('Format: JPG, PNG. Max 2MB', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  width: double.infinity,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageFile = null;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  padding: EdgeInsets.all(2),
                                  margin: EdgeInsets.all(6),
                                  child: Icon(Icons.close, size: 16, color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTicketDetail(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildTicketDetail(index),
      ),
    );
  }

  Widget _buildTicketDetail(int index) {
    final ticket = _tickets[index];
    final comments = _ticketComments[index] ?? [];
    String? technician = _ticketTechnician[index];
    bool showTechnician = (ticket['status'] == 'In Progress' && technician != null && technician.isNotEmpty);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 28,
            cornerSmoothing: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(ticket['title'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(HugeIcons.strokeRoundedFile01, color: _primaryColor, size: 18),
                SizedBox(width: 8),
                Text(ticket['category'] ?? '-', style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54)),
                if (ticket['subCategory'] != null && ticket['subCategory'] != '') ...[
                  SizedBox(width: 12),
                  Icon(HugeIcons.strokeRoundedFile01, color: _primaryColor, size: 18),
                  SizedBox(width: 4),
                  Text(ticket['subCategory'] ?? '-', style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54)),
                ],
                if (ticket['subSubCategory'] != null && ticket['subSubCategory'] != '') ...[
                  SizedBox(width: 12),
                  Icon(HugeIcons.strokeRoundedFile01, color: _primaryColor, size: 18),
                  SizedBox(width: 4),
                  Text(ticket['subSubCategory'] ?? '-', style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54)),
                ],
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(HugeIcons.strokeRoundedCalendarRemove01, color: Colors.grey[400], size: 16),
                SizedBox(width: 6),
                Text(ticket['date'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                SizedBox(width: 16),
                Icon(HugeIcons.strokeRoundedInformationCircle, color: Colors.grey[400], size: 16),
                SizedBox(width: 6),
                Text(ticket['status'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                SizedBox(width: 16),
                Icon(HugeIcons.strokeRoundedInformationCircle, color: _getPriorityColor(ticket['priority']), size: 16),
                SizedBox(width: 6),
                Text(ticket['priority'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: _getPriorityColor(ticket['priority']))),
              ],
            ),
            SizedBox(height: 16),
            Text('Teknisi:', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(HugeIcons.strokeRoundedUser03, color: Colors.grey[400], size: 18),
                SizedBox(width: 8),
                Text(
                  showTechnician ? technician ?? '' : 'Belum ada teknisi',
                  style: GoogleFonts.outfit(fontSize: 14, color: showTechnician ? Colors.black87 : Colors.black38, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 18),
            Text('Komentar:', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 10),
            Container(
              constraints: BoxConstraints(maxHeight: 220),
              child: comments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('Belum ada komentar.', style: GoogleFonts.outfit(color: Colors.black54, fontSize: 13))),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade100, width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: _primaryColor.withOpacity(0.08),
                                child: Icon(HugeIcons.strokeRoundedUser03, color: _primaryColor, size: 18),
                                radius: 18,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['text'] ?? '', style: GoogleFonts.outfit(fontSize: 13)),
                                    if (c['image'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(c['image'], width: 80, height: 80, fit: BoxFit.cover),
                                        ),
                                      ),
                                    SizedBox(height: 4),
                                    Text(c['time'] ?? '', style: GoogleFonts.outfit(fontSize: 11, color: Colors.black45)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 14),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 14,
                    cornerSmoothing: 1,
                  ),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: GoogleFonts.outfit(),
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...'
                            ,
                        filled: true,
                        fillColor: Colors.white,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: Icon(HugeIcons.strokeRoundedImage01, color: _primaryColor),
                    onPressed: () {
                      // TODO: Implement image picker for comment
                    },
                  ),
                  IconButton(
                    icon: Icon(HugeIcons.strokeRoundedSent, color: _primaryColor),
                    onPressed: () {
                      final text = _commentController.text.trim();
                      if (text.isNotEmpty || _commentImage != null) {
                        setState(() {
                          _ticketComments[index] = [
                            ...comments,
                            {
                              'text': text,
                              'image': _commentImage,
                              'time': DateTime.now().toString().substring(0, 16).replaceAll('T', ' '),
                            }
                          ];
                          _commentController.clear();
                          _commentImage = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    int index = _tickets.indexOf(ticket);
    return GestureDetector(
      onTap: () => _showTicketDetail(index),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(18),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 20,
              cornerSmoothing: 1,
            ),
            side: BorderSide(
              color: Colors.grey.shade100,
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedFile01,
                  color: _primaryColor,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ticket['title'] ?? '-',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: ShapeDecoration(
                    color: _getPriorityColor(ticket['priority']).withOpacity(0.13),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 8,
                        cornerSmoothing: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    ticket['priority'] ?? '-',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(ticket['priority']),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(HugeIcons.strokeRoundedCalendarRemove01, color: Colors.grey[400], size: 16),
                SizedBox(width: 6),
                Text(ticket['date'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                SizedBox(width: 16),
                Icon(HugeIcons.strokeRoundedInformationCircle, color: Colors.grey[400], size: 16),
                SizedBox(width: 6),
                Text(ticket['status'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
              ],
            ),
            if (ticket['category'] == 'Hardware' && ticket['subCategory'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(HugeIcons.strokeRoundedFile01, color: Colors.grey[400], size: 16),
                    SizedBox(width: 6),
                    Text(ticket['subCategory'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                    if (ticket['subSubCategory'] != null) ...[
                      SizedBox(width: 12),
                      Icon(HugeIcons.strokeRoundedFile01, color: Colors.grey[400], size: 16),
                      SizedBox(width: 6),
                      Text(ticket['subSubCategory'] ?? '-', style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54)),
                    ]
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.amber[700]!;
      case 'High':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return _primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Dukungan Tiket',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _tickets.length,
          itemBuilder: (context, index) => _buildTicketCard(_tickets[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketSheet,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 1,
          ),
        ),
        icon: Icon(HugeIcons.strokeRoundedAddSquare, size: 22),
        label: Text('Buat Tiket', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCustomModalField({
    required String label,
    required String? value,
    required bool enabled,
    required String placeholder,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () async {
              final selected = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => _buildOptionSheet(label, options, value),
              );
              if (selected != null) onSelected(selected);
            }
          : null,
      child: AbsorbPointer(
        child: TextFormField(
          style: GoogleFonts.outfit(),
          readOnly: true,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.outfit(color: Colors.black54),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Icon(HugeIcons.strokeRoundedArrowDown01, color: Colors.black54),
          ),
          controller: TextEditingController(text: value ?? ''),
          validator: (v) => (enabled && (v == null || v.isEmpty)) ? 'Wajib dipilih' : null,
        ),
      ),
    );
  }

  Widget _buildOptionSheet(String label, List<String> options, String? value) {
    return Container(
      padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 28,
            cornerSmoothing: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Pilih $label', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          ...options.map((e) => InkWell(
                onTap: () => Navigator.pop(context, e),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: value == e ? _primaryColor.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: value == e ? _primaryColor : Colors.grey.shade100,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(e, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black87))),
                      if (value == e)
                        Icon(Icons.check_circle, color: _primaryColor, size: 20),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// Custom painter for dotted smooth border
class _DottedSmoothBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dotSpacing;
  final double dotRadius;
  _DottedSmoothBorderPainter({
    required this.color,
    required this.borderRadius,
    this.dotSpacing = 6,
    this.dotRadius = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final pos = metric.getTangentForOffset(distance);
        if (pos != null) {
          canvas.drawCircle(pos.position, dotRadius, paint);
        }
        distance += dotSpacing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 