import 'dart:async';
import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'login_screen.dart';
import 'parcel_detail_screen.dart';
import 'global_reports_screen.dart';

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
  String _selectedFilter = 'Todas'; // Control de filtro rápido ('Todas' o '⚠️ Con Estrés')
  String _username = 'Cargando...';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _fetchParcels();
    _fetchCurrentUser();
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

  Future<void> _fetchCurrentUser() async {
    final userData = await _apiClient.getCurrentUser();
    if (userData != null && mounted) {
      setState(() {
        _username = userData['username'] as String? ?? 'Usuario';
        _userRole = userData['role'] as String? ?? '';
      });
    }
  }

  void _showCreateParcelDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final soilTypeController = TextEditingController();
    final ownerIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Registrar Nueva Parcela',
            style: TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Parcela'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                ),
                TextField(
                  controller: soilTypeController,
                  decoration: const InputDecoration(labelText: 'Tipo de Suelo'),
                ),
                // Campo exclusivo para Admin: asignar parcela a otro usuario
                if (_userRole == 'admin') ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFF1B4314)),
                      const SizedBox(width: 6),
                      Text(
                        'Opciones de Administrador',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ownerIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Asignar a Usuario (ID) — opcional',
                      helperText: 'Dejar vacío para asignar al admin',
                      helperStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B6043)),
              onPressed: () async {
                final name = nameController.text.trim();
                final location = locationController.text.trim();
                final soilType = soilTypeController.text.trim();
                final ownerIdText = ownerIdController.text.trim();

                if (name.isEmpty || location.isEmpty || soilType.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, completa todos los campos')),
                  );
                  return;
                }

                // Construir el payload base
                final Map<String, dynamic> payload = {
                  'name': name,
                  'location': location,
                  'soil_type': soilType,
                };

                // Si es admin y especificó un owner_id, añadirlo al payload
                if (_userRole == 'admin' && ownerIdText.isNotEmpty) {
                  final parsedId = int.tryParse(ownerIdText);
                  if (parsedId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El ID de usuario debe ser un número válido')),
                    );
                    return;
                  }
                  payload['owner_id'] = parsedId;
                }

                try {
                  final response = await _apiClient.postJson('/parcels', payload);

                  if (response.statusCode == 201) {
                    if (mounted) {
                      Navigator.pop(context);
                      _fetchParcels();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Parcela registrada con éxito')),
                      );
                    }
                  } else if (response.statusCode == 404) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario destino no encontrado. Verifica el ID.')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al registrar parcela')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error de conexión')),
                    );
                  }
                }
              },
              child: const Text('Registrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- COMPONENTE: MENÚ LATERAL (DRAWER) ---
  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F9F6),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1B4314)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Color(0xFFE2E7DF),
              child: Icon(Icons.person_rounded, size: 40, color: Color(0xFF1B4314)),
            ),
            accountName: Text(
              _username.toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              '${_username.toLowerCase()}@agrotech.com - ${_userRole.toUpperCase()}', 
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.eco_rounded, color: Color(0xFF1B4314)),
            title: const Text('Mis Parcelas', style: TextStyle(fontWeight: FontWeight.bold)),
            selected: true,
            selectedTileColor: const Color(0x80E2E7DF),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_rounded, color: Colors.black54),
            title: const Text('Reportes Globales'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GlobalReportsScreen(initialParcels: _parcels),
                ),
              );
            },
          ),
          const Divider(height: 20, thickness: 0.5),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- COMPONENTE: CHIPS DE FILTRADO ---
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todas'),
            selected: _selectedFilter == 'Todas',
            selectedColor: const Color(0xFFD2D9CE),
            checkmarkColor: const Color(0xFF1B4314),
            labelStyle: TextStyle(
              color: _selectedFilter == 'Todas' ? const Color(0xFF1B4314) : Colors.black87,
              fontWeight: _selectedFilter == 'Todas' ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            onSelected: (bool selected) {
              setState(() { _selectedFilter = 'Todas'; });
            },
          ),
          const SizedBox(width: 10),
          FilterChip(
            label: const Text('⚠️ Con Estrés'),
            selected: _selectedFilter == '⚠️ Con Estrés',
            selectedColor: const Color(0xFFFADBD8),
            checkmarkColor: const Color(0xFF7B241C),
            labelStyle: TextStyle(
              color: _selectedFilter == '⚠️ Con Estrés' ? const Color(0xFF7B241C) : Colors.black87,
              fontWeight: _selectedFilter == '⚠️ Con Estrés' ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            onSelected: (bool selected) {
              setState(() { _selectedFilter = '⚠️ Con Estrés'; });
            },
          ),
        ],
      ),
    );
  }

  // --- COMPONENTE: CÁPSULA ESTILIZADA DE SENSORES IOT ---
  Widget _buildVisualSensorBadge(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.75 * 255).round()),
        borderRadius: BorderRadius.circular(14),
      ),
      width: 76, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1B4314), size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 8.5, color: Colors.grey[800], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado dinámico local de la lista en memoria
    final filteredParcels = _parcels.where((parcel) {
      if (_selectedFilter == '⚠️ Con Estrés') return parcel.hasWaterStress;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6), 
      drawer: _buildNavigationDrawer(context), // Enlace automático con el botón del menú
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/logoparcela1.png'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Mis Parcelas',
              style: TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold, fontSize: 22),
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
        child: Column(
          children: [
            _buildFilterChips(), // Renderiza la barra horizontal de filtros superiores
            Expanded(
              child: _isLoading && _parcels.isEmpty
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B6043))))
                  : filteredParcels.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.eco_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedFilter == '⚠️ Con Estrés' 
                                        ? 'No hay parcelas con estrés hídrico.'
                                        : 'No tienes parcelas registradas aún.',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          itemCount: filteredParcels.length,
                          itemBuilder: (context, index) {
                            final parcel = filteredParcels[index];
                            return GestureDetector(
                              onTap: () {
                              // 📊 Navegación real y directa hacia la pantalla de detalle
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParcelDetailScreen(parcel: parcel),
                                ),
                              ).then((_) => _fetchParcels()); // Refrescar al volver del detalle
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                child: Stack(
                                  clipBehavior: Clip.none, 
                                  children: [
                                    // 💳 Tarjeta Principal Premium de Fondo (Flexible)
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E7DF), 
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.only(left: 20, top: 18, right: 130, bottom: 48), 
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            parcel.name,
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4314)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF556B52)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  parcel.location,
                                                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.layers_rounded, size: 15, color: Color(0xFF556B52)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Suelo: ${parcel.soilType}',
                                                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 12),
                                          
                                          // 💧 🧪 🌡️ CONTENEDORES DE TELEMETRÍA IOT
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildVisualSensorBadge(Icons.water_drop_rounded, '${parcel.moisture}%', 'Humedad'),
                                              _buildVisualSensorBadge(Icons.science_rounded, '${parcel.ph}', 'pH Suelo'),
                                              _buildVisualSensorBadge(Icons.thermostat_rounded, '${parcel.temperature}°C', 'Temp'),
                                            ],
                                          ),
                                          
                                          // ⚠️ BANNER DE ALERTA DE ESTRÉS HÍDRICO REDISEÑADO
                                          if (parcel.hasWaterStress) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFADBD8), 
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFE6B0AA), width: 1),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B), size: 18),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Estrés Hídrico Detectado',
                                                      style: TextStyle(color: Color(0xFF922B21), fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 0.2),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // 🏁 Barra Inferior de Estado Tracker
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: parcel.hasWaterStress ? const Color(0xFFE5CDC8) : const Color(0xFFD2D9CE), 
                                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            parcel.hasWaterStress ? 'STATUS: ATTENTION REQUIRED' : 'STATUS: ACTIVE', 
                                            style: TextStyle(
                                              color: parcel.hasWaterStress ? const Color(0xFF7B241C) : const Color(0xFF1B4314),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 🚜 ILUSTRACIÓN DEL TRACTOR GIGANTE
                                    Positioned(
                                      right: -8, 
                                      top: -18,   
                                      bottom: 38, 
                                      child: Image.asset(
                                        'assets/logotractor1.png', 
                                        fit: BoxFit.contain,
                                        width: 135, 
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
             ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B6043),
        onPressed: _showCreateParcelDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}