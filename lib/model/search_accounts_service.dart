import 'package:dome_2fa/core/account/account.dart';
import 'package:flutter/foundation.dart';

class SearchAccountsService extends ChangeNotifier {
  AccountDb _accountDb;
  String _searchStr = "";
  final List<Account> _matchedAccounts = List.empty(growable: true);

  SearchAccountsService._internal(this._accountDb);

  /// Constructs a new search service for filtering Accounts in [accountDb]
  /// based on their issuer.
  /// When the DB changes, the search is resetted by setting [currentSearchStr]
  /// to the empty string.
  factory SearchAccountsService(AccountDb accountDb) {
    var service = SearchAccountsService._internal(accountDb);
    accountDb.addListener(service._onAccountsChanged);
    return service;
  }

  /// The current query for [matchingAccounts].
  String get currentSearchStr => _searchStr;

  /// Whether there is a filter active, i.e. [currentSearchStr] is not empty.
  bool get hasSearch => _searchStr.isNotEmpty;

  /// The current accounts matching [currentSearchStr].
  Iterable<Account> get matchingAccounts =>
      hasSearch ? _matchedAccounts : _accountDb.accounts;

  /// Updates [matchingAccounts] with accounts matching issuers
  /// according to the [searchStr].
  /// If the [searchStr] is empty, then [matchingAccounts] simply returns
  /// all accounts in the given [AccountDb].
  /// After searching the DB, all listeners will be notified.
  void updateSearch(String searchStr) {
    _searchStr = searchStr;
    _matchedAccounts.clear();

    if(searchStr.isNotEmpty) {
      searchStr = searchStr.toLowerCase();

      for (var acc in _accountDb.accounts) {
        var issuer = acc.issuer.toLowerCase();
        // TODO: use fuzzy matching instead
        if(searchStr.contains(issuer) || issuer.contains(searchStr)) {
          _matchedAccounts.add(acc);
        }
      }
    }

    notifyListeners();
  }

  void _onAccountsChanged() {
    _searchStr = "";
    notifyListeners();
  }

  @override
  void dispose() {
    _accountDb.removeListener(_onAccountsChanged);
    super.dispose();
  }
}