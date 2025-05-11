import 'package:fluent_ui/fluent_ui.dart';

void Function() showLoadingIndicator(BuildContext context) {
  BuildContext? dialogCtx;
  showDialog(
      context: context,
      builder: (context) {
        dialogCtx = context;
        return const Center(
          child: ProgressRing(),
        );
      },
      dismissWithEsc: false
  );

  return () {
    // If the dialog is being dismissed before even being shown,
    // the dialog context will be null but their will be still
    // a new entry in the widget tree which we need to pop.
    if(dialogCtx?.mounted ?? false) {
      Navigator.of(dialogCtx!).pop();
    } else {
      Navigator.of(context).pop();
    }
  };
}

Future<void> showMessage(String msg, String title, BuildContext context) async {
  await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ContentDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text("Confirm"))
        ],
      )
  );
}

void showMessageSnackbar(String msg, BuildContext context, {Duration duration = const Duration(seconds: 2)}) {
  displayInfoBar(
    context,
    builder: (context, close) => InfoBar(title: Text(msg)),
    duration: duration
  );
}

Widget buildPageScaffoldHeader(BuildContext context, String title) {
  var btnStyle = FluentTheme.of(context).typography.subtitle;
  return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        spacing: 15,
        children: [
          IconButton(icon: const Icon(FluentIcons.back), onPressed: Navigator.of(context).pop),
          Flexible(child: Text(title, style: btnStyle, overflow: TextOverflow.ellipsis))
        ],
      )
  );
}
