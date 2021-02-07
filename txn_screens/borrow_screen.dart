import 'package:AaveOnMobile/app/aave/aave_models/aave_pool.dart';
import 'package:AaveOnMobile/app/aave/aave_utils/aave_utils.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/BorrowReviewModal.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/borrow_amount_box.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/health_score_level_widget.dart';
import 'package:AaveOnMobile/app/crypto/gas_fee_modal.dart';
import 'package:AaveOnMobile/app/models/Crypto.dart';
import 'package:AaveOnMobile/crypto_utils/crypto_utls.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:AaveOnMobile/app/wallet/wallet_data_viewmodel.dart';
import 'package:AaveOnMobile/services/firebase_queries.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BorrowScreen extends StatefulWidget {
  @override
  _BorrowScreenState createState() => _BorrowScreenState();
}

class _BorrowScreenState extends State<BorrowScreen> {
  String walletAddress;
  String selectedToken;
  Map localTxObj = {};

  String _stableBorrowRateForSelectedToken = "0.0";
  String _variableBorrowRateForSelectedToken = "0.0";

  String gasFeeString;
  Color gasFeeIconColor;
  String gasFeeInGwei;
  String _borrowAmount = "0.0";

  List<String> _interestToggles = [];
  int _initialToggleIndex = 0;
  List<AavePool> _aavePoolList = [];

  int _borrowRateType; //1 = stable, 2 = variable

  Future _mainFuture;

  final _borrowFormKey = GlobalKey<FormState>();

  bool isError = false;
  final ValueNotifier<int> _healthFactorWidgetValueNotifier =
      ValueNotifier<int>(0);
  double _healthFactor = 0.0;

  @override
  void initState() {
    final walletDataProvider =
        Provider.of<WalletDataProvider>(context, listen: false);
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    walletAddress = walletDataProvider.activeWallet.walletAddress;
    // walletAddress = "0xA5576138F067EB83C6Ad4080F3164b757DEB2737";
    selectedToken = "ETH";
    _borrowRateType = 1;

    gasFeeString = appCacheProvider.userPreferances["lastGasFeesString"];
    gasFeeIconColor = Color(int.parse(
        appCacheProvider.userPreferances["lastGasIconColor"],
        radix: 16));

    _mainFuture = appCacheProvider
        .refreshAaveUserHealthDat()
        .then((value) => Future.wait([
              FirebaseQueries().getAaveMarketSymbols(),
              appCacheProvider.getaaveUserHealthData(
                  walletAddress: walletAddress),
              appCacheProvider.getGasFeeData("TRANSFER", "ETH")
            ]));
    // ignore: todo
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
      _mainFuture = Future.wait([
        FirebaseQueries().getAaveMarketSymbols(),
        appCacheProvider.getaaveUserHealthData(walletAddress: walletAddress),
        appCacheProvider.getGasFeeData("TRANSFER", "ETH")
      ]);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    Widget _borrowButton() {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (_borrowFormKey.currentState.validate()) {
            Future _depositApiResponse = borrowFromAave(
              amount: _borrowAmount,
              gasFeeInGwei: gasFeeInGwei,
              token: selectedToken,
              walletAddress: walletAddress,
              interestRateMode: _borrowRateType,
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
                return BorrowReviewModal(
                  localTxObj: localTxObj,
                  depositApiResponse: _depositApiResponse,
                  onDonePressed: () async {
                    appCacheProvider
                        .refreshAaveWalletDistData()
                        .then((value) =>
                            appCacheProvider.refreshAaveUserHealthDat())
                        .then((value) {
                      setState(() {
                        _mainFuture = Future.wait(
                          [
                            FirebaseQueries().getAaveMarketSymbols(),
                            appCacheProvider.getaaveUserHealthData(
                                walletAddress: walletAddress),
                            appCacheProvider.getGasFeeData("TRANSFER", "ETH")
                          ],
                        );
                      });
                    });

                    print("done pressed in deposit modal");
                  },
                );
              },
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: Colours.purpleGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          width: MediaQuery.of(context).size.width * 1,
          height: MediaQuery.of(context).size.height * 0.08,
          child: Center(
            child: Text(
              "Review",
              style: Theme.of(context).textTheme.button,
            ),
          ),
        ),
      );
    }

    void onTokenChaned(Map tokenMap) {
      selectedToken = tokenMap["token"];
      if (tokenMap["borrowRateType"] == BorrowRateType.stableBorrowRate) {
        setState(() {
          _borrowRateType = 1;
          _initialToggleIndex = 0;
          // _interestToggles = ['Stable ($_stableBorrowRateForSelectedToken%)'];
        });
      } else if (tokenMap["borrowRateType"] ==
          BorrowRateType.variableBorrowRate) {
        setState(() {
          _borrowRateType = 2;
          _initialToggleIndex = 0;
          // _interestToggles = [
          //   'Variable ($_variableBorrowRateForSelectedToken%)'
          // ];
        });
      } else {
        setState(() {
          _borrowRateType = 1;
          _initialToggleIndex = 0;

          // _interestToggles = [
          //   'Stable ($_stableBorrowRateForSelectedToken%)',
          //   'Variable ($_variableBorrowRateForSelectedToken%)'
          // ];
        });
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
                "Borrow",
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
      body: FutureBuilder(
        future: _mainFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              List _aaveMarketSymbolsList =
                  snapshot.data[0].value.values.toList();
              Map _objAaveUserHealth = snapshot.data[1];
              Map _objGasFee = snapshot.data[2];

              if (_objAaveUserHealth["isError"]) {
                return _ErrorWidget();
              }

              if (double.parse(_objAaveUserHealth["data"]["totalCollateralETH"]
                      .toString()) ==
                  0) {
                return _NoCollateralWidget(
                  onRefresh: () {
                    setState(() {
                      _mainFuture = Future.wait([
                        FirebaseQueries().getAaveMarketSymbols(),
                        appCacheProvider.getaaveUserHealthData(
                            walletAddress: walletAddress),
                        appCacheProvider.getGasFeeData("TRANSFER", "ETH")
                      ]);
                    });
                  },
                );
              }
              if (_healthFactor == 0.0) {
                _healthFactor = double.parse(
                    _objAaveUserHealth["data"]["healthFactor"].toString());
              }

              _setUp(_objGasFee);

              _aavePoolList = _prepareAavePools(
                  aaveMarketSymbolList: _aaveMarketSymbolsList);

              _stableBorrowRateForSelectedToken = _aavePoolList
                  .where((aavePool) => aavePool.symbol == selectedToken)
                  .toList()
                  .first
                  .stableBorrowRate
                  .toString();

              _variableBorrowRateForSelectedToken = _aavePoolList
                  .where((aavePool) => aavePool.symbol == selectedToken)
                  .toList()
                  .first
                  .variableBorrowRate
                  .toString();

              _interestToggles.clear();

              if (double.parse(_stableBorrowRateForSelectedToken) != 0) {
                _interestToggles
                    .add("Stable ($_stableBorrowRateForSelectedToken%)");
              }
              if (double.parse(_variableBorrowRateForSelectedToken) != 0) {
                _interestToggles
                    .add("Variable ($_variableBorrowRateForSelectedToken%)");
              }

              // if (listEquals(_interestToggles, ['Stable', 'Variable'])) {
              //   _interestToggles = [
              //     'Stable ($_stableBorrowRateForSelectedToken%)',
              //     'Variable ($_variableBorrowRateForSelectedToken%)'
              //   ];
              // }

              // print(_aavePoolList);

              return RefreshIndicator(
                onRefresh: () async {
                  isError = false;
                  setState(() {
                    _mainFuture = Future.wait([
                      FirebaseQueries().getAaveMarketSymbols(),
                      appCacheProvider.getaaveUserHealthData(
                          walletAddress: walletAddress),
                      appCacheProvider.getGasFeeData("TRANSFER", "ETH")
                    ]);
                  });
                },
                child: LayoutBuilder(
                  builder: (context, constraint) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraint.maxHeight),
                        child: IntrinsicHeight(
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Form(
                              key: _borrowFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Enter amount to borrow",
                                    textAlign: TextAlign.left,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2
                                        .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  BorrowAmountBox(
                                    onDonePressed: () async {
                                      double _newHealthFactor =
                                          await _recalculateHealthFactor(
                                              selectedToken: selectedToken,
                                              objAaveUserHealth:
                                                  _objAaveUserHealth);
                                      _healthFactor = _newHealthFactor;

                                      _healthFactorWidgetValueNotifier.value +=
                                          1;
                                    },
                                    amountBoxFuture: prepareAaveBorrowData(
                                      aavePools: _aavePoolList,
                                      objAaveUserHealth: _objAaveUserHealth,
                                    ),
                                    selectedToken: selectedToken,
                                    onTokenChaged: (Map tokenMap) async {
                                      onTokenChaned(tokenMap);
                                    },
                                    onMaxPressed: (String amount) async {
                                      Map txnParamsByUser = {"amount": amount};
                                      localTxObj["txnParamsByUser"] =
                                          txnParamsByUser;
                                      _borrowAmount = amount;
                                      double _newHealthFactor =
                                          await _recalculateHealthFactor(
                                              selectedToken: selectedToken,
                                              objAaveUserHealth:
                                                  _objAaveUserHealth);
                                      _healthFactor = _newHealthFactor;

                                      _healthFactorWidgetValueNotifier.value +=
                                          1;
                                    },
                                    onAmountChanged: (String amount) {
                                      _healthFactorWidgetValueNotifier.value +=
                                          1;
                                      Map txnParamsByUser = {"amount": amount};
                                      localTxObj["txnParamsByUser"] =
                                          txnParamsByUser;

                                      _borrowAmount = amount;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Choose Interest Rate",
                                    textAlign: TextAlign.left,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2
                                        .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colours.dark_line, width: 1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ToggleSwitch(
                                      initialLabelIndex: _initialToggleIndex,
                                      minWidth: _interestToggles.length == 2
                                          ? MediaQuery.of(context).size.width /
                                              2
                                          : MediaQuery.of(context).size.width,
                                      cornerRadius: 10.0,
                                      activeBgColor: Colours.dark_bg_color,
                                      activeFgColor: Colours.green,
                                      inactiveBgColor: Colours.dark_bg_color,
                                      inactiveFgColor: Colors.white,
                                      minHeight:
                                          MediaQuery.of(context).size.height *
                                              0.08,
                                      iconSize: 18,
                                      fontSize: 18,
                                      labels: _interestToggles,
                                      icons: [
                                        Icons.linear_scale_rounded,
                                        Icons.stacked_line_chart_rounded
                                      ],
                                      onToggle: (index) {
                                        index == 0
                                            ? _borrowRateType = 1
                                            : _borrowRateType = 2;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    height: 40,
                                  ),
                                  SizedBox(
                                    height: 80,
                                    // width: 200,
                                    child: ValueListenableBuilder(
                                        builder: (BuildContext context,
                                            int value, Widget child) {
                                          return HealthScoreLevelWidget(
                                            healtFactor: _healthFactor,
                                          );
                                        },
                                        valueListenable:
                                            _healthFactorWidgetValueNotifier),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  _borrowButton()
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          }
          return _ErrorWidget();
        },
      ),
    );
  }

  Future<double> _recalculateHealthFactor(
      {String selectedToken, Map objAaveUserHealth}) async {
    double _newHealthFactor = 0.0;

    try {
      // first get value of selectedToken in eth.
      String _selectedTokenToQuery =
          selectedToken == "ETH" ? "WETH-ETH" : selectedToken + "-ETH";
      double _selectedTokenValueInEth = 0.0;
      var _snapshot =
          await FirebaseQueries().getAaveSymbol(symbol: _selectedTokenToQuery);
      Crypto _selectedTokenCrypto = Crypto.fromMap(_snapshot.value);
      _selectedTokenValueInEth =
          double.parse(_selectedTokenCrypto.lastPrice.toString());
      double _tokenAmount = double.parse(_borrowAmount);
      // double.parse(localTxObj["txnParamsByUser"]["amount"].toString());

      //now get the useful aaveHealthParams
      double _totalCollateralETH = double.parse(
          objAaveUserHealth["data"]["totalCollateralETH"].toString());
      double _totalDebtETH =
          double.parse(objAaveUserHealth["data"]["totalDebtETH"].toString());
      double _liquidationThreshold = double.parse(
          objAaveUserHealth["data"]["liquidationThreshold"].toString());

      double _newDebt =
          _totalDebtETH + (_selectedTokenValueInEth * _tokenAmount);

      _newHealthFactor =
          (_totalCollateralETH * _liquidationThreshold) / _newDebt;

      return double.parse(_newHealthFactor.toStringAsFixed(2));
    } on Exception catch (_) {
      return _newHealthFactor;
    } catch (e) {
      return _newHealthFactor;
    }
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

  List<AavePool> _prepareAavePools({List aaveMarketSymbolList}) {
    List<AavePool> _toReturn = [];

    try {
      aaveMarketSymbolList.forEach(
        (symbol) {
          _toReturn.add(AavePool.fromMap(symbol));
        },
      );
    } on Exception catch (_) {} catch (e) {}

    return _toReturn;
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

class _NoCollateralWidget extends StatelessWidget {
  final Function() onRefresh;
  _NoCollateralWidget({@required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () async {
        await appCacheProvider.refreshAaveUserHealthDat();
        onRefresh();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height / 2,
          child: Center(
            child: Text(
              "You don't have 0 collateral in Aave",
              style: Theme.of(context)
                  .textTheme
                  .subtitle2
                  .copyWith(color: Colours.red),
            ),
          ),
        ),
      ),
    );
  }
}
