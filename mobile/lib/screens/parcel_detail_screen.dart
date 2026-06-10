import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/parcel.dart';

class ParcelDetailScreen extends StatelessWidget {
  final Parcel parcel;

  const ParcelDetailScreen({super.key, required this.parcel});

  // Helper para construir las tarjetas de métricas estáticas superiores
  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
          parcel.name,
          style: const TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
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
                      Text(parcel.location, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.layers_rounded, color: Color(0xFF1B4314), size: 18),
                      const SizedBox(width: 8),
                      Text('Tipo de Suelo: ${parcel.soilType}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 📊 SECCIÓN DE MÉTRICAS ACTUALES (2 COLUMNAS)
            Row(
              children: [
                Expanded(child: _buildStatCard('Humedad actual', '${parcel.moisture}%', Icons.water_drop_rounded, const Color(0xFF2E86C1))),
                const SizedBox(width: 14),
                Expanded(child: _buildStatCard('pH del Suelo', '${parcel.ph}', Icons.science_rounded, const Color(0xFF1B4314))),
              ],
            ),
            const SizedBox(height: 14),
            _buildStatCard('Temperatura ambiental', '${parcel.temperature}°C', Icons.thermostat_rounded, const Color(0xFFE67E22)),
            
            const SizedBox(height: 28),

            // 📈 CONTENEDOR DEL GRÁFICO HISTÓRICO
            const Text(
              'Histórico de Humedad (Últimas horas)',
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
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
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
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          // Simulación de etiquetas de tiempo en el eje X
                          switch (value.toInt()) {
                            case 1: return const Text('12:00', style: TextStyle(fontSize: 10, color: Colors.grey));
                            case 3: return const Text('14:00', style: TextStyle(fontSize: 10, color: Colors.grey));
                            case 5: return const Text('16:00', style: TextStyle(fontSize: 10, color: Colors.grey));
                            case 7: return const Text('18:00', style: TextStyle(fontSize: 10, color: Colors.grey));
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
                  maxX: 8,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      // Datos mock de la curva de humedad
                      spots: [
                        const FlSpot(0, 65),
                        const FlSpot(2, 58),
                        const FlSpot(4, 42),
                        const FlSpot(5, 35), // Simula caída en Estrés Hídrico
                        const FlSpot(6, 75), // Simula riego posterior
                        const FlSpot(8, 70),
                      ],
                      isCurved: true,
                      color: const Color(0xFF1B4314), // Tu verde representativo
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF1B4314).withValues(alpha: 25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}