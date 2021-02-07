import 'package:AaveOnMobile/app/aave/aave_utils/aave_utils.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/switch_apy_review_modal.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/switch_interest_type_item.dart';

import 'package:AaveOnMobile/app/crypto/gas_fee_modal.dart';
import 'package:AaveOnMobile/app/wallet/wallet_data_viewmodel.dart';
import 'package:AaveOnMobile/crypto_utils/crypto_utls.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ChangeInterestTypeScreen extends StatefulWidget {
  @override
  _ChangeInterestTypeScreenState createState() =>
      _ChangeInterestTypeScreenState();
}

class _ChangeInterestTypeScreenState extends State<ChangeInterestTypeScreen> {
  Map localTxObj = {};
  String walletAddress;
  String gasFeeInGwei;

  String gasFeeString = "fast";
  Color gasFeeIconColor;

  String selectedToken;

  Future _mainFuture;

  @override
  void initState() {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);
    final walletDataProvider =
        Provider.of<WalletDataProvider>(context, listen: false);

    walletAddress = walletDataProvider.activeWallet.walletAddress;
    // walletAddress = "0xA5576138F067EB83C6Ad4080F3164b757DEB2737";

    gasFeeString = appCacheProvider.userPreferances["lastGasFeesString"];
    gasFeeIconColor = Color(int.parse(
        appCacheProvider.userPreferances["lastGasIconColor"],
        radix: 16));

    _mainFuture = appCacheProvider
        .getAaveWalletDistData(walletAddress: walletAddress)
        .then(
          (walletDist) => prepareAaveWalletDetails(walletDist),
        );

    // TODO: implement initState
    super.initState();
  }

//Implement this function
  @override
  void didChangeDependencies() {
    // ignore: todo
    // TODO: implement didChangeDependencies
    final walletDataProvider =
        Provider.of<WalletDataProvider>(context, listen: true);
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);
    // print(walletAddress);
    // print(walletDataProvider.activeWallet.walletAddress);

    if (walletAddress != walletDataProvider.activeWallet.walletAddress) {
      walletAddress = walletDataProvider.activeWallet.walletAddress;
      _mainFuture = appCacheProvider
          .getAaveWalletDistData(walletAddress: walletAddress)
          .then(
            (walletDist) => prepareAaveWalletDetails(walletDist),
          );
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    void onSwitchInterestButtonTapped(
        {String token, InterestType interestTypeToSwitchTo}) {
      Future _switchApyApiResponse = switchAaveInterestType(
        walletAddress: walletAddress,
        gasFeeInGwei: gasFeeInGwei,
        token: token,
        interestType: interestTypeToSwitchTo,
      );

      showModalBottomSheet(
        isScrollControlled: true,
        // enableDrag: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        context: context,
        builder: (context) {
          return SwitchApyReviewModal(
            localTxObj: localTxObj,
            switchApyApiResponse: _switchApyApiResponse,
            onDonePressed: () async {
              await appCacheProvider.refreshAaveWalletDistData();
              setState(() {
                _mainFuture = appCacheProvider
                    .getAaveWalletDistData(walletAddress: walletAddress)
                    .then(
                      (walletDist) => prepareAaveWalletDetails(walletDist),
                    );
              });
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Container(
          // height: 100,
          // decoration: BoxDecoration(border: Border.all()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Switch Interest Type",
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    .copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                      isScrollControlled: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      context: context,
                      builder: (context) {
                        return GasFeeModal(
                          alreadySelectedGasFee: gasFeeString,
                          fromToken: selectedToken,
                          onGasChanged: (Map gasFeeMap) {
                            setState(() {
                              gasFeeInGwei = gasFeeMap["gasEtherInGwei"];
                              gasFeeString = gasFeeMap["gasString"].toString();
                              gasFeeIconColor = gasFeeMap["color"];
                            });
                          },
                          operation: "TRANSFER",
                        );
                      });
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    FontAwesomeIcons.solidCircle,
                    color: gasFeeIconColor,
                    size: 10,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  ImageIcon(
                    AssetImage("assets/icons/gas_station.png"),
                    size: 24,
                    color: gasFeeIconColor,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: FutureBuilder(
          future: _mainFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.connectionState == ConnectionState.done) {
              Map _objAaveWalletDist = snapshot.data;
              List _aaveLoans = _objAaveWalletDist["loans"];

              if (_aaveLoans.isEmpty) {
                return _NoLoansWidget(
                  onRefresh: () {
                    setState(() {
                      _mainFuture = appCacheProvider
                          .getAaveWalletDistData(walletAddress: walletAddress)
                          .then(
                            (walletDist) =>
                                prepareAaveWalletDetails(walletDist),
                          );
                    });
                  },
                );
              }

              selectedToken = _aaveLoans[0]["data"]["symbol"];

              appCacheProvider.getGasFeeData("TRANSFER", selectedToken).then(
                    (_objGas) => _setUp(_objGas),
                  );

              return RefreshIndicator(
                onRefresh: () async {
                  
                  await appCacheProvider.refreshAaveWalletDistData();
                },
                child: ListView.builder(
                  itemBuilder: (context, position) {
                    // print(_aaveLoans[position]);
                    String _name = _aaveLoans[position]["name"];
                    String _iconUrl = _aaveLoans[position]["data"]["img"];
                    String _symbol = _aaveLoans[position]["data"]["symbol"];
                    InterestType _interestType =
                        _name.toLowerCase().startsWith("variable")
                            ? InterestType.variable
                            : InterestType.stable;

                    return SwitchInterestTypeItem(
                        symbol: _symbol,
                        onInterestChangeTapped: (String token,
                            InterestType interestTypeToSwitchTo) {
                          // print(token);
                          // print(interestTypeToSwitchTo);
                          selectedToken = token;
                          Map _txnParamsByUser = {
                            "currentApyType": _interestType,
                            "finalApytype": interestTypeToSwitchTo
                          };
                          localTxObj["txnParamsByUser"] = _txnParamsByUser;
                          onSwitchInterestButtonTapped(
                              token: token,
                              interestTypeToSwitchTo: interestTypeToSwitchTo);
                        },
                        name: _name,
                        iconUrl: _iconUrl,
                        interestType: _interestType);
                  },
                  itemCount: _aaveLoans.length,
                ),
              );
            }
            return _ErrorWidget();
          },
        ),
      ),
    );
  }

  void _setUp(var objGasFee) {
    Map _ = objGasFee["data"];

    _.forEach((key, value) {
      if (key.toString().toLowerCase() == gasFeeString.toLowerCase()) {
        print(key.toString());
        gasFeeInGwei = _[key]["gwei"].toString();
      }
    });

    print(gasFeeInGwei);
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Error",
        style:
            Theme.of(context).textTheme.subtitle2.copyWith(color: Colours.red),
      ),
    );
  }
}

class _NoLoansWidget extends StatelessWidget {
  final Function() onRefresh;
  _NoLoansWidget({@required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () async {
        await appCacheProvider.refreshAaveWalletDistData();
        onRefresh();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height / 2,
          child: Center(
            child: Text(
              "You don't have any loans",
              style: Theme.of(context)
                  .textTheme
                  .subtitle2
                  .copyWith(color: Colours.green),
            ),
          ),
        ),
      ),
    );
  }
}
