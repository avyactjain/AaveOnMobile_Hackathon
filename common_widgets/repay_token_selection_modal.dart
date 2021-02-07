import 'package:AaveOnMobile/app/aave/aave_utils/aave_utils.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RepayTokenSelectionModal extends StatefulWidget {
  final List borrowTokensMapList;
  final Function(Map) onTokenChanged;

  RepayTokenSelectionModal(
      {@required this.borrowTokensMapList, @required this.onTokenChanged});
  @override
  _RepayTokenSelectionModalState createState() =>
      _RepayTokenSelectionModalState();
}

class _RepayTokenSelectionModalState extends State<RepayTokenSelectionModal> {
  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    // print(widget.borrowTokensMapList);

    Widget _usdBox(String token, String amt) {
      return FutureBuilder(
          future: appCacheProvider.getTokenSpotPrice(token),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              try {
                double _spotRate = double.tryParse(snapshot.data.toString());
                double _amt = double.tryParse(amt);

                double _usdAmt = _spotRate * _amt;

                String _usdString = usdFormatter.format(_usdAmt);

                return Text(
                  "\$" + _usdString,
                  style: Theme.of(context).textTheme.headline1,
                );
              } on Exception catch (_) {} catch (e) {}
              return Text(
                snapshot.data.toString(),
              );
            }
            return Text("");
          });
    }

    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
          ),
          Text(
            "Select a token",
            style: Theme.of(context).textTheme.headline2,
            textAlign: TextAlign.start,
          ),
          SizedBox(
            height: 20,
          ),
          Expanded(
              child: ListView.separated(
                  itemBuilder: (context, position) {
                    return ListTile(
                        onTap: () {
                          Map _temp = {};
                          _temp["name"] =
                              widget.borrowTokensMapList[position]["name"];
                          _temp["amt"] = widget.borrowTokensMapList[position]
                              ["data"]["amt"];
                          widget.onTokenChanged(_temp);
                          Navigator.of(context).pop();
                        },
                        dense: true,
                        leading: CryptoIcon(
                          height: 36,
                          width: 36,
                          token: widget.borrowTokensMapList[position]["name"],
                        ),
                        title: Text(
                          widget.borrowTokensMapList[position]["name"],
                          style: Theme.of(context).textTheme.headline1,
                        ),
                        subtitle: Text(
                          widget.borrowTokensMapList[position]["data"]["amt"]
                              .toString(),
                        ),
                        trailing: _usdBox(
                            widget.borrowTokensMapList[position]["name"],
                            widget.borrowTokensMapList[position]["data"]["amt"]
                                .toString()));
                  },
                  separatorBuilder: (context, positoin) {
                    return Divider(
                      // color: Colours.bg_gray,
                      endIndent: 10,
                      indent: 10,
                    );
                  },
                  itemCount: widget.borrowTokensMapList.length))
        ],
      ),
    );
  }
}
