import 'dart:convert';

import 'package:AaveOnMobile/app/aave/aave_utils/aave_utils.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/health_score_level_widget.dart';
import 'package:AaveOnMobile/app/aave/common_widgets/withdraw_amount_box.dart';
import 'package:AaveOnMobile/app/aave/withdraw_review_modal.dart';
import 'package:AaveOnMobile/app/crypto/approve_token_modal.dart';
import 'package:AaveOnMobile/app/crypto/gas_fee_modal.dart';
import 'package:AaveOnMobile/app/wallet/wallet_data_viewmodel.dart';
import 'package:AaveOnMobile/crypto_utils/crypto_utls.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class WithdrawScreen extends StatefulWidget {
  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  Map localTxObj = {};
  String walletAddress;
  String gasFeeInGwei;

  String withdrawAmount;
  String gasFeeString = "fast";
  Color gasFeeIconColor;
  String selectedToken;

  Future _mainFuture;

  final _withdrawFormKey = GlobalKey<FormState>();

  bool showCircularProgressIndicator;
  String _buttonText;
  Color _buttonColor;
  bool _showButtonGradient;
  String _errorMsg;

  @override
  void initState() {
    final walletDataProvider =
        Provider.of<WalletDataProvider>(context, listen: false);
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    walletAddress = walletDataProvider.activeWallet.walletAddress;
    // walletAddress = "0xA5576138F067EB83C6Ad4080F3164b757DEB2737";

    gasFeeString = appCacheProvider.userPreferances["lastGasFeesString"];
    gasFeeIconColor = Color(int.parse(
        appCacheProvider.userPreferances["lastGasIconColor"],
        radix: 16));

    _mainFuture = appCacheProvider.refreshAaveUserHealthDat().then(
          (value) => Future.wait(
            [
              appCacheProvider.getAaveWalletDistData(
                  walletAddress: walletAddress),
              appCacheProvider.getGasFeeData("TRANSFER", "ETH"),
              appCacheProvider.getaaveUserHealthData(
                  walletAddress: walletAddress)
            ],
          ),
        );

    showCircularProgressIndicator = false;
    _buttonText = "Review";
    _buttonColor = Colours.aave_purple;
    _showButtonGradient = true;
    _errorMsg = null;

    // ignore: todo
    // TODO: implement initState

    super.initState();
  }

  @override
  void didChangeDependencies() {
    final walletDataProvider =
        Provider.of<WalletDataProvider>(context, listen: true);
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    if (walletDataProvider.activeWallet.walletAddress != walletAddress) {
      walletAddress = walletDataProvider.activeWallet.walletAddress;
      _mainFuture = appCacheProvider.refreshAaveUserHealthDat().then(
            (value) => Future.wait(
              [
                appCacheProvider.getAaveWalletDistData(
                    walletAddress: walletAddress),
                appCacheProvider.getGasFeeData("TRANSFER", "ETH"),
                appCacheProvider.getaaveUserHealthData(
                    walletAddress: walletAddress)
              ],
            ),
          );
    }
    // ignore: todo
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  void onTokenChanged() async {
    //When token is changed, check if it's approved, it is basically the check for approval flow.
    setState(() {
      showCircularProgressIndicator = true;
    });

    //allowance API call and response
    try {
      if (selectedToken != "ETH") {
        var allowanceApiResponse = await isSourceTokenApproved(
            amount: 0.0,
            walletAddress: walletAddress,
            gasFee: gasFeeInGwei,
            isConvert: true,
            sourceToken: selectedToken);
        // var allowanceApiResponse = await isSourceTokenApproved(
        //   selectedToken,
        //   walletAddress,
        //   gasFeeInGwei,
        //   0.0,
        // );

        if (allowanceApiResponse.statusCode == 200) {
          var _objAllowance = jsonDecode(allowanceApiResponse.body.toString());
          if (_objAllowance["isError"] == false) {
            if (!_objAllowance["isAllowed"]) {
              //Token is not allowed.
              setState(
                () {
                  showCircularProgressIndicator = false;
                  _buttonText = "Approve";
                  _buttonColor = Colours.yellow;
                  _showButtonGradient = false;
                },
              );
            } else {
              setState(() {
                showCircularProgressIndicator = false;
                _buttonText = "Review";
                _buttonColor = Colours.aave_purple;
              });
            }
          } else {
            // approval api gives isError
            setState(() {
              showCircularProgressIndicator = false;
              _buttonText = "Review";
              _errorMsg = "Approval error";
            });
          }
        }
      } else {
        setState(
          () {
            showCircularProgressIndicator = false;
            _buttonText = "Review";
            // _errorMsg = exp.toString();
            _showButtonGradient = true;
          },
        );
      }
    } on Exception catch (exp) {
      setState(() {
        showCircularProgressIndicator = false;
        _buttonText = "Review";
        _errorMsg = exp.toString();
        _showButtonGradient = true;
      });
    } catch (e) {
      setState(() {
        showCircularProgressIndicator = false;
        _buttonText = "Review";
        _showButtonGradient = true;
        _errorMsg = e.toString();
      });
    }
  }

  void onApprovePressed() {
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
        return ApproveTokenModal(
          isConvert: true,
          sourceToken: selectedToken,
          gasFeeInGwei: gasFeeInGwei,
          sourceAmt: "0.0",
          onDonePressed: () {
            onTokenChanged();
          },
        );
      },
    );
  }

  void onReviewPressed() {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    if (_withdrawFormKey.currentState.validate()) {
      Future _depositApiResponse = withdrawFromAave(
        amount: withdrawAmount.toString(),
        gasFeeInGwei: gasFeeInGwei,
        token: selectedToken,
        walletAddress: walletAddress,
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
          return WithdrawReviewModal(
              localTxObj: localTxObj,
              withdrawApiResponse: _depositApiResponse,
              onDonePressed: () {
                {
                  setState(
                    () {
                      _mainFuture = appCacheProvider
                          .refreshAaveUserHealthDat()
                          .whenComplete(
                              () => appCacheProvider.refreshAaveUserHealthDat())
                          .then(
                            (value) => Future.wait(
                              [
                                appCacheProvider.getAaveWalletDistData(
                                    walletAddress: walletAddress),
                                appCacheProvider.getGasFeeData(
                                    "TRANSFER", "ETH"),
                                appCacheProvider.getaaveUserHealthData(
                                    walletAddress: walletAddress)
                              ],
                            ),
                          );
                    },
                  );
                }
              });
        },
      );
    }
  }

  Widget withdrawButton(
    String buttonText, {
    Color buttonColor = Colours.green,
    bool isButtonEnabled = true,
    bool showGradient = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isButtonEnabled
          ? () {
              if (buttonText.contains("Approve")) {
                print('handle approve here');
                onApprovePressed();
              } else if (buttonText
                  .toLowerCase()
                  .contains("Review".toLowerCase())) {
                onReviewPressed();
              }
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: buttonColor,
          gradient: showGradient ? Colours.purpleGradient : null,
          borderRadius: BorderRadius.circular(10),
        ),
        width: MediaQuery.of(context).size.width * 1,
        height: MediaQuery.of(context).size.height * 0.08,
        child: Center(
          child: Text(
            buttonText,
            style: Theme.of(context).textTheme.button,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Container(
          // height: 100,
          // decoration: BoxDecoration(border: Border.all()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Withdraw",
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
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return Center(
                child: Text(
                  "App under maintenance",
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2
                      .copyWith(color: Colours.red),
                ),
              );
            }
            //do the work here

            var _walletDist = snapshot.data[0];
            var _objGasFee = snapshot.data[1];
            var _objUserHealth = snapshot.data[2];

            _setUp(_objGasFee);

            Map _aaveWalletDetails = prepareAaveWalletDetails(_walletDist);

            List _aaveDeposits = _aaveWalletDetails["deposits"];

            if (_aaveDeposits.length > 0) {
              if (selectedToken == null) {
                selectedToken = _aaveDeposits[0]["name"];
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await appCacheProvider.refreshAaveWalletDistData();
                  setState(() {
                    _mainFuture = appCacheProvider
                        .refreshAaveUserHealthDat()
                        .then(
                          (value) => Future.wait(
                            [
                              appCacheProvider.getAaveWalletDistData(
                                  walletAddress: walletAddress),
                              appCacheProvider.getGasFeeData("TRANSFER", "ETH"),
                              appCacheProvider.getaaveUserHealthData(
                                  walletAddress: walletAddress)
                            ],
                          ),
                        );
                  });
                },
                child: Form(
                  key: _withdrawFormKey,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          WithdrawAmountBox(
                            amountBoxFuture: preapreAaveDepositData(
                                aaveDeposits: _aaveDeposits,
                                objAaveUserHealth: _objUserHealth),
                            selectedToken: selectedToken,
                            localTxObj: localTxObj,
                            onTokenChaged: (String token) {
                              selectedToken = (token);
                              onTokenChanged();
                            },
                            onDonePressed: () {
                              onTokenChanged();
                            },
                            onAmountChanged: (String amount) {
                              Map txnParamsByUser = {"amount": amount};
                              localTxObj["txnParamsByUser"] = txnParamsByUser;
                              withdrawAmount = amount;
                            },
                            onMaxPressed: (String amount) {
                              onTokenChanged();
                              Map txnParamsByUser = {"amount": amount};
                              localTxObj["txnParamsByUser"] = txnParamsByUser;
                              withdrawAmount = "-1";
                            },
                          ),
                          SizedBox(
                            height: 100,
                          ),
                          showCircularProgressIndicator
                              ? CircularProgressIndicator()
                              : withdrawButton(
                                  _buttonText,
                                  showGradient: _showButtonGradient,
                                  buttonColor: _buttonColor,
                                  isButtonEnabled: true,
                                ),
                          _errorMsg != null
                              ? Text(_errorMsg.toString())
                              : Container()
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else if (_aaveDeposits.length == 0) {
              return _NoDepositsWidget(
                onRefresh: () {
                  setState(() {
                    _mainFuture = appCacheProvider
                        .refreshAaveUserHealthDat()
                        .then(
                          (value) => Future.wait(
                            [
                              appCacheProvider.getAaveWalletDistData(
                                  walletAddress: walletAddress),
                              appCacheProvider.getGasFeeData("TRANSFER", "ETH"),
                              appCacheProvider.getaaveUserHealthData(
                                  walletAddress: walletAddress)
                            ],
                          ),
                        );
                  });
                },
              );
            }
          }

          return Center(
            child: Text("Error"),
          );
        },
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

class _NoDepositsWidget extends StatelessWidget {
  final Function() onRefresh;
  _NoDepositsWidget({@required this.onRefresh});
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
              "You don't have any deposits in Aave",
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
