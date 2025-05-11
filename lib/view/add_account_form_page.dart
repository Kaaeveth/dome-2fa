import 'package:dome_2fa/controller/add_account_controller.dart';
import 'package:dome_2fa/core/one_time_password.dart';
import 'package:fluent_ui/fluent_ui.dart';

class AddAccountFormPage extends StatelessWidget with AddAccountController {
  AddAccountFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    var headingStyle = FluentTheme.of(context).typography.title;
    return ScaffoldPage(
      key: pageKey,
      padding: const EdgeInsets.all(0),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          spacing: 10.0,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Text("Add Token", style: headingStyle)],
            ),
            _buildForm(context)
          ],
        ),
      )
    );
  }

  Widget _buildForm(BuildContext context) {
    return Card(
      padding: EdgeInsets.all(12.0),
      child: Form(
        key: accountFormKey,
        child: Column(
          spacing: 10.0,
          children: [
            TextFormBox(
              controller: secretCtrl,
              placeholder: "Secret",
              validator: validateSecret,
              autovalidateMode: AutovalidateMode.onUnfocus,
              onChanged: (v) {
                secretCtrl.text = v.toUpperCase();
                secretCtrl.selection = TextSelection.collapsed(offset: v.length);
              },
            ),
            TextFormBox(
              controller: issuerCtrl,
              placeholder: "Issuer",
              autovalidateMode: AutovalidateMode.onUnfocus,
              validator: validateIssuer,
            ),
            TextFormBox(
              controller: labelCtrl,
              placeholder: "Label (optional)",
              validator: (val) =>  validateLabel(val, context),
              autovalidateMode: AutovalidateMode.onUnfocus,
            ),
            Row(
              children: [
                const Text("Duration: "),
                Flexible(child: NumberFormBox(
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  precision: 0,
                  min: 1,
                  value: duration,
                  mode: SpinButtonPlacementMode.inline,
                  validator: validateDuration,
                  onChanged: (v) => duration = v ?? 1,
                ))
              ],
            ),
            Row(
              spacing: 5,
              children: [
                const Text("Algorithm: "),
                ComboboxFormField(
                  items: _algorithmFields(context),
                  onChanged: (val) => selectedAlgorithm = val!,
                  value: HashAlgorithm.sha1
                )
              ],
            ),
            Row(
              spacing: 5.0,
              children: [
                Expanded(child: Button(onPressed: Navigator.of(context).pop, child: const Text("Cancel"))),
                Expanded(child: FilledButton(onPressed: () => onFormConfirm(context), child: const Text("Confirm")))
              ],
            )
          ],
        ),
      )
    );
  }

  List<ComboBoxItem<HashAlgorithm>> _algorithmFields(BuildContext context) {
    return HashAlgorithm.values.map((val) =>
        ComboBoxItem(value: val, child: Text(val.name.toUpperCase()))
    ).toList();
  }
}