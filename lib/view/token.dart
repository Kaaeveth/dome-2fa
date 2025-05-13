import 'dart:async';
import 'dart:ui';

import 'package:dome_2fa/core/account/account.dart';
import 'package:fluent_ui/fluent_ui.dart';

class Token extends StatelessWidget {
  final String token;
  final double fontSize;

  const Token({super.key, required this.token, this.fontSize=20});

  @override
  Widget build(BuildContext context) {
    var style = FluentTheme.of(context);

    var textStyle = TextStyle(
      color: style.accentColor,
      overflow: TextOverflow.clip,
      fontSize: fontSize,
      fontWeight: FontWeight.bold
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 5,
      children: [
        Text(token.substring(0, 3), style: textStyle),
        Text(token.substring(3), style: textStyle)
      ],
    );
  }
}

class TokenWithLifetime extends StatefulWidget {
  final Account account;
  final double fontSize;
  final bool barBelow;

  const TokenWithLifetime({
    super.key,
    required this.account,
    this.fontSize=20,
    this.barBelow=false
  });

  @override
  State<StatefulWidget> createState() => TokenWithLifetimeState();
}

class TokenWithLifetimeState extends State<TokenWithLifetime> {

  int _tokenLifetime = 30;
  String _token = "";
  Timer? _timer;

  @override
  void initState() {
    setState(_updateToken);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if(--_tokenLifetime < 1) {
          _updateToken();
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateToken() {
    final acc = widget.account;
    _token = acc.generateToken();
    _tokenLifetime = acc.getRemainingTime();
  }

  double get _percentTokenLifetime => clampDouble(_tokenLifetime / widget.account.duration * 100, 0.0, 100.0);

  @override
  Widget build(BuildContext context) {
    return widget.barBelow ? _buildWithBottomBar(context) : _buildDefault(context);
  }

  Widget _buildDefault(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Token(token: _token, fontSize: widget.fontSize),
        ProgressRing(value: _percentTokenLifetime),
      ],
    );
  }

  Widget _buildWithBottomBar(BuildContext context) {
    return Column(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Token(token: _token, fontSize: widget.fontSize),
        ProgressBar(value: _percentTokenLifetime, strokeWidth: 8)
      ],
    );
  }
}