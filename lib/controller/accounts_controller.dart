import 'dart:io';

import 'package:dome_2fa/core/util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:dome_2fa/model/accounts_service.dart';
import 'package:dome_2fa/view/util.dart';
import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/view/add_account_form_page.dart';
import 'package:dome_2fa/view/qr_scanner_page.dart';

mixin AccountsController {

  final GlobalKey pageKey = GlobalKey();

  void exportAccounts(BuildContext context) async {
    var dismiss = showLoadingIndicator(context);
    var accountsModel = Provider.of<AccountsService>(context, listen: false);

    if(isDesktop) {
      var saveFilePath = await FilePicker.platform.saveFile(
          dialogTitle: "Select export path",
          fileName: AccountsService.DB_NAME,
          lockParentWindow: true
      );
      if (saveFilePath != null) {
        try {
          await accountsModel.exportDatabase(saveFilePath);
        } catch (e) {
          await showMessage(e.toString(), "Error", pageKey.currentContext!);
        }
      }
    } else {
      await FilePicker.platform.saveFile(
        dialogTitle: "Select export path",
        fileName: AccountsService.DB_NAME,
        lockParentWindow: true,
        bytes: await File(accountsModel.dbPath).readAsBytes()
      );
    }

    dismiss();
    if(context.mounted) {
      showMessageSnackbar("Accounts exported", context);
    }
  }

  void importAccounts(BuildContext context) async {
    var dismiss = showLoadingIndicator(context);
    var accountsModel = Provider.of<AccountsService>(context, listen: false);
    var filePath = await FilePicker.platform.pickFiles(
        lockParentWindow: true,
        dialogTitle: "Select database file",
        allowedExtensions: isDesktop ? ["db"] : null,
        type: isDesktop ? FileType.custom : FileType.any
    );

    if(filePath != null && context.mounted) {
      // Prompt password
      String? password = await showDialog(
          context: context,
          builder: (context) {
            var pwdInput = TextEditingController();
            return ContentDialog(
              content: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 30),
                  child: PasswordBox(placeholder: "Password", controller: pwdInput)
              ),
              actions: [
                Button(onPressed: Navigator.of(context).pop, child: const Text("Cancel")),
                FilledButton(child: const Text("Confirm"), onPressed: () {
                  var pwd = pwdInput.text;
                  pwdInput.dispose();
                  Navigator.of(context).pop(pwd);
                })
              ],
            );
          }
      );

      if(password != null) {
        assert (filePath.isSinglePick);
        try {
          await accountsModel.importDatabase(filePath.paths.first!, password);
          showMessageSnackbar("Imported Accounts", pageKey.currentContext!);
        } catch (e) {
          await showMessage(e.toString(), "Error", pageKey.currentContext!);
        }
      }
    }

    dismiss();
  }

  void gotoAddAccount(BuildContext context) {
    Flyout.of(context).close();
    Navigator.of(context).push(
        FluentPageRoute(builder: (context) => AddAccountFormPage())
    );
  }

  void closeDb(BuildContext context) {
    var accountService = Provider.of<AccountsService>(context, listen: false);
    accountService.closeDb();
  }

  void toggleRememberPassword(BuildContext context) {
    var accountService = Provider.of<AccountsService>(context, listen: false);
    if(accountService.dbPasswordSaved.value) {
      accountService.forgetDbPassword();
    } else {
      accountService.rememberDbPassword();
    }
  }

  Future<void> addAccountFromQr(BuildContext context) async {
    var accountsModel = Provider.of<AccountsService>(context, listen: false);
    Flyout.of(context).close();
    Account? res = await Navigator.of(context).push(
        FluentPageRoute(builder: (context) => QrScannerPage())
    );

    if(res != null) {
      var dismiss = showLoadingIndicator(pageKey.currentContext!);
      try {
        await accountsModel.accountDb?.insert(res);
      } catch (e) {
        if (kDebugMode) {
          print(e.toString());
        }
        await showMessage(e.toString(), "Error", pageKey.currentContext!);
      } finally {
        dismiss();
      }
    }
  }

  void deleteAccount(Account acc, Widget Function(BuildContext) buildConfirmDeleteDialog) async {
    var confirmDelete = await showDialog<bool>(
      context: pageKey.currentContext!,
      builder: buildConfirmDeleteDialog,
    );

    if(!(confirmDelete ?? false) || !pageKey.currentContext!.mounted) {
      return;
    }
    var accountDb = Provider.of<AccountsService>(pageKey.currentContext!, listen: false).accountDb!;
    Navigator.of(pageKey.currentContext!).pop();
    await accountDb.delete(acc);
  }
}
