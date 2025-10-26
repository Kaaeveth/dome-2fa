import 'package:dome_2fa/controller/accounts_controller.dart';
import 'package:dome_2fa/core/util.dart';
import 'package:dome_2fa/model/accounts_service.dart';
import 'package:dome_2fa/model/search_accounts_service.dart';
import 'package:dome_2fa/view/account_detail_page.dart';
import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/view/token.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});
  @override
  State<StatefulWidget> createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> with AccountsController {

  final FlyoutController _menuController = FlyoutController();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: pageKey,
      padding: const EdgeInsets.all(0),
      header: _buildHeader(context),
      content: ChangeNotifierProvider(
        create: (context) {
          var accDb = Provider.of<AccountsService>(context, listen: false).accountDb!;
          var searchService = SearchAccountsService(accDb);
          _searchController.addListener(() => searchService.updateSearch(_searchController.text));
          return searchService;
        },
        builder: (context, child) => _buildAccountList(context, child)
      )
    );
  }

  Widget _buildAccountList(BuildContext context, Widget? child) {
    return Consumer2<SearchAccountsService, AccountsService>(
        builder: (context, accountSearch, accountsService, child) =>
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: ReorderableListView.builder(
              itemCount: accountSearch.matchingAccounts.length,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final acc = accountSearch.matchingAccounts.elementAt(index);
                return ReorderableDragStartListener(
                    index: index,
                    key: ValueKey(index),
                    child: ListTile.selectable(
                      title: Text(acc.issuer, overflow: TextOverflow.ellipsis),
                      subtitle: Text(acc.label, overflow: TextOverflow.ellipsis),
                      trailing: TokenWithLifetime(account: acc),
                      onPressed: () => openAccountDetails(acc),
                    )
                );
              },
              onReorder: (oldIdx, newIdx) async {
                if (oldIdx < newIdx) {
                  --newIdx;
                }
                await accountsService.accountDb?.changeAccountOrder(oldIdx, newIdx);
              },
              //separatorBuilder: (context, index) => const Divider(),
            ),
          )
    );
  }
  
  void openAccountDetails(Account acc) {
    Navigator.of(context).push(
      FluentPageRoute(builder: (_) => AccountDetailPage(account: acc))
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(6.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: TextBox(placeholder: "Search...", controller: _searchController)),
          FlyoutTarget(
            controller: _menuController,
            child: Button(
              child: const Icon(FluentIcons.more_vertical),
              onPressed: () => _menuController.showFlyout(
                builder: (context) => MenuFlyout(
                  items: [
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.add),
                      text: const Text("Add Token manually"),
                      onPressed: () => gotoAddAccount(context)
                    ),
                    if(!isDesktop) MenuFlyoutItem(
                      leading: const Icon(FluentIcons.add),
                      text: const Text("Add Token using QR-Code"),
                      onPressed: () => addAccountFromQr(context)
                    ),
                    const MenuFlyoutSeparator(),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.export),
                      text: const Text("Export Accounts"),
                      onPressed: () => exportAccounts(context)
                    ),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.import),
                      text: const Text("Import Accounts"),
                      onPressed: () => importAccounts(context)
                    ),
                    const MenuFlyoutSeparator(),
                    MenuFlyoutItem(
                      leading: ListenableProvider(
                        create: (BuildContext context) {
                          var accService = Provider.of<AccountsService>(context, listen: false);
                          return accService.dbPasswordSaved;
                        },
                        builder: (context, child) {
                          var pwdSaved = context.watch<ValueNotifier<bool>>().value;
                          return Checkbox(checked: pwdSaved, onChanged: (_) => {});
                        }
                      ),
                      text: const Text("Remember Password"),
                      onPressed: () => toggleRememberPassword(context)
                    ),
                    const MenuFlyoutSeparator(),
                    MenuFlyoutItem(
                      leading: const Icon(FluentIcons.clear),
                      text: const Text("Close DB"),
                      onPressed: () => closeDb(context)
                    )
                  ]
                )
              )
            )
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}