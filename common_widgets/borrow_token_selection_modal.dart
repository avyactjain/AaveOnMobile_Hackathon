import 'package:AaveOnMobile/app/aave/aave_utils/aave_utils.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BorrowTokenSelectionModal extends StatefulWidget {
  final List borrowTokensMapList;
  final Function(Map) onTokenChanged;

  BorrowTokenSelectionModal(
      {@required this.borrowTokensMapList, @required this.onTokenChanged});
  @override
  _BorrowTokenSelectionModalState createState() =>
      _BorrowTokenSelectionModalState();
}

class _BorrowTokenSelectionModalState extends State<BorrowTokenSelectionModal> {
  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    // print(widget.borrowTokensMapList);

    List _canBorrowTokensList = widget.borrowTokensMapList.where((tokenMap) =>
        tokenMap["data"]["borrowRateType"] != BorrowRateType.none).toList();

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
                          _temp["token"] = _canBorrowTokensList[position]["name"];
                          _temp["borrowRateType"] = _canBorrowTokensList[position]["data"]["borrowRateType"];
                          widget.onTokenChanged(_temp);
                          Navigator.of(context).pop();
                        },
                        dense: true,
                        leading: CryptoIcon(
                          height: 36,
                          width: 36,
                          token: _canBorrowTokensList[position]["name"],
                        ),
                        title: Text(
                          _canBorrowTokensList[position]["name"],
                          style: Theme.of(context).textTheme.headline1,
                        ),
                        subtitle: Text(
                          _canBorrowTokensList[position]["data"]
                                  ["maxTokensToBorrow"]
                              .toString(),
                        ),
                        trailing: _usdBox(
                            _canBorrowTokensList[position]["name"],
                            _canBorrowTokensList[position]["data"]
                                    ["maxTokensToBorrow"]
                                .toString()));
                  },
                  separatorBuilder: (context, positoin) {
                    return Divider(
                      // color: Colours.bg_gray,
                      endIndent: 10,
                      indent: 10,
                    );
                  },
                  itemCount: _canBorrowTokensList.length))
        ],
      ),
    );
  }
}
