import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import 'parcel_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiClient = ApiClient();
  final _tokenStorage = TokenStorage();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.postForm('/token', {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = _apiClient.decodeJson(response);
        final token = data['access_token'] as String?;
        if (token == null) {
          throw Exception('Token inválido');
        }
        await _tokenStorage.saveToken(token);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParcelListScreen()),
        );
        return;
      }

      _showError('Credenciales inválidas.');
    } catch (_) {
      if (mounted) {
        _showError('No se pudo iniciar sesión.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6), // 🎨 Fondo crema exacto de la imagen
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400), // Optimización para centrado en Web
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🌿 LOGO AVANZADO PREMIUM (Carga local desde Assets)
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/logoagrotech.png', // 👈 CAMBIADO A ASSETIMAGE LOCAL
                          ), 
                          fit: BoxFit.contain, // Ajuste óptimo para vectores circulares sin recortes
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Título principal con el tono verde bosque oscuro
                    const Text(
                      'AgroTech',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4314), // Verde oscuro de la imagen
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.grey, 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 👤 Campo de Entrada: Usuario
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Usuario',
                        style: TextStyle(
                          color: Color(0xFF1B4314),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Color(0xFF1B4314)),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF3E6B48)),
                        hintText: 'Ingresa tu usuario',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF1F4F0), // Gris claro integrado con el tono crema
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0), // Mayor redondeado como la imagen
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔒 Campo de Entrada: Contraseña
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Contraseña',
                        style: TextStyle(
                          color: Color(0xFF1B4314),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Color(0xFF1B4314)),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF3E6B48)),
                        hintText: 'Ingresa tu contraseña',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF1F4F0),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 🟩 Botón "Ingresar" Sólido y Redondeado Premium
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B6043), // Verde exacto mate de la imagen
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF3B6043).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27), // Bordes perfectos tipo píldora
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}