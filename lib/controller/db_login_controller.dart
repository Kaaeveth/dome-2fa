import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:dome_2fa/model/accounts_service.dart';
import 'package:dome_2fa/view/util.dart';

mixin DbLoginController {
  final GlobalKey pageKey = GlobalKey();

  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  void unlockOrCreateDatabase(BuildContext context) async {
    var accounts = Provider.of<AccountsService>(context, listen: false);
    if(!accounts.dbExists) {
      // Creating new DB - Check if passwords match
      if(passwordCtrl.text != confirmPasswordCtrl.text || passwordCtrl.text.isEmpty) {
        await showMessage("Passwords do not match", "Error", context);
        return;
      }
    } else if(passwordCtrl.text.isEmpty) {
      await showMessage("Password is empty!", "Error", context);
      return;
    }

    var dismiss = showLoadingIndicator(context);
    try {
      await accounts.createOrOpenDatabase(passwordCtrl.text);
    } catch (e){
      await showMessage(e.toString(), "Error", pageKey.currentContext!);
      dismiss();
      return;
    }
  }
}