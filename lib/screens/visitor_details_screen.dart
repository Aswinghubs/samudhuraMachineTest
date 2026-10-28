import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import 'visitor_form_screen.dart';

class VisitorDetailsScreen extends StatefulWidget {
  const VisitorDetailsScreen({super.key, required this.visitor});

  final Visitor visitor;

  @override
  State<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends State<VisitorDetailsScreen> {
  bool _updatingStatus = false;

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Not recorded';

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Not recorded';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  $hour:$minute $period';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Checked In':
        return Colors.green;
      case 'Checked Out':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Future<void> _changeStatus(Visitor visitor) async {
    final nextStatus = visitor.status == 'Registered'
        ? 'check in'
        : 'check out';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm $nextStatus'),
        content: Text('Do you want to $nextStatus ${visitor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _updatingStatus = true);

    try {
      await context.read<VisitorProvider>().updateVisitStatus(visitor.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Visitor $nextStatus successful')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to $nextStatus: $error')));
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitorProvider>();
    final visitor = provider.findVisitor(widget.visitor.id) ?? widget.visitor;
    final color = _statusColor(visitor.status);
    final canChangeStatus = visitor.status != 'Checked Out';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details'),
        actions: [
          IconButton(
            tooltip: 'Edit visitor',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VisitorFormScreen(visitor: visitor),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    child: Text(
                      visitor.name.isEmpty
                          ? '?'
                          : visitor.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    visitor.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    avatar: Icon(Icons.circle, size: 10, color: color),
                    label: Text(visitor.status),
                    backgroundColor: color.withValues(alpha: 0.10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visitor ID: ${visitor.id}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visitor Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Mobile', value: visitor.mobile),
                  _InfoRow(
                    label: 'Email',
                    value: visitor.email?.isNotEmpty == true
                        ? visitor.email!
                        : 'Not provided',
                  ),
                  _InfoRow(label: 'Visitor Type', value: visitor.visitorType),
                  _InfoRow(label: 'Project', value: visitor.project),
                  _InfoRow(label: 'Purpose', value: visitor.purpose),
                  _InfoRow(
                    label: 'Registered',
                    value: _formatDate(visitor.createdAt),
                  ),
                  _InfoRow(
                    label: 'Check-in',
                    value: _formatDate(visitor.checkInTime),
                  ),
                  _InfoRow(
                    label: 'Check-out',
                    value: _formatDate(visitor.checkOutTime),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Visitor QR Code',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan this code to retrieve the visitor record.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: visitor.id,
                    version: QrVersions.auto,
                    size: 210,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  SelectableText(
                    visitor.id,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (canChangeStatus)
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _updatingStatus
                    ? null
                    : () => _changeStatus(visitor),
                icon: _updatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        visitor.status == 'Registered'
                            ? Icons.login
                            : Icons.logout,
                      ),
                label: Text(
                  _updatingStatus
                      ? 'Updating...'
                      : visitor.status == 'Registered'
                      ? 'Check In Visitor'
                      : 'Check Out Visitor',
                ),
              ),
            )
          else
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Visit completed'),
                subtitle: Text('This visitor cannot check in again.'),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
