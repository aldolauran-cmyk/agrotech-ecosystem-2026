class Parcel {
  final int id;
  final String name;
  final String ubicacionGrilla;
  final String ubicacionReferencial;
  final String soilType;
  final int ownerId;    
  final double moisture;      // Humedad del suelo (%)
  final double ph;            // pH del suelo (Acidez)
  final double temperature;   // Temperatura del suelo (°C)
  final bool hasWaterStress;  // Alerta de estrés hídrico crítica

  Parcel({
    required this.id,
    required this.name,
    required this.ubicacionGrilla,
    required this.ubicacionReferencial,
    required this.soilType,
    required this.ownerId,
    required this.moisture,
    required this.ph,
    required this.temperature,
    required this.hasWaterStress,
  });

// Este es el constructor que convierte el mapa JSON del Backend a un Objeto Flutter
  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'] as int,
      name: json['name'] as String,
      ubicacionGrilla: json['ubicacion_grilla'] as String? ?? "0,0",
      ubicacionReferencial: json['ubicacion_referencial'] as String? ?? "",
      soilType: json['soil_type'] as String,
      ownerId: json['owner_id'] as int,
      
// Usamos num y toDouble() por si el backend envía enteros (ej. 23 en vez de 23.0)
      moisture: (json['moisture'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      hasWaterStress: json['has_water_stress'] as bool? ?? false,   // Si es nulo por defecto es false 
    );
  }
}
