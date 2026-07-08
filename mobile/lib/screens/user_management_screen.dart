import 'package:flutter/material.dart';
import '../services/api_client.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _apiClient = ApiClient();
  List<dynamic> _users = [];
  bool _isLoading = true;

  // Roles disponibles
  final List<String> _roles = ['farmer', 'viewer'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _apiClient.getUsers();
    if (mounted) {
      setState(() {
        _users = users ?? [];
        _isLoading = false;
      });
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF1B4314);
      case 'farmer':
        return const Color(0xFF2E86C1);
      case 'viewer':
        return const Color(0xFF8E44AD);
      default:
        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'farmer':
        return Icons.agriculture_rounded;
      case 'viewer':
        return Icons.visibility_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  void _showCreateUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'farmer';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Crear Nuevo Usuario',
                style: TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        helperText: 'Mínimo 3 caracteres',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                        helperText: 'Mínimo 6 caracteres',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Rol', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B4314))),
                    const SizedBox(height: 8),
                    ..._roles.map((role) {
                      return RadioListTile<String>(
                        value: role,
                        groupValue: selectedRole,
                        title: Row(
                          children: [
                            Icon(_roleIcon(role), color: _roleColor(role), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              role == 'farmer' ? 'Agricultor (farmer)' : 'Observador (viewer)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          role == 'farmer'
                              ? 'Puede crear y ver sus propias parcelas'
                              : 'Solo puede ver parcelas asignadas',
                          style: const TextStyle(fontSize: 11),
                        ),
                        activeColor: _roleColor(role),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedRole = val);
                        },
                      );
                    }),
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
                    final username = usernameController.text.trim();
                    final password = passwordController.text;

                    if (username.length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El nombre de usuario debe tener al menos 3 caracteres')),
                      );
                      return;
                    }
                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                      );
                      return;
                    }

                    final response = await _apiClient.createUser({
                      'username': username,
                      'password': password,
                      'role': selectedRole,
                    });

                    if (response.statusCode == 201) {
                      if (mounted) {
                        Navigator.pop(context);
                        _fetchUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Usuario "$username" creado con éxito')),
                        );
                      }
                    } else if (response.statusCode == 409) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ese nombre de usuario ya existe')),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al crear usuario')),
                        );
                      }
                    }
                  },
                  child: const Text('Crear Usuario', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPasswordDialog(Map<String, dynamic> user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Restablecer Contraseña',
            style: TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva contraseña para ${user['username']}:'),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                  helperText: 'Mínimo 6 caracteres',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B6043)),
              onPressed: () async {
                final pwd = passwordController.text.trim();
                if (pwd.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                  );
                  return;
                }
                
                try {
                  final response = await _apiClient.updateUserPassword(user['id'] as int, pwd);
                  if (response.statusCode == 200) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contraseña de ${user['username']} actualizada')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al actualizar contraseña')),
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
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario', style: TextStyle(color: Colors.redAccent)),
        content: Text(
          '¿Estás seguro de que quieres eliminar a "${user['username']}"?\n\nEsta acción también eliminará todas sus parcelas y telemetría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _apiClient.deleteUser(user['id'] as int);
      if (response.statusCode == 204) {
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario "${user['username']}" eliminado')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar el usuario')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B4314), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(color: Color(0xFF1B4314), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B6043)))
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              color: const Color(0xFF3B6043),
              child: _users.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No hay usuarios registrados', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = _users[index] as Map<String, dynamic>;
                        final role = user['role'] as String? ?? 'farmer';
                        final isAdmin = role == 'admin';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              // Avatar con color por rol
                              CircleAvatar(
                                backgroundColor: _roleColor(role).withOpacity(0.15),
                                child: Icon(_roleIcon(role), color: _roleColor(role), size: 22),
                              ),
                              const SizedBox(width: 14),
                              // Info del usuario
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['username'] as String? ?? '—',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _roleColor(role).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            role.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _roleColor(role),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ID: ${user['id']}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                    if (role == 'farmer') ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.eco_rounded, size: 12, color: Color(0xFF556B52)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Parcelas asignadas: ${user['parcel_count'] ?? 0}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Botones de acción (no disponibles para admins)
                              if (!isAdmin) ...[
                                IconButton(
                                  icon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF3B6043)),
                                  tooltip: 'Cambiar contraseña',
                                  onPressed: () => _showEditPasswordDialog(user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  tooltip: 'Eliminar usuario',
                                  onPressed: () => _confirmDeleteUser(user),
                                ),
                              ] else
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Icon(Icons.shield_rounded, color: Color(0xFF1B4314), size: 20),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B6043),
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Nuevo Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
