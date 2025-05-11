import 'package:dome_2fa/core/preferences.dart';
import 'package:dome_2fa/model/accounts_service.dart';
import 'package:dome_2fa/view/accounts_page.dart';
import 'package:dome_2fa/view/db_login_page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var preferences = await UserPreferences.create();

  runApp(MultiProvider(
    providers: [
      Provider<Preferences>.value(value: preferences),
      ChangeNotifierProvider<AccountsService>(
        create: (context) => AccountsService(preferences)
      )
    ],
    child: App()
  ));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountsService>(context, listen: false).addListener(_onAccountsDbChange);
    });
  }

  @override
  void dispose() {
    Provider.of<AccountsService>(context, listen: false).removeListener(_onAccountsDbChange);
    super.dispose();
  }

  void _onAccountsDbChange() {
    if(navigatorKey.currentState == null) return;
    final accountModel = Provider.of<AccountsService>(context, listen: false);
    FluentPageRoute page;
    if(accountModel.accountDb != null) {
      page = FluentPageRoute(builder: (context) => AccountsPage());
    } else {
      page = FluentPageRoute(builder: (context) => DbLoginPage());
    }
    navigatorKey.currentState?.pushReplacement(page);
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      navigatorKey: navigatorKey,
      title: "Dome2FA",
      themeMode: ThemeMode.light,
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
        scaffoldBackgroundColor: Color.fromARGB(255, 243, 243, 243),
      ),
      home: DbLoginPage(),
      builder: (context, child) => AnnotatedRegion(
        value: SystemUiOverlayStyle(
          statusBarColor: FluentTheme.of(context).scaffoldBackgroundColor,
          statusBarIconBrightness: Brightness.dark
        ),
        // For whatever reason, setting the status bar color above
        // has no effect. We color the safe area directly because of that.
        child: Container(
          color: FluentTheme.of(context).scaffoldBackgroundColor,
          child: SafeArea(child: child!),
        )
      ),
    );
  }
}
