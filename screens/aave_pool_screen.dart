import 'package:AaveOnMobile/app/aave/aave_models/aave_pool.dart';
import 'package:AaveOnMobile/common_widgets/DetailPageStatisticBox.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/utils/cache.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class AavePoolScreen extends StatefulWidget {
  final AavePool aavePool;

  AavePoolScreen({@required this.aavePool});

  @override
  _AavePoolScreenState createState() => _AavePoolScreenState();
}

class _AavePoolScreenState extends State<AavePoolScreen> {
  @override
  Widget build(BuildContext context) {
    Map<String, double> _pieChartDataMap = {
      "Available Liquidity": widget.aavePool.availableLiquidity,
      "Total Borrowed": widget.aavePool.totalVariableDebt
    };

    Widget _pieChartBox() {
      final appCacheProvider = Provider.of<AppCache>(context, listen: false);

      return Container(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Stack(
                children: [
                  PieChart(
                    colorList: [Colours.dark_bg_color, Colours.white_light],
                    dataMap: _pieChartDataMap,
                    animationDuration: Duration(milliseconds: 800),
                    chartLegendSpacing: 32,
                    chartRadius: MediaQuery.of(context).size.width / 2,
                    // initialAngleInDegree: 360,

                    chartType: ChartType.ring,
                    ringStrokeWidth: 30,
                    legendOptions: LegendOptions(
                      showLegendsInRow: false,
                      legendPosition: LegendPosition.bottom,
                      showLegends: false,
                      // legendShape: _BoxShape.circle,
                      legendTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    chartValuesOptions: ChartValuesOptions(
                      showChartValueBackground: true,
                      showChartValues: false,
                      showChartValuesInPercentage: false,
                      showChartValuesOutside: false,
                    ),
                  ),
                  Positioned(
                    top: 50,
                    bottom: 50,
                    right: 50,
                    left: 50,
                    child: Container(
                      child: CryptoIcon(
                        token: widget.aavePool.symbol,
                        height: 72,
                        width: 72,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.1,
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Available Liquidity",
                          style: Theme.of(context).textTheme.subtitle2.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: Colours.dark_bg_color,
                        )
                      ],
                    ),
                    Expanded(
                        child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            usdFormatter
                                .format(widget.aavePool.availableLiquidity),
                            style: Theme.of(context)
                                .textTheme
                                .headline1
                                .copyWith(fontSize: 28),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          FutureBuilder(
                            future: appCacheProvider
                                .getTokenSpotPrice(widget.aavePool.symbol),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                print(snapshot.data);
                                double _symbolSpotPrice =
                                    double.tryParse(snapshot.data);
                                double _liquidityInUsd = 0.0;

                                try {
                                  _liquidityInUsd =
                                      widget.aavePool.availableLiquidity *
                                          _symbolSpotPrice;
                                } on Exception catch (_) {} catch (_) {}

                                return Text(
                                  "\$" + usdFormatter.format(_liquidityInUsd),
                                );
                              }
                              return Container();
                            },
                          )
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.1,
              child: Container(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Total Borrowed",
                          style: Theme.of(context).textTheme.subtitle2.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: Colours.white_light,
                        )
                      ],
                    ),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          usdFormatter
                              .format(widget.aavePool.totalVariableDebt),
                          style: Theme.of(context)
                              .textTheme
                              .headline1
                              .copyWith(fontSize: 28),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        FutureBuilder(
                          future: appCacheProvider
                              .getTokenSpotPrice(widget.aavePool.symbol),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              print(snapshot.data);
                              double _symbolSpotPrice =
                                  double.tryParse(snapshot.data);
                              double _liquidityInUsd = 0.0;

                              try {
                                _liquidityInUsd =
                                    widget.aavePool.totalVariableDebt *
                                        _symbolSpotPrice;
                              } on Exception catch (_) {} catch (_) {}

                              return Text(
                                  "\$" + usdFormatter.format(_liquidityInUsd));
                            }
                            return Container();
                          },
                        )
                      ],
                    ))
                  ],
                ),
              ),
            )
          ]),
        ),
      );
    }

    Widget _availableLiquidityBox() {
      final appCacheProvider = Provider.of<AppCache>(context, listen: false);

      return Container(
        height: MediaQuery.of(context).size.height * 0.1,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Available Liquidity",
                      style: Theme.of(context).textTheme.subtitle2.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: Colours.dark_bg_color,
                    )
                  ],
                ),
                Expanded(
                    child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      usdFormatter.format(widget.aavePool.availableLiquidity),
                      style: Theme.of(context)
                          .textTheme
                          .headline1
                          .copyWith(fontSize: 28),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    FutureBuilder(
                      future: appCacheProvider
                          .getTokenSpotPrice(widget.aavePool.symbol),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          print(snapshot.data);
                          double _symbolSpotPrice =
                              double.tryParse(snapshot.data);
                          double _liquidityInUsd = 0.0;

                          try {
                            _liquidityInUsd =
                                widget.aavePool.availableLiquidity *
                                    _symbolSpotPrice;
                          } on Exception catch (_) {} catch (_) {}

                          return Text(
                              "\$" + usdFormatter.format(_liquidityInUsd));
                        }
                        return Container();
                      },
                    )
                  ],
                ))
              ],
            ),
          ),
        ),
      );
    }

    Widget _totalBorrowedBox() {
      final appCacheProvider = Provider.of<AppCache>(context, listen: false);

      return Container(
        height: MediaQuery.of(context).size.height * 0.1,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total Borrowed",
                      style: Theme.of(context).textTheme.subtitle2.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: Colours.white_light,
                    )
                  ],
                ),
                Expanded(
                    child: Row(
                  children: [
                    Text(
                      usdFormatter.format(widget.aavePool.totalVariableDebt),
                      style: Theme.of(context)
                          .textTheme
                          .headline1
                          .copyWith(fontSize: 28),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    FutureBuilder(
                      future: appCacheProvider
                          .getTokenSpotPrice(widget.aavePool.symbol),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          print(snapshot.data);
                          double _symbolSpotPrice =
                              double.tryParse(snapshot.data);
                          double _liquidityInUsd = 0.0;

                          try {
                            _liquidityInUsd =
                                widget.aavePool.totalVariableDebt *
                                    _symbolSpotPrice;
                          } on Exception catch (_) {} catch (_) {}

                          return Text(
                              "\$" + usdFormatter.format(_liquidityInUsd));
                        }
                        return Container();
                      },
                    )
                  ],
                ))
              ],
            ),
          ),
        ),
      );
    }

    Widget _depositBox() {
      return Container(
        height: MediaQuery.of(context).size.height * 0.1,
        child: Card(
          color: Colours.aave_orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Deposit APY",
                      style: Theme.of(context).textTheme.subtitle2.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Spacer(),
                Flexible(
                  child: Text(
                    widget.aavePool.liquidityRate.toString() + "%",
                    style: Theme.of(context)
                        .textTheme
                        .headline1
                        .copyWith(fontSize: 28),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    Widget _borrowBox() {
      return Container(
        height: MediaQuery.of(context).size.height * 0.1,
        child: Card(
          color: Colours.aave_blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Borrow APR",
                      style: Theme.of(context).textTheme.subtitle2.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    widget.aavePool.variableBorrowRate.toString() + "%",
                    style: Theme.of(context)
                        .textTheme
                        .headline1
                        .copyWith(fontSize: 28),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    Widget _stableBorrowBox() {
      return Container(
        height: MediaQuery.of(context).size.height * 0.1,
        child: Card(
          color: Colours.aave_purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Stable Borrow APR",
                      style: Theme.of(context).textTheme.subtitle2.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    widget.aavePool.stableBorrowRate.toString() + "%",
                    style: Theme.of(context)
                        .textTheme
                        .headline1
                        .copyWith(fontSize: 28),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    Widget _ltvDescriptionBox() {
      final appCacheProvider = Provider.of<AppCache>(context, listen: false);

      double _totalTokens = widget.aavePool.availableLiquidity +
          widget.aavePool.totalVariableDebt;

      return Container(
          padding: EdgeInsets.all(8),
          child: FutureBuilder(
              future:
                  appCacheProvider.getTokenSpotPrice(widget.aavePool.symbol),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  print(snapshot.data);

                  double _usdValue = 0.0;
                  try {
                    _usdValue = _totalTokens * double.tryParse(snapshot.data);
                  } on Exception catch (_) {
                    print(_.toString());
                  } catch (_) {
                    print(_.toString());
                  }

                  String _usdValueFormatted = usdFormatter.format(_usdValue);

                  return Text(
                    "The AAVE protocol currently has \$$_usdValueFormatted of ${widget.aavePool.symbol} earning at ${widget.aavePool.liquidityRate}% Interest",
                    style: Theme.of(context)
                        .textTheme
                        .headline1
                        .copyWith(fontSize: 22),
                  );
                }
                return Container();
              }));
    }

    return Scaffold(
      floatingActionButton: AavePoolSpeedDial(),
      appBar: AppBar(
        title: Text(widget.aavePool.symbol),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: ListView(
          children: [
            _ltvDescriptionBox(),
            SizedBox(
              height: 8,
            ),
            _pieChartBox(),
            SizedBox(
              height: 8,
            ),
            _depositBox(),
            SizedBox(
              height: 8,
            ),
            _borrowBox(),
            SizedBox(
              height: 8,
            ),
            _stableBorrowBox(),
            SizedBox(
              height: 8,
            ),
            Text("HI"),
            Container(
                // height: 400,
                padding: EdgeInsets.all(8),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  children: [Text("HI"), Text("HI")],
                )),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Container(
                // decoration: BoxDecoration(border:Border.all()),
                padding: EdgeInsets.all(15),
                // height: MediaQuery.of(context).size.height * 0.34,
                width: MediaQuery.of(context).size.width * 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DetailPageStatisticBox(
                          name: "Maximum LTV",
                          value: widget.aavePool.ltv.toString() + "%",
                        ),
                        SizedBox(height: 10),
                        DetailPageStatisticBox(
                          name: "Liquidation Threshold",
                          value:
                              widget.aavePool.liquidationThreshold.toString() +
                                  "%",
                        ),
                        SizedBox(height: 10),
                        DetailPageStatisticBox(
                          name: "Liquidation Penality",
                          value:
                              widget.aavePool.liquidationPenality.toString() +
                                  "%",
                        )
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DetailPageStatisticBox(
                          name: "Use as collateral",
                          value: widget.aavePool.canUseAsCollateral.toString(),
                        ),
                        SizedBox(height: 10),
                        DetailPageStatisticBox(
                          name: "Stable Borrowing",
                          value: "Yes",
                        ),
                        SizedBox(height: 10),
                        DetailPageStatisticBox(
                          name: "Day Change %",
                          value: "1",
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AavePoolSpeedDial extends StatelessWidget {
  const AavePoolSpeedDial({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      backgroundColor: Colours.dark_bg_color,
      animatedIcon: AnimatedIcons.menu_arrow,
      overlayOpacity: 0.4,
      children: [
        SpeedDialChild(
            labelStyle: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: Colours.dark_bg_color,
                  fontWeight: FontWeight.w500,
                ),
            label: "Deposit",
            backgroundColor: Colours.aave_orange,
            child: Icon(FontAwesomeIcons.piggyBank)
            // child: Text("Deposit", style: Theme.of(context).textTheme.headline1),
            ),
        SpeedDialChild(
          backgroundColor: Colours.aave_orange,
          labelStyle: Theme.of(context).textTheme.subtitle2.copyWith(
                color: Colours.dark_bg_color,
                fontWeight: FontWeight.w500,
              ),
          child: Icon(FontAwesomeIcons.solidMoneyBillAlt),
          label: "Withdraw",
        ),
        SpeedDialChild(
            backgroundColor: Colours.aave_blue,
            labelStyle: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: Colours.dark_bg_color,
                  fontWeight: FontWeight.w500,
                ),
            label: "Borrow",
            child: Icon(FontAwesomeIcons.receipt)),
        SpeedDialChild(
            backgroundColor: Colours.aave_blue,
            labelStyle: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: Colours.dark_bg_color,
                  fontWeight: FontWeight.w500,
                ),
            label: "Repay",
            child: Icon(FontAwesomeIcons.cashRegister)),
        SpeedDialChild(
            labelStyle: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: Colours.dark_bg_color,
                  fontWeight: FontWeight.w500,
                ),
            label: "Deposit",
            child: Icon(FontAwesomeIcons.cashRegister)),
        SpeedDialChild(
            labelStyle: Theme.of(context).textTheme.subtitle2.copyWith(
                  color: Colours.dark_bg_color,
                  fontWeight: FontWeight.w500,
                ),
            label: "Deposit",
            child: Icon(FontAwesomeIcons.cashRegister)),
      ],
    );
  }
}
