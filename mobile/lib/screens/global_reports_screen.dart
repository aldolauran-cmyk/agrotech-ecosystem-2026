import 'dart:async';
import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../services/api_client.dart';

class GlobalReportsScreen extends StatefulWidget {
  final List<Parcel> initialParcels;

  const GlobalReportsScreen({super.key, required this.initialParcels});

  @override
  State<GlobalReportsScreen> createState() => _GlobalReportsScreenState();
}

class _GlobalReportsScreenState extends State<GlobalReportsScreen> {
  final _apiClient = ApiClient();
  Timer? _refreshTimer;
  List<Parcel> _parcels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _parcels = widget.initialParcels;
    _refreshParcels();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshParcels(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshParcels({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/parcels');
      if (response.statusCode == 200) {
        final List<dynamic> rawList = _apiClient.decodeJsonList(response);
        final parcels = rawList
            .map((item) => Parcel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _parcels = parcels);
      }
    } catch (_) {}
    if (!silent && mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalParcels = _parcels.length;
    final stressedParcels = _parcels.where((p) => p.hasWaterStress).length;
    final healthyParcels = totalParcels - stressedParcels;

    double avgMoisture = 0.0;
    double avgPh = 0.0;
    double avgTemp = 0.0;

    if (totalParcels > 0) {
      avgMoisture = _parcels.map((p) => p.moisture).reduce((a, b) => a + b) / totalParcels;
      avgPh = _parcels.map((p) => p.ph).reduce((a, b) => a + b) / totalParcels;
      avgTemp = _parcels.map((p) => p.temperature).reduce((a, b) => a + b) / totalParcels;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B4314), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reportes Globales',
          style: TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B6043)),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshParcels,
        color: const Color(0xFF3B6043),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de actualización automática
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.autorenew_rounded, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('Se actualiza cada 30s', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 10),

              // Resumen de Estado de Parcelas
              const Text(
                'Estado del Ecosistema',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4314)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Parcelas',
                      value: '$totalParcels',
                      color: const Color(0xFF1B4314),
                      icon: Icons.grid_view_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Bajo Estrés',
                      value: '$stressedParcels',
                      color: stressedParcels > 0 ? const Color(0xFFC0392B) : Colors.grey,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tarjeta de distribución (Salud general)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribución de Salud',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    totalParcels == 0
                        ? const Text('Sin datos de parcelas', style: TextStyle(color: Colors.grey))
                        : Row(
                            children: [
                              Expanded(
                                flex: healthyParcels > 0 ? healthyParcels : 1,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF52BE80),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(6),
                                      bottomLeft: const Radius.circular(6),
                                      topRight: stressedParcels == 0 ? const Radius.circular(6) : Radius.zero,
                                      bottomRight: stressedParcels == 0 ? const Radius.circular(6) : Radius.zero,
                                    ),
                                  ),
                                ),
                              ),
                              if (stressedParcels > 0)
                                Expanded(
                                  flex: stressedParcels,
                                  child: Container(
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEC7063),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(6),
                                        bottomRight: Radius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, color: const Color(0xFF52BE80)),
                            const SizedBox(width: 6),
                            Text('Saludables ($healthyParcels)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(width: 10, height: 10, color: const Color(0xFFEC7063)),
                            const SizedBox(width: 6),
                            Text('Estrés Hídrico ($stressedParcels)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Promedios Generales de Sensores
              const Text(
                'Promedios Generales del Suelo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4314)),
              ),
              const SizedBox(height: 14),
              _buildAverageMetricTile(
                title: 'Humedad Promedio',
                value: totalParcels > 0 ? '${avgMoisture.toStringAsFixed(1)}%' : '—',
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF2E86C1),
                percentage: totalParcels > 0 ? avgMoisture / 100.0 : 0,
              ),
              const SizedBox(height: 14),
              _buildAverageMetricTile(
                title: 'pH Promedio',
                value: totalParcels > 0 ? avgPh.toStringAsFixed(2) : '—',
                icon: Icons.science_rounded,
                color: const Color(0xFF1B4314),
                percentage: totalParcels > 0 ? avgPh / 14.0 : 0,
              ),
              const SizedBox(height: 14),
              _buildAverageMetricTile(
                title: 'Temperatura Promedio',
                value: totalParcels > 0 ? '${avgTemp.toStringAsFixed(1)}°C' : '—',
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFE67E22),
                percentage: totalParcels > 0 ? avgTemp / 50.0 : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: color.withOpacity(0.7), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAverageMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double percentage,
  }) {
    final clampPercent = percentage.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                ],
              ),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampPercent,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
