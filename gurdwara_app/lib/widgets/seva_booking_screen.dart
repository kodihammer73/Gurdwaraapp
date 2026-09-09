import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SevaBookingScreen extends StatefulWidget {
  const SevaBookingScreen({super.key});

  @override
  State<SevaBookingScreen> createState() => _SevaBookingScreenState();
}

class _SevaBookingScreenState extends State<SevaBookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = Dio();
  static const String _apiUrl = 'https://www.gurdwarasahibmelaka.com/api/submit_request.php';
  static const String _trackUrl = 'https://www.gurdwarasahibmelaka.com/api/track_request.php';

  final _langarFormKey = GlobalKey<FormState>();
  final _langarNameController = TextEditingController();
  final _langarPhoneController = TextEditingController();
  final _langarPasscodeController = TextEditingController();
  final _langarNotesController = TextEditingController();
  DateTime? _selectedLangarDate;
  String _selectedMeal = 'Lunch';

  final _bookingFormKey = GlobalKey<FormState>();
  final _bookingNameController = TextEditingController();
  final _bookingPhoneController = TextEditingController();
  final _bookingPasscodeController = TextEditingController();
  final _bookingNotesController = TextEditingController();
  DateTime? _selectedBookingDate;
  String _selectedEventType = 'Akhand Path';

  final _ardasFormKey = GlobalKey<FormState>();
  final _ardasNameController = TextEditingController();
  final _ardasPhoneController = TextEditingController();
  final _ardasPasscodeController = TextEditingController();
  final _ardasDetailsController = TextEditingController();

  // Track My Request state
  final _trackFormKey = GlobalKey<FormState>();
  final _trackPhoneController = TextEditingController();
  final _trackPasscodeController = TextEditingController();
  List<Map<String, dynamic>>? _trackResults;
  String? _trackError;
  bool _isTracking = false;

  bool _isSubmitting = false;

  /// Validator: exactly 4 digits.
  String? _passcodeValidator(String? v) =>
      (v == null || !RegExp(r'^\d{4}$').hasMatch(v.trim())) ? 'Enter exactly 4 digits' : null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _langarNameController.dispose();
    _langarPhoneController.dispose();
    _langarPasscodeController.dispose();
    _langarNotesController.dispose();
    _bookingNameController.dispose();
    _bookingPhoneController.dispose();
    _bookingPasscodeController.dispose();
    _bookingNotesController.dispose();
    _ardasNameController.dispose();
    _ardasPhoneController.dispose();
    _ardasPasscodeController.dispose();
    _ardasDetailsController.dispose();
    _trackPhoneController.dispose();
    _trackPasscodeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm({
    required GlobalKey<FormState> formKey,
    required Map<String, dynamic> payload,
  }) async {
    if (!formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final response = await _dio.post(_apiUrl, data: payload);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.data != null && response.data['success'] == true) {
        _showSuccessDialog(response.data['request_id'] ?? 'REQ');
        formKey.currentState!.reset();
      } else {
        _showErrorSnackBar(response.data['message'] ?? 'Failed to submit request.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Network error. Please check your connection.');
    }
  }

  void _showSuccessDialog(String reqId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Submitted'),
        content: Text('Your request has been received. You can check its status anytime in the Track tab using your mobile number and the 4-digit passcode you chose.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _lookupRequest() async {
    final phone = _trackPhoneController.text.trim();
    final passcode = _trackPasscodeController.text.trim();
    if (phone.isEmpty) {
      _showErrorSnackBar('Please enter your mobile number');
      return;
    }
    if (_passcodeValidator(passcode) != null) {
      _showErrorSnackBar('Please enter your 4-digit passcode');
      return;
    }
    setState(() {
      _isTracking = true;
      _trackResults = null;
      _trackError = null;
    });

    try {
      final query = 'phone=${Uri.encodeComponent(phone)}&passcode=${Uri.encodeComponent(passcode)}';
      final response = await _dio.get<String>(
        '$_trackUrl?$query',
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final raw = response.data ?? '';
      Map<String, dynamic>? decoded;
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) decoded = json;
      } catch (_) {
        // Non-JSON body (e.g. server error page) â€” fall through to generic handling
      }
      if (!mounted) return;

      List<Map<String, dynamic>>? results;
      if (decoded != null && decoded['success'] == true) {
        if (decoded['requests'] is List) {
          results = (decoded['requests'] as List)
              .whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList();
        } else if (decoded['request'] is Map<String, dynamic>) {
          results = [(decoded['request'] as Map<String, dynamic>).cast<String, dynamic>()];
        }
      }

      if (results != null && results.isNotEmpty) {
        setState(() {
          _trackResults = results;
          _isTracking = false;
        });
      } else if (decoded != null && (decoded['message'] as String?)?.isNotEmpty == true) {
        // Our API's own 404 "No requests found..." etc.
        setState(() {
          _trackError = decoded?['message'] as String? ?? 'No matching requests found.';
          _isTracking = false;
        });
      } else {
        setState(() {
          _trackError = 'Tracking service is temporarily unavailable. Please try again later.';
          _isTracking = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          msg = 'Request timed out. Please check your connection and try again.';
          break;
        case DioExceptionType.connectionError:
          msg = 'No internet connection. Please check your network and try again.';
          break;
        default:
          // HTTP error statuses: if the server returned OUR JSON (e.g. 404
          // "No request found with that ID."), show its message; otherwise the
          // endpoint itself is missing/broken (HTML error page, 500, etc.).
          final body = e.response?.data;
          String? apiMessage;
          if (body is String) {
            try {
              final json = jsonDecode(body);
              if (json is Map<String, dynamic> && json['message'] is String) {
                apiMessage = json['message'] as String;
              }
            } catch (_) {}
          }
          msg = apiMessage ??
              'Tracking service is temporarily unavailable. Please try again later.';
      }
      setState(() {
        _trackError = msg;
        _isTracking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trackError = 'Something went wrong. Please try again later.';
        _isTracking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: const Color(0xFF1B365D),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE8A838),
          labelColor: const Color(0xFFE8A838),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Langar'),
            Tab(icon: Icon(Icons.event), text: 'Booking'),
            Tab(icon: Icon(Icons.volunteer_activism), text: 'Ardas'),
            Tab(icon: Icon(Icons.manage_search), text: 'Track'),
          ],
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLangarTab(),
                _buildBookingTab(),
                _buildArdasTab(),
                _buildTrackTab(),
              ],
            ),
    );
  }

  Widget _buildLangarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _langarFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sponsor Langar Seva',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _langarNameController,
              decoration: const InputDecoration(labelText: 'Sponsor Family / Name *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _langarPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone Number *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _langarPasscodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: '4-Digit Passcode *',
                helperText: 'Choose any 4 digits to track your request later',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: _passcodeValidator,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              title: Text(_selectedLangarDate == null ? 'Select Seva Date *' : 'Date: ${_selectedLangarDate!.day}/${_selectedLangarDate!.month}/${_selectedLangarDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _selectedLangarDate = d);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMeal,
              decoration: const InputDecoration(labelText: 'Meal Type', border: OutlineInputBorder()),
              items: ['Breakfast', 'Lunch', 'Tea', 'Dinner', 'Full Day'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _selectedMeal = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _langarNotesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes / Occasion', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: const Color(0xFF1B365D), foregroundColor: const Color(0xFFE8A838)),
              onPressed: () {
                if (_selectedLangarDate == null) { _showErrorSnackBar('Select a date'); return; }
                _submitForm(formKey: _langarFormKey, payload: {
                  'type': 'langar',
                  'name': _langarNameController.text.trim(),
                  'phone': _langarPhoneController.text.trim(),
                  'passcode': _langarPasscodeController.text.trim(),
                  'date': '${_selectedLangarDate!.year}-${_selectedLangarDate!.month.toString().padLeft(2, '0')}-${_selectedLangarDate!.day.toString().padLeft(2, '0')}',
                  'meal_type': _selectedMeal,
                  'notes': _langarNotesController.text.trim(),
                });
              },
              child: const Text('Submit Langar Request'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _bookingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hall & Path Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookingNameController,
              decoration: const InputDecoration(labelText: 'Applicant Name *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookingPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookingPasscodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: '4-Digit Passcode *',
                helperText: 'Choose any 4 digits to track your request later',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: _passcodeValidator,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedEventType,
              decoration: const InputDecoration(labelText: 'Booking Category', border: OutlineInputBorder()),
              items: ['Akhand Path', 'Sehaj Path', 'Anand Karaj', 'Smagam', 'Hall Booking'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedEventType = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              title: Text(_selectedBookingDate == null ? 'Select Booking Date *' : 'Target Date: ${_selectedBookingDate!.day}/${_selectedBookingDate!.month}/${_selectedBookingDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _selectedBookingDate = d);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookingNotesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Details / Special Requests', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: const Color(0xFF1B365D), foregroundColor: const Color(0xFFE8A838)),
              onPressed: () {
                if (_selectedBookingDate == null) { _showErrorSnackBar('Select a target date'); return; }
                _submitForm(formKey: _bookingFormKey, payload: {
                  'type': 'booking',
                  'name': _bookingNameController.text.trim(),
                  'phone': _bookingPhoneController.text.trim(),
                  'passcode': _bookingPasscodeController.text.trim(),
                  'date': '${_selectedBookingDate!.year}-${_selectedBookingDate!.month.toString().padLeft(2, '0')}-${_selectedBookingDate!.day.toString().padLeft(2, '0')}',
                  'event_type': _selectedEventType,
                  'notes': _bookingNotesController.text.trim(),
                });
              },
              child: const Text('Submit Booking Request'),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildArdasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _ardasFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Online Ardas Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ardasNameController,
              decoration: const InputDecoration(labelText: 'Name / Family Name *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ardasPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ardasPasscodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: '4-Digit Passcode *',
                helperText: 'Choose any 4 digits to track your request later',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: _passcodeValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ardasDetailsController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ardas Details & Occasion *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter details' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: const Color(0xFF1B365D), foregroundColor: const Color(0xFFE8A838)),
              onPressed: () {
                _submitForm(formKey: _ardasFormKey, payload: {
                  'type': 'ardas',
                  'name': _ardasNameController.text.trim(),
                  'phone': _ardasPhoneController.text.trim(),
                  'passcode': _ardasPasscodeController.text.trim(),
                  'notes': _ardasDetailsController.text.trim(),
                });
              },
              child: const Text('Submit Ardas Request'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _trackFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track My Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D)),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the mobile number and the 4-digit passcode you chose when submitting a Langar, Hall Booking or Ardas request. All matching requests will be shown.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trackPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your mobile number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trackPasscodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: '4-Digit Passcode *',
                border: OutlineInputBorder(),
                counterText: '',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: _passcodeValidator,
              onFieldSubmitted: (_) => _lookupRequest(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF1B365D),
                foregroundColor: const Color(0xFFE8A838),
              ),
              onPressed: _isTracking ? null : _lookupRequest,
              icon: const Icon(Icons.search),
              label: const Text('Check Status'),
            ),
            const SizedBox(height: 24),
            if (_isTracking) const Center(child: CircularProgressIndicator()),
            if (!_isTracking && _trackError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_trackError!, style: TextStyle(color: Colors.red.shade700))),
                  ],
                ),
              ),
            if (!_isTracking && _trackResults != null && _trackResults!.isNotEmpty) ...[
              Text(
                '${_trackResults!.length} request${_trackResults!.length == 1 ? '' : 's'} found',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ..._trackResults!.map(_buildTrackResultCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackResultCard(Map<String, dynamic> r) {
    final status = (r['status'] as String? ?? 'pending').toLowerCase();
    final isDone = status == 'completed' || status == 'approved';
    final statusColor = isDone ? Colors.green.shade700 : (status == 'rejected' ? Colors.red.shade700 : Colors.orange.shade800);
    final typeLabel = (r['type'] as String? ?? '').isEmpty
        ? ''
        : r['type'].toString()[0].toUpperCase() + r['type'].toString().substring(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isDone ? Icons.check_circle : Icons.hourglass_top, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _trackRow('Request ID', r['id']),
          if (typeLabel.isNotEmpty) _trackRow('Type', typeLabel),
          if ((r['name'] as String? ?? '').isNotEmpty) _trackRow('Name', r['name']),
          if ((r['date'] as String? ?? '').isNotEmpty) _trackRow('Requested Date', r['date']),
          if ((r['meal_type'] as String? ?? '').isNotEmpty) _trackRow('Meal', r['meal_type']),
          if ((r['event_type'] as String? ?? '').isNotEmpty) _trackRow('Event', r['event_type']),
          if ((r['notes'] as String? ?? '').isNotEmpty) _trackRow('Notes', r['notes']),
          if ((r['admin_remark'] as String? ?? '').isNotEmpty) _trackRow('Committee Remark', r['admin_remark']),
          if ((r['created_at'] as String? ?? '').isNotEmpty) _trackRow('Submitted', r['created_at']),
        ],
      ),
    );
  }

  Widget _trackRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(value.toString(), style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
