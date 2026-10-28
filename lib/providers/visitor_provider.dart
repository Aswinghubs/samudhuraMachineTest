import 'package:flutter/foundation.dart';

import '../models/visitor.dart';
import '../services/visitor_api_service.dart';

class VisitorProvider extends ChangeNotifier {
  VisitorProvider(this._apiService);

  final VisitorApiService _apiService;

  List<Visitor> _visitors = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _processingVisitorIds = {};

  List<Visitor> get visitors => List.unmodifiable(_visitors);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalVisitorsToday {
    final now = DateTime.now();

    return _visitors.where((visitor) {
      final date = DateTime.tryParse(visitor.createdAt)?.toLocal();

      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get currentlyCheckedIn =>
      _visitors.where((v) => v.status == 'Checked In').length;

  int get checkedOutToday {
    final now = DateTime.now();

    return _visitors.where((visitor) {
      if (visitor.status != 'Checked Out') return false;

      final date = DateTime.tryParse(visitor.checkOutTime ?? '')?.toLocal();

      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  Visitor? findVisitor(String id) {
    for (final visitor in _visitors) {
      if (visitor.id == id) return visitor;
    }
    return null;
  }

  List<Visitor> searchVisitors(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) return visitors;

    return _visitors.where((visitor) {
      return visitor.name.toLowerCase().contains(normalized) ||
          visitor.mobile.contains(normalized);
    }).toList();
  }

  Future<void> loadVisitors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _visitors = await _apiService.getVisitors();
    } catch (_) {
      _errorMessage =
          'Unable to load visitors. Check your internet connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Visitor> registerVisitor(Visitor visitor) async {
    final created = await _apiService.createVisitor(visitor);

    _visitors = [created, ..._visitors.where((v) => v.id != created.id)];

    notifyListeners();
    return created;
  }

  Future<Visitor> editVisitor(Visitor visitor) async {
    final updated = await _apiService.updateVisitor(visitor);

    _visitors = _visitors.map((v) => v.id == updated.id ? updated : v).toList();

    notifyListeners();
    return updated;
  }

  Future<void> deleteVisitor(String id) async {
    await _apiService.deleteVisitor(id);

    _visitors.removeWhere((visitor) => visitor.id == id);
    notifyListeners();
  }

  Future<Visitor> updateVisitStatus(String id) async {
    if (!_processingVisitorIds.add(id)) {
      throw StateError('This visitor is already being processed.');
    }

    try {
      final current = await _apiService.getVisitor(id);

      late final Visitor updated;

      if (current.status == 'Registered') {
        updated = Visitor(
          id: current.id,
          name: current.name,
          mobile: current.mobile,
          email: current.email,
          visitorType: current.visitorType,
          project: current.project,
          purpose: current.purpose,
          status: 'Checked In',
          createdAt: current.createdAt,
          checkInTime: DateTime.now().toIso8601String(),
          checkOutTime: null,
        );
      } else if (current.status == 'Checked In') {
        updated = Visitor(
          id: current.id,
          name: current.name,
          mobile: current.mobile,
          email: current.email,
          visitorType: current.visitorType,
          project: current.project,
          purpose: current.purpose,
          status: 'Checked Out',
          createdAt: current.createdAt,
          checkInTime: current.checkInTime,
          checkOutTime: DateTime.now().toIso8601String(),
        );
      } else {
        throw StateError('This visit has already been completed.');
      }

      return await editVisitor(updated);
    } finally {
      _processingVisitorIds.remove(id);
    }
  }
}
