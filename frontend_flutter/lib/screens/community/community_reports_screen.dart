import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/community_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_report_service.dart';
import 'illegal_dumping_report_screen.dart';
import 'map_location_picker_screen.dart';
import 'report_detail_screen.dart';

class CommunityReportsScreen extends StatefulWidget {
  const CommunityReportsScreen({super.key});

  @override
  State<CommunityReportsScreen> createState() => _CommunityReportsScreenState();
}

class _CommunityReportsScreenState extends State<CommunityReportsScreen>
    with TickerProviderStateMixin {
  final CommunityReportService _service = CommunityReportService();
  List<CommunityReport> _reports = [];
  bool _loading = true;
  String? _error;

  late TabController _outerTabController; // 2 tabs: My Reports, Community
  late TabController _myReportsTabController; // 3 tabs: Report Issue, In Progress, Resolved
  late TabController _communityTabController; // 2 tabs: In Progress, Resolved

  @override
  void initState() {
    super.initState();
    _outerTabController = TabController(length: 2, vsync: this);
    _myReportsTabController = TabController(length: 3, vsync: this);
    _communityTabController = TabController(length: 2, vsync: this);

    _outerTabController.addListener(_onTabChanged);
    _myReportsTabController.addListener(_onTabChanged);
    _communityTabController.addListener(_onTabChanged);

    _load();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _outerTabController.removeListener(_onTabChanged);
    _myReportsTabController.removeListener(_onTabChanged);
    _communityTabController.removeListener(_onTabChanged);
    _outerTabController.dispose();
    _myReportsTabController.dispose();
    _communityTabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await _service.getReports();
      setState(() => _reports = reports);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isMyReport(CommunityReport r, String currentUserId) {
    if (currentUserId.isEmpty) return false;
    return r.reporter.id.trim() == currentUserId.trim();
  }

  List<CommunityReport> _myReports(String currentUserId) =>
      _reports.where((r) => _isMyReport(r, currentUserId)).toList();

  List<CommunityReport> _communityReports(String currentUserId) =>
      _reports.where((r) => !_isMyReport(r, currentUserId)).toList();

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.watch<AuthProvider>().user?.id ?? '';
    final myReportsList = _myReports(currentUserId);
    final communityReportsList = _communityReports(currentUserId);

    final isFormActive =
        _outerTabController.index == 0 && _myReportsTabController.index == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('🚨 Community Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _outerTabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 8),
                  Text('My Reports (${myReportsList.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.public, size: 18),
                  const SizedBox(width: 8),
                  Text('Community (${communityReportsList.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isFormActive
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                _outerTabController.animateTo(0);
                _myReportsTabController.animateTo(0);
              },
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Report Issue'),
            ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _outerTabController,
                  children: [
                    _buildMyReportsSection(currentUserId, myReportsList),
                    _buildCommunitySection(currentUserId, communityReportsList),
                  ],
                ),
    );
  }

  Widget _buildMyReportsSection(
      String currentUserId, List<CommunityReport> myReports) {
    final myInProgress =
        myReports.where((r) => r.status != 'resolved').toList();
    final myResolved =
        myReports.where((r) => r.status == 'resolved').toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _myReportsTabController,
            indicator: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade700,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            dividerColor: Colors.transparent,
            tabs: [
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 14),
                    SizedBox(width: 4),
                    Text('Report Issue'),
                  ],
                ),
              ),
              Tab(text: 'In Progress (${myInProgress.length})'),
              Tab(text: 'Resolved (${myResolved.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _myReportsTabController,
            children: [
              // Tab 1: Embedded Report Form
              RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF2E7D32),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  child: _EmbeddedReportForm(
                    onSuccess: () {
                      _load();
                      _myReportsTabController.animateTo(1);
                    },
                    onCancel: () {
                      _myReportsTabController.animateTo(1);
                    },
                  ),
                ),
              ),
              // Tab 2: In Progress
              _buildList(myInProgress, currentUserId, 'in progress',
                  isMySection: true),
              // Tab 3: Resolved
              _buildList(myResolved, currentUserId, 'resolved',
                  isMySection: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunitySection(
      String currentUserId, List<CommunityReport> communityReports) {
    final communityInProgress =
        communityReports.where((r) => r.status != 'resolved').toList();
    final communityResolved =
        communityReports.where((r) => r.status == 'resolved').toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _communityTabController,
            indicator: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade700,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'In Progress (${communityInProgress.length})'),
              Tab(text: 'Resolved (${communityResolved.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _communityTabController,
            children: [
              // Tab 1: In Progress Community Reports
              _buildList(communityInProgress, currentUserId, 'in progress',
                  isMySection: false),
              // Tab 2: Resolved Community Reports
              _buildList(communityResolved, currentUserId, 'resolved',
                  isMySection: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<CommunityReport> reports, String currentUserId,
      String statusLabel, {required bool isMySection}) {
    if (reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMySection
                    ? Icons.assignment_outlined
                    : Icons.check_circle_outline,
                size: 56,
                color: isMySection ? Colors.grey : const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 14),
              Text(
                isMySection
                    ? 'No $statusLabel reports submitted by you'
                    : 'No $statusLabel community reports found',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMySection
                    ? 'Reports you create for illegal dumping, bin overflow, or waste issues will show here.'
                    : 'Reports submitted by neighbors in your area will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
        itemCount: reports.length,
        itemBuilder: (ctx, i) => _ReportCard(
          report: reports[i],
          currentUserId: currentUserId,
          onUpvote: () async {
            try {
              await _service.toggleUpvote(reports[i].id);
              _load();
            } catch (_) {}
          },
          onAddInfo: () => _showAddInfoDialog(reports[i]),
          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    IllegalDumpingReportScreen(initialReport: reports[i]),
              ),
            );
            if (result == true) _load();
          },
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(report: reports[i]),
              ),
            );
            if (result == true) _load();
          },
        ),
      ),
    );
  }

  Future<void> _showAddInfoDialog(CommunityReport report) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Information'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add more details about this report...',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              try {
                await _service.addAdditionalInfo(report.id,
                    text: ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(
                          e.toString().replaceFirst('Exception: ', ''))));
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final CommunityReport report;
  final String currentUserId;
  final VoidCallback onUpvote;
  final VoidCallback onAddInfo;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _ReportCard({
    required this.report,
    required this.currentUserId,
    required this.onUpvote,
    required this.onAddInfo,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isUpvoted =
        report.upvotes.contains(currentUserId);
    final canEdit = currentUserId.isNotEmpty &&
        report.reporter.id.trim() == currentUserId.trim() &&
        report.status != 'resolved';

    final typeColors = {
      'illegal_dumping': Colors.red,
      'overflow': Colors.orange,
      'contamination': Colors.purple,
      'other': Colors.grey,
    };
    final typeLabels = {
      'illegal_dumping': '🗑️ Illegal Dumping',
      'overflow': '⚠️ Overflow',
      'contamination': '☢️ Contamination',
      'other': '❓ Other',
    };
    final color = typeColors[report.type] ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          typeLabels[report.type] ?? report.type,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (currentUserId.isNotEmpty &&
                          report.reporter.id.trim() == currentUserId.trim())
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2E7D32)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 12, color: Color(0xFF2E7D32)),
                              SizedBox(width: 4),
                              Text(
                                'My Report',
                                style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d').format(report.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(report.description,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(report.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
            if (currentUserId.isNotEmpty &&
                report.reporter.id.trim() != currentUserId.trim() &&
                report.reporter.name.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reported by ${report.reporter.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (report.additionalInfo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${report.additionalInfo.length} additional info added',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: onUpvote,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isUpvoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          color: isUpvoted
                              ? const Color(0xFF2E7D32)
                              : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${report.upvotes.length} Support',
                          style: TextStyle(
                              color: isUpvoted
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onAddInfo,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.add_comment_outlined,
                            color: Colors.grey, size: 18),
                        SizedBox(width: 4),
                        Text('Add Info',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                if (canEdit && onEdit != null) ...[
                  const Spacer(),
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF2E7D32).withAlpha(100)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              color: Color(0xFF2E7D32), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _EmbeddedReportForm extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const _EmbeddedReportForm({
    required this.onSuccess,
    this.onCancel,
  });

  @override
  State<_EmbeddedReportForm> createState() => _EmbeddedReportFormState();
}

class _EmbeddedReportFormState extends State<_EmbeddedReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _type = 'illegal_dumping';
  Uint8List? _imageBytes;
  double? _pickedLat;
  double? _pickedLng;
  String? _locationSource;
  bool _submitting = false;

  bool get _isFormDirty =>
      _titleCtrl.text.trim().isNotEmpty ||
      _descCtrl.text.trim().isNotEmpty ||
      _locationCtrl.text.trim().isNotEmpty ||
      _imageBytes != null ||
      _pickedLat != null;

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    setState(() {
      _imageBytes = null;
      _pickedLat = null;
      _pickedLng = null;
      _locationSource = null;
      _type = 'illegal_dumping';
    });
  }

  Future<void> _handleCancel() async {
    if (_isFormDirty) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Discard Report?'),
            ],
          ),
          content: const Text(
            'You have unsaved changes in your report. Are you sure you want to discard them?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (shouldDiscard != true) return;
    }

    _clearForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report form cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    widget.onCancel?.call();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location is turned off. Please enable location in device settings.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location access not granted. You can choose on the map instead.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission is blocked. Please allow location in device settings.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _pickedLat = position.latitude;
        _pickedLng = position.longitude;
        _locationSource = 'current';
        _locationCtrl.text =
            'Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Current location detected'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Unable to get location: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialPosition: _pickedLat != null && _pickedLng != null
              ? LatLng(_pickedLat!, _pickedLng!)
              : null,
          initialLabel: _locationCtrl.text,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLat = result.lat;
        _pickedLng = result.lng;
        _locationSource = 'map';
        if (result.label != null && result.label!.isNotEmpty) {
          _locationCtrl.text = result.label!;
        } else {
          _locationCtrl.text =
              'Near ${result.lat.toStringAsFixed(4)}, ${result.lng.toStringAsFixed(4)}';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗺️ Location updated from map'),
            backgroundColor: Color(0xFF1565C0),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
      }

      await CommunityReportService().createReport(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        type: _type,
        imageUrl: imageUrl,
        coordinates: _pickedLat != null && _pickedLng != null
            ? {'lat': _pickedLat!, 'lng': _pickedLng!}
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Report submitted! +10 Green Points earned 🎉',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );

        _formKey.currentState?.reset();
        _titleCtrl.clear();
        _descCtrl.clear();
        _locationCtrl.clear();
        setState(() {
          _imageBytes = null;
          _pickedLat = null;
          _pickedLng = null;
          _locationSource = null;
          _type = 'illegal_dumping';
        });

        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeOptions = [
      {'key': 'illegal_dumping', 'label': 'Illegal Dumping', 'icon': '🗑️'},
      {'key': 'overflow', 'label': 'Bin Overflow', 'icon': '⚠️'},
      {'key': 'contamination', 'label': 'Contamination', 'icon': '☢️'},
      {'key': 'other', 'label': 'Other Issue', 'icon': '❓'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF2E7D32),
                      radius: 20,
                      child:
                          Icon(Icons.campaign, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Waste Issue',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Spot dumping or overflowing bins? Submit details below.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars,
                              color: Colors.amber.shade800, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '+10 Pts',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isFormDirty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _handleCancel,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Issue Type
              const Text(
                'Issue Type',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: typeOptions.map((opt) {
                  final isSelected = _type == opt['key'];
                  return InkWell(
                    onTap: () => setState(() => _type = opt['key']!),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E7D32).withAlpha(25)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(opt['icon']!,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            opt['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Broken furniture dumped near playground',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),

              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the waste issue, landmarks, or hazards...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),

              const SizedBox(height: 16),

              // Location
              const Text(
                'Location',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. 5th Avenue, opposite community hall',
                  prefixIcon: const Icon(Icons.location_on,
                      color: Colors.grey, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Location is required'
                    : null,
              ),

              const SizedBox(height: 8),

              // Location Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location, size: 16),
                      label: Text(
                        _locationSource == 'current'
                            ? 'Location Found ✓'
                            : 'Use Current Location',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: BorderSide(
                          color: const Color(0xFF2E7D32),
                          width: _locationSource == 'current' ? 2 : 1,
                        ),
                        backgroundColor: _locationSource == 'current'
                            ? const Color(0xFF2E7D32).withAlpha(20)
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: Text(
                        _locationSource == 'map'
                            ? 'Map Picked ✓'
                            : 'Choose on Map',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: BorderSide(
                          color: const Color(0xFF1565C0),
                          width: _locationSource == 'map' ? 2 : 1,
                        ),
                        backgroundColor: _locationSource == 'map'
                            ? const Color(0xFF1565C0).withAlpha(20)
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Map Preview if coordinates exist
              if (_pickedLat != null && _pickedLng != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                    onTap: _openMapPicker,
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: IgnorePointer(
                        child: FlutterMap(
                          key: ValueKey('preview_${_pickedLat}_$_pickedLng'),
                          options: MapOptions(
                            initialCenter: LatLng(_pickedLat!, _pickedLng!),
                            initialZoom: 18.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ecotrack.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_pickedLat!, _pickedLng!),
                                width: 36,
                                height: 36,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFD32F2F),
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '📍 ${_pickedLat!.toStringAsFixed(5)}, ${_pickedLng!.toStringAsFixed(5)}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() {
                        _pickedLat = null;
                        _pickedLng = null;
                        _locationSource = null;
                        if (_locationCtrl.text.startsWith('Near ')) {
                          _locationCtrl.clear();
                        }
                      }),
                      child: const Text(
                        'Clear Pin',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Photo
              const Text(
                'Photo (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: _imageBytes != null ? 150 : 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageBytes != null
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 28, color: Colors.grey),
                            SizedBox(height: 4),
                            Text(
                              'Tap to upload a photo',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
              if (_imageBytes != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _imageBytes = null),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 16),
                    label: const Text(
                      'Remove photo',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Action Buttons: Cancel and Submit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _handleCancel,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.send_rounded, size: 18),
                        label: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit (+10 Pts)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
