import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CollateralSettingItem extends StatefulWidget {
  final String token;
  final String amount;
  final String amountUsd;
  final String iconUrl;
  final bool usedAsCollateral;
  final Function(String, bool) onTogglePressed;

  CollateralSettingItem({
    @required this.token,
    @required this.amount,
    @required this.iconUrl,
    @required this.amountUsd,
    @required this.usedAsCollateral,
    @required this.onTogglePressed,
  });
  @override
  _CollateralSettingItemState createState() => _CollateralSettingItemState();
}

class _CollateralSettingItemState extends State<CollateralSettingItem> {
  bool _usedAsCollateral;

  @override
  void initState() {
    _usedAsCollateral = widget.usedAsCollateral;
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        width: 36,
        height: 36,
        imageUrl: widget.iconUrl,
        errorWidget: (_, x, e) => Container(),
      ),
      title: Text(
        widget.token,
        style: Theme.of(context).textTheme.headline1,
      ),
      subtitle: Text(
        "\$" + widget.amountUsd,
        style: Theme.of(context).textTheme.subtitle2,
      ),
      trailing: CupertinoSwitch(
          value: _usedAsCollateral,
          onChanged: (_) {
            setState(() {
              _usedAsCollateral = !_usedAsCollateral;
            });
            widget.onTogglePressed(widget.token, _);
          }),
    );
  }
}
