import 'package:AaveOnMobile/app/aave/common_widgets/borrow_token_selection_modal.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class BorrowAmountBox extends StatefulWidget {
  final Future amountBoxFuture;
  final String selectedToken;

  final Function(Map) onTokenChaged;
  final Function(String) onMaxPressed;
  final Function(String) onAmountChanged;
  final Function() onDonePressed;

  BorrowAmountBox({
    @required this.amountBoxFuture,
    @required this.selectedToken,
    @required this.onTokenChaged,
    @required this.onMaxPressed,
    @required this.onAmountChanged,
    @required this.onDonePressed,
  });
  @override
  _BorrowAmountBoxState createState() => _BorrowAmountBoxState();
}

class _BorrowAmountBoxState extends State<BorrowAmountBox> {
  double _maxTokensToBorrowForSelectedToken = 0.0;
  TextEditingController _borrowAmountController = TextEditingController();

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          Map _objBorrowData = snapshot.data;

          if (_objBorrowData["isError"]) {
            return Container(
              child: Text(
                "Error (${_objBorrowData["errorMsg"]})",
                style: Theme.of(context)
                    .textTheme
                    .subtitle2
                    .copyWith(color: Colours.red),
              ),
              height: MediaQuery.of(context).size.height * 0.14,
            );
          }

          List _borrowTokensMapList = _objBorrowData["data"];
          Map _tokenMapForSelectedToken = _borrowTokensMapList
              .where((tokenMap) => tokenMap["name"] == _selectedToken)
              .toList()[0];
          _maxTokensToBorrowForSelectedToken =
              _tokenMapForSelectedToken["data"]["maxTokensToBorrow"];
          // _maxWithdrawalAmountForSelectedToken = doubleFormatter.format(_tokenMapForSelectedToken["data"][])

          void onTokenCardPressed() {
            showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              context: context,
              builder: (context) => BorrowTokenSelectionModal(
                  borrowTokensMapList: _borrowTokensMapList,
                  onTokenChanged: (Map borrowTokenMap) {
                    setState(
                      () {
                        _selectedToken = borrowTokenMap["token"];
                      },
                    );
                    widget.onTokenChaged(borrowTokenMap);
                  }),
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
                                      _borrowAmountController.text) ==
                                  null) {
                                return "invalid amount";
                              } else {
                                if (double.tryParse(
                                        _borrowAmountController.text) >
                                    _maxTokensToBorrowForSelectedToken) {
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
                        Text("Max Borrow : $_maxTokensToBorrowForSelectedToken",
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
                                  _borrowAmountController.text =
                                      _maxTokensToBorrowForSelectedToken
                                          .toString();

                                  widget.onMaxPressed(
                                      _maxTokensToBorrowForSelectedToken
                                          .toString());
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
