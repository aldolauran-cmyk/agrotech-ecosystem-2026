import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/parcel.dart';
import '../services/api_client.dart';

class ParcelDetailScreen extends StatefulWidget {
  final Parcel parcel;

  const ParcelDetailScreen({super.key, required this.parcel});

  @override
  State<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends State<ParcelDetailScreen> {
  final _apiClient = ApiClient();
  Timer? _refreshTimer;
  late double _moisture;
  late double _ph;
  late double _temperature;
  late bool _hasWaterStress;
  List<FlSpot> _humidityHistory = [];
  List<String> _timeLabels = [];

  @override
  void initState() {
    super.initState();
    _moisture = widget.parcel.moisture;
    _ph = widget.parcel.ph;
    _temperature = widget.parcel.temperature;
    _hasWaterStress = widget.parcel.hasWaterStress;
    _fetchTelemetryHistory();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshParcelData();
      _fetchTelemetryHistory();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshParcelData() async {
    try {
      final response = await _apiClient.get('/parcels');
      if (response.statusCode == 200) {
        final List<dynamic> rawList = _apiClient.decodeJsonList(response);
        final updatedParcel = rawList
            .map((item) => Parcel.fromJson(item as Map<String, dynamic>))
            .where((p) => p.id == widget.parcel.id)
            .firstOrNull;
        if (updatedParcel != null && mounted) {
          setState(() {
            _moisture = updatedParcel.moisture;
            _ph = updatedParcel.ph;
            _temperature = updatedParcel.temperature;
            _hasWaterStress = updatedParcel.hasWaterStress;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTelemetryHistory() async {
    try {
      final response = await _apiClient.get('/telemetry/${widget.parcel.id}');
      if (response.statusCode == 200) {
        final List<dynamic> rawList = _apiClient.decodeJsonList(response);
        if (rawList.isEmpty) return;

        // Tomar las últimas 20 entradas para el gráfico
        final recent = rawList.length > 20 ? rawList.sublist(rawList.length - 20) : rawList;
        final spots = <FlSpot>[];
        final labels = <String>[];

        for (int i = 0; i < recent.length; i++) {
          final entry = recent[i] as Map<String, dynamic>;
          final humidity = (entry['humidity'] as num).toDouble();
          spots.add(FlSpot(i.toDouble(), humidity));
          
          // Parsear timestamp para etiquetas
          final ts = entry['timestamp'] as String?;
          if (ts != null) {
            try {
              final dt = DateTime.parse(ts);
              labels.add('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');
            } catch (_) {
              labels.add('');
            }
          } else {
            labels.add('');
          }
        }

        if (mounted) {
          setState(() {
            _humidityHistory = spots;
            _timeLabels = labels;
          });
        }
      }
    } catch (_) {}
  }

  // Helper para construir las tarjetas de métricas superiores
  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
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
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6), // Tu fondo crema global
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B4314), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.parcel.name,
          style: const TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshParcelData();
          await _fetchTelemetryHistory();
        },
        color: const Color(0xFF3B6043),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📍 BANNER DE INFORMACIÓN GENERAL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E7DF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF1B4314), size: 18),
                        const SizedBox(width: 8),
                        Text(widget.parcel.location, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.layers_rounded, color: Color(0xFF1B4314), size: 18),
                        const SizedBox(width: 8),
                        Text('Tipo de Suelo: ${widget.parcel.soilType}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ⚠️ ALERTA DE ESTRÉS HÍDRICO EN TIEMPO REAL
              if (_hasWaterStress) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFADBD8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6B0AA), width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '⚠️ ESTRÉS HÍDRICO DETECTADO - Humedad por debajo del 30%',
                          style: TextStyle(color: Color(0xFF922B21), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 📊 SECCIÓN DE MÉTRICAS ACTUALES (2 COLUMNAS)
              Row(
                children: [
                  Expanded(child: _buildStatCard('Humedad actual', '$_moisture%', Icons.water_drop_rounded, const Color(0xFF2E86C1))),
                  const SizedBox(width: 14),
                  Expanded(child: _buildStatCard('pH del Suelo', '$_ph', Icons.science_rounded, const Color(0xFF1B4314))),
                ],
              ),
              const SizedBox(height: 14),
              _buildStatCard('Temperatura ambiental', '$_temperature°C', Icons.thermostat_rounded, const Color(0xFFE67E22)),
              
              // Indicador de actualización automática
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.autorenew_rounded, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('Actualización automática cada 10s', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),

              const SizedBox(height: 28),

              // 📈 CONTENEDOR DEL GRÁFICO HISTÓRICO
              const Text(
                'Histórico de Humedad (Últimas lecturas)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4314)),
              ),
              const SizedBox(height: 14),
              Container(
                height: 260,
                padding: const EdgeInsets.only(right: 20, top: 24, left: 10, bottom: 12),
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
                child: _humidityHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'Esperando datos de telemetría...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey[200],
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: _humidityHistory.length > 5 ? (_humidityHistory.length / 5).ceilToDouble() : 1,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < _timeLabels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(_timeLabels[idx], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 20,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (_humidityHistory.length - 1).toDouble().clamp(1, double.infinity),
                          minY: 0,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _humidityHistory,
                              isCurved: true,
                              color: const Color(0xFF1B4314), // Tu verde representativo
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: _humidityHistory.length <= 10,
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF1B4314).withOpacity(0.1),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '${spot.y.toStringAsFixed(1)}%',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}