import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../domain/login_usecase.dart';
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validaciones frontend
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Todos los campos son obligatorios.');
      return;
    }

    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog('Introduce un correo electrónico válido.');
      return;
    }

    setState(() => _loading = true);
    final loginUseCase = GetIt.I<LoginUseCase>();

    try {
      if (_isLogin) {
        await loginUseCase.login(email, password);
      } else {
        throw UnimplementedError('Registro no implementado todavía');
      }
    } catch (e) {
      _showErrorDialog(
        e.toString().contains('invalid_credentials')
            ? 'Credenciales incorrectas. Verifica tu email y contraseña.'
            : 'Ocurrió un error: ${e.toString()}',
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Planner')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Correo electrónico'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Contraseña'),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _handleAuth,
                child: Text(_loading
                    ? 'Cargando...'
                    : _isLogin
                    ? 'Iniciar sesión'
                    : 'Registrarse'),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
