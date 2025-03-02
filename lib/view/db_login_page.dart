import 'package:dome_2fa/controller/db_login_controller.dart';
import 'package:dome_2fa/model/accounts_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class DbLoginPage extends StatelessWidget with DbLoginController {
  DbLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    var accDb = Provider.of<AccountsService>(context, listen: false);

    // Check if we can login using saved password
    // else if just show the login/register form
    var checkPwdWidget = FutureBuilder(
      future: accDb.tryOpenWithSavedPassword(),
      builder: (context, snapshot) {
        if(snapshot.hasData && !snapshot.data!) {
          return accDb.dbExists ? _buildPasswordInputPage(context) : _buildPasswordCreatePage(context);
        }
        // If tryOpenWithSavedPassword succeeds, the navigator will automatically
        // go to the correct page. We don't need to do anything more here.
        return ProgressRing();
      },
    );

    return ScaffoldPage(
      content: _buildScaffold(context, checkPwdWidget),
    );
  }

  Widget _buildScaffold(BuildContext context, Widget pageContent) {
    return Center(
      child: SizedBox(
        width: 350,
        height: 200,
        child: Card(
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            spacing: 8,
            children: [
              pageContent,
              Row(children: [
                  Expanded(child: FilledButton(onPressed: () => unlockOrCreateDatabase(context), child: const Text("Confirm")))
                ]
              )
            ],
          )
        ),
      ),
    );
  }

  Widget _buildPasswordInputPage(BuildContext context) {
    var titleStyle = FluentTheme.of(context).typography.subtitle;
    return Column(
      spacing: 10,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [Text("Unlock Database", style: titleStyle)]),
        PasswordBox(placeholder: "Password", controller: passwordCtrl, onSubmitted: (_) => unlockOrCreateDatabase(context))
      ],
    );
  }

  Widget _buildPasswordCreatePage(BuildContext context) {
    var titleStyle = FluentTheme.of(context).typography.subtitle;
    return Column(
      spacing: 6.5,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [Text("Choose Database Password", style: titleStyle)]),
        PasswordBox(placeholder: "Password", controller: passwordCtrl),
        PasswordBox(placeholder: "Repeat Password", controller: confirmPasswordCtrl, onSubmitted: (_) => unlockOrCreateDatabase(context))
      ],
    );
  }
}