import 'package:AaveOnMobile/app/aave/common_widgets/repay_token_selection_modal.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class RepayAmountBox extends StatefulWidget {
  final Map aaveWalletDist;
  final List loanTokens;
  final Function(Map) onTokenChaged;
  final Function(Map) onMaxPressed;
  final Function(String) onAmountChanged;

  RepayAmountBox({
    @required this.onTokenChaged,
    @required this.onMaxPressed,
    @required this.loanTokens,
    @required this.aaveWalletDist,
    @required this.onAmountChanged,
  });

  @override
  _RepayAmountBoxState createState() => _RepayAmountBoxState();
}

class _RepayAmountBoxState extends State<RepayAmountBox> {
  double _maxTokensUserCanPay = 0.0;
  double _maxTokensToRepay;
  TextEditingController _borrowAmountController = TextEditingController();
  bool _canPayAllDebt = false;
  String _selectedToken;
  List<Map> loanTokensThatUserOwnsData = [];
  List<Map> tokenWiseLoans = [];
  double _borrowedTokenThatUserOwns;
  double _totalBorrowedTokens;

  final FocusNode _nodeText = FocusNode(); //for done button on keyboard

  KeyboardActionsConfig _keyboardActionBuildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colours.dark_bg_color,
      nextFocus: true,
      actions: [
        KeyboardActionsItem(
          focusNode: _nodeText,
          onTapAction: () {},
        ),
      ],
    );
  }

  @override
  void initState() {
    tokenWiseLoans = _getTokenWiseLoans(widget.aaveWalletDist);
    loanTokensThatUserOwnsData =
        _getLoanTokensThatUserOwnsData(widget.aaveWalletDist);

    if (loanTokensThatUserOwnsData.length != 0) {
      Map _temp = {};

      _selectedToken = loanTokensThatUserOwnsData.first["name"];
      _temp["name"] = _selectedToken;
      _temp["data"] = loanTokensThatUserOwnsData.first["data"];

      widget.onTokenChaged(_temp);
    }

    // Map _tokenMap = {};
    // _tokenMap["name"] = _selectedToken;
    // _tokenMap["amt"] = loanTokensThatUserOwnsData[0]["data"]["amt"];

    // widget.onTokenChaged(_tokenMap);

    // ignore: todo
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    void onTokenCardPressed() {
      showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        context: context,
        builder: (context) => RepayTokenSelectionModal(
          borrowTokensMapList: loanTokensThatUserOwnsData,
          onTokenChanged: (Map tokenMap) {
            setState(() {
              _selectedToken = tokenMap["name"];
            });
            widget.onTokenChaged(tokenMap);
            // print(tokenMap);
          },
        ),
      );
    }

    if (loanTokensThatUserOwnsData.isEmpty) {
      return Center(
        child: Text("You don't own loaned asset"),
      );
    }

    _maxTokensUserCanPay = loanTokensThatUserOwnsData
        .where((token) => token["name"] == _selectedToken)
        .toList()
        .first["data"]["amt"];

    _maxTokensToRepay = tokenWiseLoans
        .where((loan) => loan["name"] == _selectedToken)
        .toList()
        .first["loanAmt"];

    if (_maxTokensUserCanPay > _maxTokensToRepay * 1.001) {
      _canPayAllDebt = true;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.14,
      child: Card(
        margin: EdgeInsets.all(0),
        elevation: 10,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colours.dark_line)),
        color: Colours.dark_bg_color,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.13,
          // decoration: BoxDecoration(border: Border.all()),
          padding: EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: KeyboardActions(
                  disableScroll: true,
                  config: _keyboardActionBuildConfig(context),
                  child: Container(
                    // decoration: BoxDecoration(border: Border.all()),
                    child: TextFormField(
                      autovalidateMode: AutovalidateMode.always,
                      focusNode: _nodeText,
                      enabled: true,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (val) {},
                      controller: _borrowAmountController,
                      textAlignVertical: TextAlignVertical.center,
                      style: Theme.of(context).textTheme.headline2,
                      decoration: InputDecoration(
                        errorStyle: Theme.of(context)
                            .textTheme
                            .subtitle1
                            .copyWith(color: Colours.red),
                        isDense: true,
                        // contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelStyle: Theme.of(context).textTheme.headline2,
                        labelText: "0.000",
                      ),
                      onChanged: (String value) {
                        widget.onAmountChanged(value);
                      },
                      validator: (String value) {
                        if (double.tryParse(_borrowAmountController.text) ==
                            null) {
                          return "invalid amount";
                        } else {
                          if (double.tryParse(_borrowAmountController.text) >
                              _maxTokensUserCanPay) {
                            return "Enter lesser amount";
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Max : $_maxTokensUserCanPay",
                      style: Theme.of(context).textTheme.subtitle2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 25,
                        child: FlatButton(
                          padding: EdgeInsets.all(0),
                          color: Colours.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text("MAX",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline1
                                  .copyWith(
                                      fontSize: 12,
                                      color: Colours.dark_bg_color)),
                          onPressed: () {
                            if (_canPayAllDebt) {
                              _borrowAmountController.text =
                                  _maxTokensToRepay.toString();
                            } else {
                              _borrowAmountController.text =
                                  _maxTokensUserCanPay.toString();
                            }

                            Map _temp = {};
                            _temp["amount"] = _maxTokensUserCanPay.toString();
                            _temp["canPayAllDebt"] = _canPayAllDebt;

                            widget.onMaxPressed(_temp);
                          },
                        ),
                      ),

                      SizedBox(
                        width: 10,
                      ),
                      // Expanded(child: SizedBox(width: 10,)),
                      Card(
                        margin: EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 10,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            onTokenCardPressed();
                          },
                          child: Container(
                            padding: EdgeInsets.all(5),
                            child: Row(children: [
                              SizedBox(
                                width: 10,
                              ),
                              CryptoIcon(
                                  height: 36, width: 36, token: _selectedToken),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                _selectedToken,
                                style: Theme.of(context).textTheme.headline1,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                            ]),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Map> _getLoanTokensThatUserOwnsData(Map objAaveWalletDist) {
    List<Map> _toReturn = [];
    List<String> _loanTokens = [];

    for (Map loan in objAaveWalletDist["loans"]) {
      if (loan["data"]["symbol"] == "WETH") {
        _loanTokens.add("ETH");
      } else {
        _loanTokens.add(loan["data"]["symbol"]);
      }
    }

    print(_loanTokens);
    print(objAaveWalletDist);

    for (String token in _loanTokens) {
      for (Map asset in objAaveWalletDist["tokens"]) {
        if (asset["name"] == token) {
          _toReturn.add(asset);
        }
      }
    }

    return _toReturn;
  }

  List<Map> _getTokenWiseLoans(Map objAaveWalletDist) {
    List<Map> _toReturn = [];

    for (Map loan in objAaveWalletDist["loans"]) {
      Map _temp = {};
      if (loan["data"]["symbol"] == "WETH") {
        _temp["name"] = "ETH";
        _temp["loanAmt"] = loan["data"]["amt"];
      } else {
        _temp["name"] = loan["data"]["symbol"];
        _temp["loanAmt"] = loan["data"]["amt"];
      }
      _toReturn.add(_temp);
    }

    return _toReturn;
  }
}
