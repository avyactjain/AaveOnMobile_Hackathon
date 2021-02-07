import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';

class SwitchApySuccessModal extends StatelessWidget {
  final localTxObj;
  final Function() onDonePressed;

  SwitchApySuccessModal(
      {@required this.localTxObj, @required this.onDonePressed});
  @override
  Widget build(BuildContext context) {
    String _intitialApyType = localTxObj["txnParamsByUser"]["currentApyType"]
        .toString()
        .split(".")
        .last;
    String _finalApyType = localTxObj["txnParamsByUser"]["finalApytype"]
        .toString()
        .split(".")
        .last;

    // print(jsonEncode(widget.localTxObj));ƒ
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colours.green,
            size: 70,
          ),
          Text(
            "Success",
            style: Theme.of(context)
                .textTheme
                .headline2
                .copyWith(color: Colours.green),
          ),
          SizedBox(
            height: 20,
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                  text:
                      "Successfully switched $_intitialApyType to $_finalApyType using Aave",
                  style: Theme.of(context).textTheme.headline1),
            ]),
          ),
          SizedBox(
            height: 50,
          ),
          Divider(),
          SizedBox(
            height: 20,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  if (await canLaunch(
                      localTxObj["broadcastApiResponseObj"]["data"])) {
                    launch(localTxObj["broadcastApiResponseObj"]["data"]);
                  }
                },
                child: Text(
                  "View on etherscan",
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      .copyWith(color: Colours.dark_text_gray),
                ),
              ),
              SizedBox(
                width: 5,
              ),
              Icon(
                Icons.open_in_new,
                color: Colours.dark_text_gray,
              ),
            ],
          ),
          Expanded(
            child: SizedBox(),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    onDonePressed();
                    Navigator.of(context).pop();
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
                        "Done",
                        style: Theme.of(context).textTheme.button,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.08,
                  child: OutlineButton(
                    borderSide: BorderSide(color: Colours.aave_purple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "Share",
                      style: Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colours.aave_purple),
                    ),
                    onPressed: () {
                      Share.text(
                          "Transaction hash url",
                          localTxObj["broadcastApiResponseObj"]["data"]
                              .toString(),
                          "text");
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
