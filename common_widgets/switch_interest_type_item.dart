import 'package:AaveOnMobile/app/aave/aave_models/aave_pool.dart';
import 'package:AaveOnMobile/common_widgets/FirebaseStreamObserver.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/services/firebase_streams.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class SwitchInterestTypeItem extends StatefulWidget {
  final String name;
  final String symbol;
  final String iconUrl;
  final InterestType interestType;
  final Function(String token, InterestType interestType)
      onInterestChangeTapped;

  SwitchInterestTypeItem({
    @required this.name,
    @required this.iconUrl,
    @required this.symbol,
    @required this.interestType,
    @required this.onInterestChangeTapped,
  });

  @override
  _SwitchInterestTypeItemState createState() => _SwitchInterestTypeItemState();
}

class _SwitchInterestTypeItemState extends State<SwitchInterestTypeItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      // leading: CryptoIcon(
      //   height: 36,
      //   width: 36,
      //   token: widget.name,
      // ),
      leading: CachedNetworkImage(
        height: 36,
        width: 36,
        imageUrl: widget.iconUrl,
        errorWidget: (_, s, d) {
          return Container();
        },
      ),
      title: FittedBox(
        // fit: FlexFit.tight,
        child: Text(
          widget.name,
          style: Theme.of(context).textTheme.headline1,
        ),
      ),

      subtitle: Container(
        height: 40,
        width: 80,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.interestType == InterestType.variable
                    ? "Variable Interest"
                    : "Stable Interest",
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
            widget.interestType == InterestType.variable
                ? Expanded(child: _VariableInterestText(token: widget.symbol))
                : Expanded(child: _StableInterestText(token: widget.symbol))
            // Text("3%")
          ],
        ),
      ),
      trailing: Container(
        height: 65,
        width: 130,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white30)),
        padding: EdgeInsets.all(8),
        child: InkWell(
          onTap: () {
            widget.onInterestChangeTapped(
              widget.symbol,
              widget.interestType,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  widget.interestType == InterestType.stable
                      ? "Switch To Variable"
                      : "Switch To Stable",
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
              widget.interestType == InterestType.stable
                  ? Expanded(child: _VariableInterestText(token: widget.symbol))
                  : Expanded(child: _StableInterestText(token: widget.symbol))
            ],
          ),
        ),
      ),
    );
  }
}

class _StableInterestText extends StatefulWidget {
  final String token;
  _StableInterestText({@required this.token});

  @override
  __StableInterestTextState createState() => __StableInterestTextState();
}

class __StableInterestTextState extends State<_StableInterestText> {
  @override
  Widget build(BuildContext context) {
    final streams = Provider.of<FirebaseStreams>(context, listen: false);
    Stream<Event> _dataStream = streams.getAavePoolStream(symbol: widget.token == "WETH" ? "ETH" : widget.token);
    return Container(
      child: FirebaseStreamObserver(
        onError: (_) {
          return Container();
        },
        stream: _dataStream,
        onSuccess: (context, event) {
          if (event.snapshot.value != null) {
            AavePool _aavePool = AavePool.fromMap(event.snapshot.value);
            print(_aavePool.availableLiquidity);
            return Container(
                child: Text(
              _aavePool.stableBorrowRate.toString() + "%",
              style: Theme.of(context).textTheme.subtitle2,
            ));
          }
          return Container();
        },
      ),
    );
  }
}

class _VariableInterestText extends StatefulWidget {
  final String token;
  _VariableInterestText({@required this.token});
  @override
  __VariableInterestTextState createState() => __VariableInterestTextState();
}

class __VariableInterestTextState extends State<_VariableInterestText> {
  @override
  Widget build(BuildContext context) {
    final streams = Provider.of<FirebaseStreams>(context, listen: false);
    Stream<Event> _dataStream = streams.getAavePoolStream(symbol: widget.token == "WETH" ? "ETH" : widget.token);
    return Container(
      child: FirebaseStreamObserver(
        onError: (_) {
          return Container(
            height: 1,
            width: 1,
          );
        },
        stream: _dataStream,
        onSuccess: (context, event) {
          if (event.snapshot.value != null) {
            AavePool _aavePool = AavePool.fromMap(event.snapshot.value);
            return Container(
                child: Text(
              _aavePool.variableBorrowRate.toString() + "%",
              style: Theme.of(context).textTheme.subtitle2,
            ));
          }
          return Container();
        },
      ),
    );
  }
}
