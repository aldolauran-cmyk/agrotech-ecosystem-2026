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
    if (!_isLoading) {
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
      appBar: AppBar(
        title: const Text('Mis Parcelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchParcels,
        child: _isLoading && _parcels.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _parcels.length,
                itemBuilder: (context, index) {
                  final parcel = _parcels[index];
                  return ListTile(
                    title: Text(parcel.name),
                    subtitle: Text(
                      'Ubicación: ${parcel.location} - Suelo: ${parcel.soilType}',
                    ),
                    trailing: const Icon(Icons.agriculture),
                  );
                },
              ),
      ),
    );
  }
}
