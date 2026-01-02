import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({Key? key}) : super(key: key);

  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _reports = [];
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadStats(),
      _loadReports(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final String? token = AuthService().loadUserData('accessToken');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://roomier-production.up.railway.app/api/admin/reports/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _stats = json.decode(response.body)['statistics'];
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadReports() async {
    try {
      final String? token = AuthService().loadUserData('accessToken');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('https://roomier-production.up.railway.app/api/admin/reports?status=$_selectedStatus&limit=50'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reports = data['reports'];
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.report), text: 'Reportes'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildReportsTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    if (_stats == null) {
      return const Center(child: Text('No hay estadísticas disponibles'));
    }

    final byStatus = _stats!['byStatus'] as List? ?? [];
    final byReason = _stats!['byReason'] as List? ?? [];
    final pending = _stats!['recent'] as List? ?? [];
    final pendingCount = pending.isNotEmpty ? pending[0]['pendingCount'] ?? 0 : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen rápido
          Card(
            elevation: 4,
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 48),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$pendingCount Reportes Pendientes',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Requieren revisión',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reportes por estado
          const Text(
            'Reportes por Estado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...byStatus.map((item) => _buildStatCard(
                _getStatusName(item['_id']),
                item['count'].toString(),
                _getStatusColor(item['_id']),
                _getStatusIcon(item['_id']),
              )),
          const SizedBox(height: 24),

          // Reportes por razón
          const Text(
            'Reportes por Razón',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...byReason.map((item) => _buildStatCard(
                _getReasonName(item['_id']),
                item['count'].toString(),
                Colors.blue,
                Icons.info_outline,
              )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        // Filtro por estado
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Filtrar: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todos')),
                    DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
                    DropdownMenuItem(value: 'reviewed', child: Text('Revisados')),
                    DropdownMenuItem(value: 'action_taken', child: Text('Acción tomada')),
                    DropdownMenuItem(value: 'dismissed', child: Text('Descartados')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _loadReports();
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Lista de reportes
        Expanded(
          child: _reports.isEmpty
              ? const Center(child: Text('No hay reportes'))
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return _buildReportCard(report);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['status'] ?? 'pending';
    final reason = report['reason'] ?? 'other';
    final createdAt = DateTime.parse(report['createdAt'] ?? DateTime.now().toIso8601String());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(_getStatusIcon(status), color: Colors.white, size: 20),
        ),
        title: Text(
          'Usuario: ${report['reportedUser']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_getReasonName(reason)} • ${_formatDate(createdAt)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Reportado por', report['reportedBy']),
                _buildInfoRow('Razón', _getReasonName(reason)),
                _buildInfoRow('Estado', _getStatusName(status)),
                if (report['description'] != null && report['description'].isNotEmpty)
                  _buildInfoRow('Descripción', report['description']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'pending') ...[
                      TextButton.icon(
                        onPressed: () => _updateReportStatus(report['_id'], 'dismissed'),
                        icon: const Icon(Icons.close),
                        label: const Text('Descartar'),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showActionDialog(report),
                        icon: const Icon(Icons.gavel),
                        label: const Text('Tomar Acción'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return const Center(
      child: Text(
        'Funcionalidad de usuarios próximamente',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  void _showActionDialog(Map<String, dynamic> report) {
    String? selectedAction;
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Acción para ${report['reportedUser']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Selecciona una acción:'),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('Advertencia'),
                  value: 'warning',
                  groupValue: selectedAction,
                  onChanged: (value) => setState(() => selectedAction = value),
                ),
                RadioListTile<String>(
                  title: const Text('Suspender cuenta (temporal)'),
                  value: 'suspend',
                  groupValue: selectedAction,
                  onChanged: (value) => setState(() => selectedAction = value),
                ),
                RadioListTile<String>(
                  title: const Text('Banear (permanente)'),
                  value: 'ban',
                  groupValue: selectedAction,
                  onChanged: (value) => setState(() => selectedAction = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedAction == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      _applyAction(
                        report['_id'],
                        report['reportedUser'],
                        selectedAction!,
                        notesController.text,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      final String? token = AuthService().loadUserData('accessToken');
      if (token == null) return;

      final response = await http.put(
        Uri.parse('https://roomier-production.up.railway.app/api/admin/reports/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte actualizado')),
        );
        _loadReports();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _applyAction(String reportId, String username, String action, String notes) async {
    try {
      final String? token = AuthService().loadUserData('accessToken');
      if (token == null) return;

      // Actualizar reporte
      await _updateReportStatus(reportId, 'action_taken');

      // Aplicar acción al usuario
      final response = await http.post(
        Uri.parse('https://roomier-production.up.railway.app/api/admin/users/$username/action'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'action': action,
          'reason': notes.isEmpty ? 'Acción por reporte' : notes,
          'duration': action == 'suspend' ? 7 : null,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Acción "$action" aplicada correctamente')),
        );
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Helpers
  String _getStatusName(String status) {
    const map = {
      'pending': 'Pendiente',
      'reviewed': 'Revisado',
      'action_taken': 'Acción tomada',
      'dismissed': 'Descartado',
    };
    return map[status] ?? status;
  }

  String _getReasonName(String reason) {
    const map = {
      'harassment': 'Acoso',
      'fake': 'Información falsa',
      'spam': 'Spam',
      'inappropriate': 'Comportamiento inapropiado',
      'other': 'Otro',
      'inappropriate_behavior': 'Comportamiento inapropiado',
      'fake_profile': 'Perfil falso',
      'offensive_content': 'Contenido ofensivo',
      'scam': 'Estafa',
      'underage': 'Menor de edad',
      'impersonation': 'Suplantación',
    };
    return map[reason] ?? reason;
  }

  Color _getStatusColor(String status) {
    const map = {
      'pending': Colors.orange,
      'reviewed': Colors.blue,
      'action_taken': Colors.green,
      'dismissed': Colors.grey,
    };
    return map[status] ?? Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    const map = {
      'pending': Icons.pending,
      'reviewed': Icons.visibility,
      'action_taken': Icons.check_circle,
      'dismissed': Icons.cancel,
    };
    return map[status] ?? Icons.help;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
