import 'package:AaveOnMobile/app/aave/withdraw_token_selection_modal.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class WithdrawAmountBox extends StatefulWidget {
  final Future amountBoxFuture;
  final String selectedToken;
  final localTxObj;
  final Function(String) onTokenChaged;
  final Function(String) onMaxPressed;
  final Function(String) onAmountChanged;
  final Function() onDonePressed;

  WithdrawAmountBox({
    @required this.amountBoxFuture,
    @required this.selectedToken,
    @required this.localTxObj,
    @required this.onTokenChaged,
    @required this.onDonePressed,
    @required this.onMaxPressed,
    @required this.onAmountChanged,
  });
  @override
  _WithdrawAmountBoxState createState() => _WithdrawAmountBoxState();
}

class _WithdrawAmountBoxState extends State<WithdrawAmountBox> {
  double _maxWithdrawalAmountForSelectedToken;
  TextEditingController _withdrawAmountController = TextEditingController();

  Future _mainFuture;
  String _selectedToken;

  final FocusNode _nodeText = FocusNode(); //for done button on keyboard

  KeyboardActionsConfig _keyboardActionBuildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colours.dark_bg_color,
      nextFocus: true,
      actions: [
        KeyboardActionsItem(
          focusNode: _nodeText,
          onTapAction: () {
            widget.onDonePressed();
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    _selectedToken = widget.selectedToken;

    _mainFuture = widget.amountBoxFuture;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _mainFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Map _objWithdraw = snapshot.data;
          List _tokenWiseWithdrawalData =
              _objWithdraw["data"]["tokenWiseWithdrawal"];

          _maxWithdrawalAmountForSelectedToken = _tokenWiseWithdrawalData
              .where((tokenData) => tokenData["name"] == _selectedToken)
              .toList()[0]["maxTokensToWithdraw"];

          String _maxWithdrawalAmtString =
              doubleFormatter.format(_maxWithdrawalAmountForSelectedToken);

          _maxWithdrawalAmountForSelectedToken =
              double.parse(_maxWithdrawalAmtString);

          void onTokenCardPressed() {
            showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              context: context,
              builder: (context) => WithdrawTokenSelectionModal(
                tokenDataList: _tokenWiseWithdrawalData,
                onTokenChanged: (String token) {
                  setState(() {
                    _selectedToken = token;
                  });
                  widget.onTokenChaged(token);
                },
              ),
            );
          }

          if (_objWithdraw["isError"]) {
            return Center(
              child: Text("error"),
            );
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
                            onFieldSubmitted: (val) {
                              widget.onDonePressed();
                            },
                            controller: _withdrawAmountController,
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              labelStyle: Theme.of(context).textTheme.headline2,
                              labelText: "0.000",
                            ),
                            onChanged: (String value) {
                              widget.onAmountChanged(value);
                            },
                            validator: (String value) {
                              if (double.tryParse(
                                      _withdrawAmountController.text) ==
                                  null) {
                                return "invalid amount";
                              } else {
                                if (double.tryParse(
                                        _withdrawAmountController.text) >
                                    _maxWithdrawalAmountForSelectedToken) {
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
                        Text(
                            "Max Withdraw : ${_tokenWiseWithdrawalData.where((tokenData) => tokenData["name"] == _selectedToken).toList()[0]["maxTokensToWithdraw"].toStringAsFixed(4)}",
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
                                  _withdrawAmountController.text =
                                      _maxWithdrawalAmountForSelectedToken
                                          .toStringAsFixed(4);
                                  widget.onMaxPressed(
                                      _maxWithdrawalAmountForSelectedToken
                                          .toStringAsFixed(4));
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
                                        height: 36,
                                        width: 36,
                                        token: _selectedToken),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      _selectedToken,
                                      style:
                                          Theme.of(context).textTheme.headline1,
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

        return Container(
          height: MediaQuery.of(context).size.height * 0.14,
        );
      },
    );
  }
}
