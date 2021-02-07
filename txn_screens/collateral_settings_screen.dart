import 'package:AaveOnMobile/app/aave/aave_utils/aave_utils.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/collateral_setting_item.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/collateral_toggle_review_modal.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/repay_review_modal.dart';
import 'package:AaveOnMobile/app/crypto/gas_fee_modal.dart';
import 'package:AaveOnMobile/app/wallet/wallet_data_viewmodel.dart';
import 'package:AaveOnMobile/crypto_utils/crypto_utls.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class CollateralSettingsScreen extends StatefulWidget {
  @override
  _CollateralSettingsScreenState createState() =>
      _CollateralSettingsScreenState();
}

class _CollateralSettingsScreenState extends State<CollateralSettingsScreen> {
  Map localTxObj = {};
  String walletAddress;
  String gasFeeInGwei;

  bool useAsCollateral;

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

    Widget _header(BoxConstraints constraints) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: constraints.maxHeight * 0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Token",
                style: Theme.of(context)
                    .textTheme
                    .subtitle2
                    .copyWith(color: Colors.white),
              ),
              Text(
                "Collateral",
                style: Theme.of(context)
                    .textTheme
                    .subtitle2
                    .copyWith(color: Colors.white),
              )
            ],
          ),
        ),
      );
    }

    void onTogglePressed() {
      var collateralToggleApiResponse = toggleCollateral(
          gasFeeInGwei: gasFeeInGwei,
          token: selectedToken,
          walletAddress: walletAddress,
          useAsCollateral: useAsCollateral);
      if (selectedToken != null && useAsCollateral != null) {
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
            return CollateralToggleReviewModal(
                localTxObj: localTxObj,
                collateralToggleApiResponse: collateralToggleApiResponse,
                onDonePressed: () async {
                  await appCacheProvider.refreshAaveWalletDistData();
                  setState(() {
                    _mainFuture = appCacheProvider
                        .getAaveWalletDistData(walletAddress: walletAddress)
                        .then(
                          (walletDist) => prepareAaveWalletDetails(walletDist),
                        );
                  });
                });
          },
        );
      }
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
                "Collateral Settings",
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

              List _aaveDeposits = _objAaveWalletDist["deposits"];

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      _header(constraints),
                      SizedBox(
                        height: constraints.maxHeight * 0.9,
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await appCacheProvider.refreshAaveWalletDistData();
                          },
                          child: ListView.builder(
                            itemBuilder: (context, position) {
                              // print(_aaveDeposits[position]);

                              String _token = _aaveDeposits[position]["name"];
                              String _amount = _aaveDeposits[position]["data"]
                                      ["amt"]
                                  .toString();
                              String _iconUrl =
                                  _aaveDeposits[position]["data"]["img"];
                              bool _usedAsCollateral = _aaveDeposits[position]
                                  ["data"]["usedAsCollateral"];
                              String _amountUSD = usdFormatter.format(
                                  _aaveDeposits[position]["data"]["amtUSD"]);

                              // return Text("Hi");

                              return CollateralSettingItem(
                                token: _token,
                                amount: _amount,
                                iconUrl: _iconUrl,
                                amountUsd: _amountUSD,
                                usedAsCollateral: _usedAsCollateral,
                                onTogglePressed: (String token,
                                    bool useAsCollateralNew) async {
                                  selectedToken = token;
                                  useAsCollateral = useAsCollateralNew;

                                  Map _txnParamsByUser = {};
                                  _txnParamsByUser["useAsCollateral"] =
                                      useAsCollateral;
                                  _txnParamsByUser["token"] = selectedToken;

                                  localTxObj["txnParamsByUser"] =
                                      _txnParamsByUser;

                                  var _objGasFee = await appCacheProvider
                                      .getGasFeeData("TRANSFER", selectedToken);

                                  _setUp(_objGasFee);

                                  onTogglePressed();
                                },
                              );
                            },
                            itemCount: _aaveDeposits.length,
                          ),
                        ),
                      )
                    ],
                  );
                },
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
