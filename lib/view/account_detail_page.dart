import 'package:dome_2fa/controller/accounts_controller.dart';
import 'package:dome_2fa/view/token.dart';
import 'package:dome_2fa/view/util.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:dome_2fa/core/account/account.dart';
import 'package:flutter/services.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.account});

  final Account account;

  @override
  State<StatefulWidget> createState() => AccountDetailPageState();
}

class AccountDetailPageState extends State<AccountDetailPage> with AccountsController {

  var deleteBtnStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.red)
  );

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: pageKey,
      header: buildPageScaffoldHeader(context, widget.account.label),
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      spacing: 5,
      children: [
        _buildTokenDisplay(context),
        _buildEditCard(context),
        _buildActionCard(context)
      ],
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(child: FilledButton(
                onPressed: () => deleteAccount(widget.account, _buildDeleteConfirmDialog),
                style: deleteBtnStyle,
                child: const Text("Delete")
              ))
            ],
          )
        ],
      )
    );
  }

  Widget _buildDeleteConfirmDialog(BuildContext context) {
    return ContentDialog(
      title: const Text("Confirm Deletion"),
      actions: [
        Button(onPressed: Navigator.of(context).pop, child: const Text("Cancel")),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: deleteBtnStyle,
          child: const Text("Delete"),
        )
      ],
    );
  }

  Widget _buildTokenDisplay(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.account.generateToken()));
            showMessageSnackbar("Copied to clipboard", pageKey.currentContext!);
          },
          child: TokenWithLifetime(account: widget.account, fontSize: 45, barBelow: true),
        )
      )
    );
  }

  Widget _buildEditCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        spacing: 8,
        children: [
          InfoLabel(
            label: "Issuer",
            child: TextBox(readOnly: true, controller: TextEditingController(text: widget.account.issuer))
          ),
          InfoLabel(
            label: "Label",
            child: TextBox(readOnly: true, controller: TextEditingController(text: widget.account.label)),
          )
        ],
      )
    );
  }
}