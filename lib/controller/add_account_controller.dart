import 'package:base32/base32.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:dome_2fa/core/one_time_password.dart';
import 'package:provider/provider.dart';
import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/model/accounts_service.dart';
import 'package:dome_2fa/view/util.dart';

mixin AddAccountController {
  final GlobalKey pageKey = GlobalKey();

  final GlobalKey<FormState> accountFormKey = GlobalKey<FormState>();
  final TextEditingController secretCtrl = TextEditingController();
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController issuerCtrl = TextEditingController();
  HashAlgorithm selectedAlgorithm = HashAlgorithm.sha1;
  int duration = 30;

  void onFormConfirm(BuildContext context) async {
    if(!(accountFormKey.currentState?.validate() ?? false)) {
      return;
    }
    var dismiss = showLoadingIndicator(context);
    var accountsService = Provider.of<AccountsService>(context, listen: false);

    var acc = Account(
        secretCtrl.text,
        label: labelCtrl.text,
        issuer: issuerCtrl.text,
        duration: duration,
        alg: selectedAlgorithm
    );
    await accountsService.accountDb?.insert(acc);

    dismiss();
    if(context.mounted) {
      Navigator.of(context).pop();
    }
  }

  String? validateDuration(String? val) {
    if (val == null && duration > 0) return null;
    if (val != null && val.isNotEmpty) {
      var duration = int.tryParse(val);
      if (duration != null && duration > 0) {
        return null;
      }
    }
    return "Duration must be greater than 1";
  }

  String? validateIssuer(String? val) {
    if(val == null || val.isEmpty) {
      return "Issuer must not be empty";
    }
    return null;
  }

  String? validateSecret(String? val) {
    if(val == null || val.isEmpty) {
      return "Secret must not be emtpy";
    }
    try{
      base32.decode(val);
    } catch (e) {
      return "Secret must be valid Base32";
    }
    return null;
  }

  String? validateLabel(String? val, BuildContext context) {
    if(val == null || val.isEmpty) {
      return null;
    }
    var accountsModel = Provider.of<AccountsService>(context, listen: false);
    if (accountsModel.accountDb!.accounts.any((a) => a.label == val)) {
      return "Label already exists";
    }
    return null;
  }
}