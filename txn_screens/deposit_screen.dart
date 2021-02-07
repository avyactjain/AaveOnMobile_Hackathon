import 'dart:convert';

import 'package:AaveOnMobile/app/aave/deposit_review_modal.dart';
import 'package:AaveOnMobile/app/crypto/amount_container_with_token.dart';
import 'package:AaveOnMobile/app/crypto/approve_token_modal.dart';
import 'package:AaveOnMobile/app/crypto/gas_fee_modal.dart';
import 'package:AaveOnMobile/app/wallet/wallet_data_viewmodel.dart';
import 'package:AaveOnMobile/crypto_utils/crypto_utls.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class DepositScreen extends StatefulWidget {
  final String selectedToken;
  DepositScreen({@required this.selectedToken});
  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  Map localTxObj = {};

  String selectedToken;

  String walletAddress;
  String gasFeeString;
  Color gasFeeIconColor;
  String gasFeeInGwei;
  final TextEditingController _depositAmountController =
      TextEditingController();
  Future _mainFuture;
  bool showCircularProgressIndicator;
  String _buttonText;
  Color _buttonColor;
  String _errorMsg;
  double _depositAmount = 0.0;
  bool _showButtonGradient;

  final _depositFormKey = GlobalKey<FormState>();

  @override
  // ignore: must_call_super
  void initState() {
    final walletData = Provider.of<WalletDataProvider>(context, listen: false);
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    walletAddress = walletData.activeWallet.walletAddress;
    //  walletAddress = "0xA5576138F067EB83C6Ad4080F3164b757DEB2737";
    selectedToken = "ETH";
    showCircularProgressIndicator = false;
    _buttonText = "Review";
    _buttonColor = Colours.aave_purple;
    _showButtonGradient = true;
    _errorMsg = null;
    gasFeeString = appCacheProvider.userPreferances["lastGasFeesString"];
    gasFeeIconColor = Color(int.parse(
        appCacheProvider.userPreferances["lastGasIconColor"],
        radix: 16));

    _mainFuture = Future.wait(
      [
        appCacheProvider.getAaveWalletDistData(walletAddress: walletAddress),
        appCacheProvider.getGasFeeData("TRANSFER", "ETH")
      ],
    );
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
      _mainFuture = Future.wait(
        [
          appCacheProvider.getAaveWalletDistData(
              walletAddress: walletDataProvider.activeWallet.walletAddress),
          appCacheProvider.getGasFeeData("TRANSFER", "ETH")
        ],
      );
    }
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
            amount: _depositAmount,
            walletAddress: walletAddress,
            gasFee: gasFeeInGwei,
            isConvert: false,
            sourceToken: selectedToken);

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
          isConvert: false,
          sourceToken: selectedToken,
          gasFeeInGwei: gasFeeInGwei,
          sourceAmt: _depositAmount.toString(),
          onDonePressed: () {
            onTokenChanged();
          },
        );
      },
    );
  }

  void onReviewPressed() {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    if (_depositFormKey.currentState.validate()) {
      Future _depositApiResponse = depositInAave(
        amount: _depositAmount.toString(),
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
          return DepositReviewModal(
            localTxObj: localTxObj,
            depositApiResponse: _depositApiResponse,
            onDonePressed: () async {
              await appCacheProvider.refreshAaveWalletDistData();

              setState(() {
                _mainFuture = Future.wait(
                  [
                    appCacheProvider.getAaveWalletDistData(
                        walletAddress: walletAddress),
                    appCacheProvider.getGasFeeData("TRANSFER", "ETH")
                  ],
                );
              });
              print("done pressed in deposit modal");
            },
          );
        },
      );
    }
  }

  Widget depositButton(
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
    return Scaffold(
        appBar: AppBar(
          title: Container(
            // height: 100,
            // decoration: BoxDecoration(border: Border.all()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Deposit",
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
              if (snapshot.connectionState == ConnectionState.done) {
                // print(snapshot.data);
                var _walletDist = snapshot.data[0];
                var _objGasFee = snapshot.data[1];

                _setUp(_objGasFee);

                Map<String, dynamic> _tokenDataMap =
                    _prepareTokenDataMap(_walletDist);

                return Form(
                  key: _depositFormKey,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AmountContainerWithToken(
                          tokenDataMap: _tokenDataMap,
                          context: context,
                          amountController: _depositAmountController,
                          operation: "SWAP",
                          showMaxButton: true,
                          toToken: null,
                          takeToSearchPageWhenSelectingToken: false,
                          showBalance: true,
                          gasFeesInGwei: gasFeeInGwei,
                          textFieldEnabled: true,
                          fromToken: selectedToken,
                          onDonePressed: (_) {
                            onTokenChanged();
                          },
                          onAmountChanged: (String amt) {
                            Map txnParamsByUser = {"amount": amt};
                            localTxObj["txnParamsByUser"] = txnParamsByUser;
                            _depositAmount = double.tryParse(amt);
                          },
                          onMaxPressed: (String amt) {
                            Map txnParamsByUser = {"amount": amt};
                            localTxObj["txnParamsByUser"] = txnParamsByUser;
                            _depositAmount = double.tryParse(amt);
                          },
                          onTokenChanged: (String token) {
                            selectedToken = token;
                            print("Source token changed");
                            onTokenChanged();
                          },
                        ),
                        SizedBox(height: 40),
                        showCircularProgressIndicator
                            ? CircularProgressIndicator()
                            : depositButton(
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
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Container();
            }));
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

  Map _prepareTokenDataMap(var _walletDist) {
    Map<String, dynamic> _mapToReturn = {};

    try {
      Map _ = _walletDist["data"];

      _.forEach(
        (key, value) {
          if (key.toString().toLowerCase() != "total") {
            _mapToReturn[key] = value;
          }
        },
      );

      return _mapToReturn;
    } on Exception catch (_) {
      // print(_.toString());
      return _mapToReturn;
    } catch (_) {
      // print(_.toString());
      return _mapToReturn;
    }
  }
}
