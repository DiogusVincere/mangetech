import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/cadastro_screen.dart';
import 'ui/screens/recuperacao_senha_screen.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/dashboardgerencial_screen.dart';
import 'ui/screens/gestao_ativos_screen.dart';
import 'ui/screens/visualizar_perfil.dart';
import 'data/providers/chamado_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/ativo_provider.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (_) => ChamadoProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AtivoProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Chamados App',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            initialRoute: '/login',
            onGenerateRoute: (settings) {
              // Rotas com animação customizada
              switch (settings.name) {
                case '/login':
                  return MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                    settings: settings,
                  );
                case '/cadastro':
                  return MaterialPageRoute(
                    builder: (_) => const CadastroScreen(),
                    settings: settings,
                  );
                case '/esqueci-senha':
                  return MaterialPageRoute(
                    builder: (_) => const RecuperacaoSenhaScreen(),
                    settings: settings,
                  );
                case '/dashboard':
                  return MaterialPageRoute(
                    builder: (_) => const DashboardScreen(),
                    settings: settings,
                  );
                case '/dashboard-gerencial':
                  return MaterialPageRoute(
                    builder: (_) => const DashboardGerencialScreen(),
                    settings: settings,
                  );
                case '/gestao-ativos':
                  return MaterialPageRoute(
                    builder: (_) => const GestaoAtivosScreen(),
                    settings: settings,
                  );
                case '/perfil':
                  return MaterialPageRoute(
                    builder: (_) => const PerfilScreen(),
                    settings: settings,
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                    settings: settings,
                  );
              }
            },
          );
        },
      ),
    );
  }
}