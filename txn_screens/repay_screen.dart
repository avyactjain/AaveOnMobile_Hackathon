import 'package:AaveOnMobile/app/aave/aave_utils/aave_utils.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/repay_amount_box.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/repay_review_modal.dart';
import 'package:AaveOnMobile/app/aave/wallet_details_page_item.dart';
import 'package:AaveOnMobile/app/crypto/gas_fee_modal.dart';
import 'package:AaveOnMobile/app/wallet/wallet_data_viewmodel.dart';
import 'package:AaveOnMobile/crypto_utils/crypto_utls.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class RepayScreen extends StatefulWidget {
  @override
  _RepayScreenState createState() => _RepayScreenState();
}

class _RepayScreenState extends State<RepayScreen> {
  Map localTxObj = {};
  String walletAddress;
  String gasFeeInGwei;
  String repayAmount;

  bool repayAllDebt = false;
  String withdrawAmount;
  String gasFeeString = "fast";
  Color gasFeeIconColor;
  String selectedToken;

  List<String> loanTokens = [];

  Future _mainFuture;

  final _repayFormKey = GlobalKey<FormState>();

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

    Widget _loansBox(List loans) {
      int noOfLoans = loans.length;

      double _heightToBuild = 50;

      if (noOfLoans == 0) {
        _heightToBuild = 50;
      } else if (noOfLoans >= 5) {
        _heightToBuild = MediaQuery.of(context).size.height * 0.1 * 5;
      } else {
        _heightToBuild = MediaQuery.of(context).size.height * 0.1 * noOfLoans;
      }

      return Container(
        // decoration: BoxDecoration(border: Border.all()),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Loans ($noOfLoans)",
                    style: Theme.of(context).textTheme.headline1),
                Text(
                  "See All",
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      .copyWith(color: Colours.aave_blue),
                )
              ],
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: _heightToBuild,
              width: MediaQuery.of(context).size.width,
              child: Card(
                  margin: EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListView.separated(
                    separatorBuilder: (context, position) {
                      return Divider(
                        color: Colors.white24,
                      );
                    },
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, position) {
                      // print(tokens[position]);
                      String _token = loans[position]["name"].toString();
                      String _tokenValue =
                          loans[position]["data"]["amt"].toStringAsFixed(2);
                      String _usdValue = usdFormatter
                          .format(loans[position]["data"]["amtUSD"]);
                      String _iconUrl = loans[position]["data"]["img"];
                      String _usdPctChange;
                      return WalletDetailsPageItem(
                          token: _token,
                          iconUrl: _iconUrl,
                          tokenValue: _tokenValue,
                          usdValue: _usdValue,
                          usdPctChange: _usdPctChange);
                    },
                    itemCount: noOfLoans,
                  )),
            ),
          ],
        ),
      );
    }

    Widget _repayButton() {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (_repayFormKey.currentState.validate()) {
            Future _repayApiResponse = repayToAave(
                amount: repayAmount,
                gasFeeInGwei: gasFeeInGwei,
                token: selectedToken,
                walletAddress: walletAddress,
                interestRateMode: 2,
                repayAllDebt: repayAllDebt // need to add this
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
                return RepayReviewModal(
                  localTxObj: localTxObj,
                  repayApiResponse: _repayApiResponse,
                  onDonePressed: () async {
                    await appCacheProvider.refreshAaveWalletDistData();
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

    return Scaffold(
        appBar: AppBar(
          title: Container(
            // height: 100,
            // decoration: BoxDecoration(border: Border.all()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Repay",
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
                                gasFeeString =
                                    gasFeeMap["gasString"].toString();
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
                Map _objAaveWalletDist = snapshot.data;
                List _loans = _objAaveWalletDist["loans"];

                if (_loans.length > 0) {
                  loanTokens = _getLoanTokensList(aaveLoans: _loans);

                  print(loanTokens);

                  return RefreshIndicator(
                    onRefresh: () async {
                      await appCacheProvider.refreshAaveWalletDistData();

                      setState(() {
                        _mainFuture = appCacheProvider
                            .getAaveWalletDistData(walletAddress: walletAddress)
                            .then(
                              (walletDist) =>
                                  prepareAaveWalletDetails(walletDist),
                            );
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
                                  key: _repayFormKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      _loansBox(_loans),
                                      SizedBox(height: 20),
                                      Text(
                                        "Enter amount to repay",
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
                                      RepayAmountBox(
                                          onTokenChaged: (Map tokenMap) {
                                            selectedToken = tokenMap["name"];
                                            appCacheProvider
                                                .getGasFeeData(
                                                    "TRANSFER", selectedToken)
                                                .then((_objGasFee) =>
                                                    _setUp(_objGasFee));
                                          },
                                          onMaxPressed: (Map amountMap) {
                                            if (amountMap["canPayAllDebt"]) {
                                              repayAllDebt = true;
                                              repayAmount = "-1";
                                              Map _txnParamsByUser = {};
                                              _txnParamsByUser["amount"] =
                                                  amountMap["amount"];
                                              localTxObj["txnParamsByUser"] =
                                                  _txnParamsByUser;
                                            } else {
                                              Map _txnParamsByUser = {};
                                              _txnParamsByUser["amount"] =
                                                  amountMap["amount"];
                                              localTxObj["txnParamsByUser"] =
                                                  _txnParamsByUser;
                                              repayAmount = amountMap["amount"];
                                            }
                                          },
                                          loanTokens: loanTokens,
                                          aaveWalletDist: _objAaveWalletDist,
                                          onAmountChanged: (String amount) {
                                            Map _txnParamsByUser = {};
                                            _txnParamsByUser["amount"] = amount;
                                            localTxObj["txnParamsByUser"] =
                                                _txnParamsByUser;
                                            repayAmount = amount;
                                          }),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      SizedBox(
                                        height: 40,
                                      ),
                                      _repayButton()
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
                } else {
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
              }
            }
            return _ErrorWidget(
              onRefresh: () {
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
        ));
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

  List<String> _getLoanTokensList({List aaveLoans}) {
    List<String> _toReturn = [];

    for (Map loan in aaveLoans) {
      _toReturn.add(loan["data"]["symbol"]);
    }

    return _toReturn;
  }
}

class _ErrorWidget extends StatelessWidget {
  final Function() onRefresh;
  _ErrorWidget({@required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    return RefreshIndicator(
      onRefresh: () async {
        await appCacheProvider.refreshAaveWalletDistData();
        onRefresh();
      },
      child: SingleChildScrollView(
        // physics: AlwaysScrollableScrollPhysics(),
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
