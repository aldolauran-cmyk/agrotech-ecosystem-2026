import 'dart:async';
import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'login_screen.dart';

class ParcelListScreen extends StatefulWidget {
  const ParcelListScreen({super.key});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  final _apiClient = ApiClient();
  final _tokenStorage = TokenStorage();
  Timer? _refreshTimer;
  bool _isLoading = true;
  List<Parcel> _parcels = [];

  @override
  void initState() {
    super.initState();
    _fetchParcels();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchParcels(showErrors: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchParcels({bool showErrors = true}) async {
    if (!_isLoading && _parcels.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await _apiClient.get('/parcels');
      if (response.statusCode == 200) {
        final List<dynamic> rawList = _apiClient.decodeJsonList(response);
        final parcels = rawList
            .map((item) => Parcel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _parcels = parcels;
          });
        }
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
      } else if (showErrors && mounted) {
        _showError('No se pudo cargar las parcelas.');
      }
    } catch (_) {
      if (showErrors && mounted) {
        _showError('No se pudo cargar las parcelas.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUnauthorized() async {
    await _tokenStorage.clearToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout() async {
    await _tokenStorage.clearToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6), // Fondo crema global
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF1B4314), size: 28),
          onPressed: () {},
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🌿 MINI LOGO CIRCULAR LOCAL EN EL APPBAR
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/logoparcela.png'), // 👈 Cambiado a asset local
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Mis Parcelas',
              style: TextStyle(
                color: Color(0xFF1B4314),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 28),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchParcels,
        color: const Color(0xFF3B6043),
        child: _isLoading && _parcels.isEmpty
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B6043))))
            : _parcels.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.eco_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes parcelas registradas aún.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    itemCount: _parcels.length,
                    itemBuilder: (context, index) {
                      final parcel = _parcels[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        height: 155, // Altura exacta para contener los textos y la barra inferior
                        child: Stack(
                          clipBehavior: Clip.none, // Crucial: Permite que el tractor sobresalga
                          children: [
                            // 💳 Tarjeta Principal de Fondo
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E7DF), // El color crema/verdoso de tu imagen
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.only(left: 20, top: 16, right: 140), // Espacio para el tractor gigante
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      parcel.name,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B4314), // Tu verde corporativo oscuro
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            parcel.location,
                                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.layers_outlined, size: 16, color: Colors.black54),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Suelo: ${parcel.soilType}',
                                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 🏁 Barra Inferior de Estado ("Status: Active")
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD2D9CE), // Tono ligeramente más oscuro para la base
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Status: Active',
                                    style: TextStyle(
                                      color: Color(0xFF1B4314),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 🚜 ILUSTRACIÓN LOCAL DEL TRACTOR GIGANTE (Optimizado con BoxFit.contain)
                            Positioned(
                              right: -10, // Sobresale levemente a la derecha
                              top: -20,   // Sobresale hacia arriba rompiendo el contenedor
                              bottom: 12,  // Evita pisar la barra de estado inferior
                              child: Image.asset(
                                'assets/logotractor.png', // 👈 Cambiado a asset local
                                fit: BoxFit.contain,
                                width: 150, // Forzamos el ancho para dar un aspecto imponente
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}