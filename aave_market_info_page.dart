import 'package:AaveOnMobile/app/aave/aave_models/aave_pool.dart';
import 'package:AaveOnMobile/app/aave/aave_pool_item.dart';
import 'package:AaveOnMobile/common_widgets/FirebaseStreamObserver.dart';
import 'package:AaveOnMobile/services/consts.dart';
import 'package:AaveOnMobile/services/firebase_streams.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AaveMarketInfoPage extends StatefulWidget {
  @override
  _AaveMarketInfoPageState createState() => _AaveMarketInfoPageState();
}

class _AaveMarketInfoPageState extends State<AaveMarketInfoPage> {
  List<AavePool> listAavePool = [];
  String _sortingOrder = "DepositDesc";

  //0 - name
  //1 - borrow asc
  //2 - borrow desc
  //3 - deposit asc
  //4 - deposit desc
  //5 0 name desc

  _sortWatchlist(List<AavePool> data) {
    switch (_sortingOrder) {
      case "Name":
        data.sort(
          (a, b) => a.symbol.compareTo(b.symbol),
        );
        return data;

      case "Borrow":
        data.sort(
            (a, b) => a.variableBorrowRate.compareTo(b.variableBorrowRate));
        return data;

      case "BorrowDesc":
        data.sort(
          (a, b) => b.variableBorrowRate.compareTo(a.variableBorrowRate),
        );

        return data.reversed.toList();

      case "Deposit":
        data.sort(
          (a, b) => a.liquidityRate.compareTo(b.liquidityRate),
        );
        return data;

      case "DepositDesc":
        data.sort(
          (a, b) => b.liquidityRate.compareTo(a.liquidityRate),
        );
        data = data.reversed.toList();
        return data;

      case "NameDesc":
        data.sort(
          (a, b) => a.symbol.compareTo(a.symbol),
        );
        data = data.reversed.toList();
        return data;

        break;
      default:
        return data;
    }
  }

  @override
  Widget build(BuildContext context) {
    final streams = Provider.of<FirebaseStreams>(context, listen: false);
    final aaveMarketInfoStream = streams.getAaveMArketInfoStream;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          "Market Info",
          style: Theme.of(context).textTheme.headline1.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              // color: Colors.white,
              foreground: Paint()..shader = linearGradient),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: FirebaseStreamObserver(
          stream: aaveMarketInfoStream,
          onError: (context, event) {
            print('Firebase error while reading aave/market_info node');
          },
          onSuccess: (context, event) {
            listAavePool.clear();

            print('Firebase success while reading aave/market_info node');
            List _aavePools = (event.snapshot.value.values.toList());

            _aavePools.forEach((f) => {listAavePool.add(AavePool.fromMap(f))});

            _aavePools = _sortWatchlist(listAavePool);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: Colours.purpleGradient),
                  padding: EdgeInsets.all(8),
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          width: 36,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Asset",
                          style: Theme.of(context).textTheme.subtitle2.copyWith(
                              color: Colours.dark_bg_color,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Deposit",
                          style: Theme.of(context).textTheme.subtitle2.copyWith(
                              color: Colours.dark_bg_color,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Borrow",
                          style: Theme.of(context).textTheme.subtitle2.copyWith(
                              color: Colours.dark_bg_color,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 36,
                        child: IconButton(
                          padding: EdgeInsets.all(0),
                          icon: Icon(
                            Icons.sort_rounded,
                            color: Colours.dark_bg_color,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                                isDismissible: true,
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                context: context,
                                builder: (context) {
                                  return AaveMarketInfoSortModal(
                                    sortingOrder: _sortingOrder,
                                    onSortingOrderChanged: (_sortingOrderNew) {
                                      print(_sortingOrder);
                                      setState(() {
                                        _sortingOrder = _sortingOrderNew;
                                      });
                                    },
                                  );
                                });
                            //sort the list here
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, position) {
                      return Divider(
                        color: Colours.aave_blue,
                        indent: 20,
                        endIndent: 20,
                      );
                    },
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (context, position) {
                      return AavePoolItem(aavePool: listAavePool[position]);
                    },
                    itemCount: listAavePool.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AaveMarketInfoSortModal extends StatefulWidget {
  final Function(String) onSortingOrderChanged;
  final String sortingOrder;

  AaveMarketInfoSortModal(
      {@required this.onSortingOrderChanged, @required this.sortingOrder});

  @override
  _AaveMarketInfoSortModalState createState() =>
      _AaveMarketInfoSortModalState();
}

class _AaveMarketInfoSortModalState extends State<AaveMarketInfoSortModal> {
  List<String> options = aaveMarketInfoSortingOptions;
  String _sortingValueSelected;

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    _sortingValueSelected = widget.sortingOrder;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: options.map(
                (option) {
                  String name = "by " + option ;

                  return RadioListTile<String>(
                    // selected: true,
                    // dense: true,
                    activeColor: Colours.green,
                    title: Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2
                            .copyWith(color: Colors.white)),
                    value: option,
                    groupValue: _sortingValueSelected,
                    onChanged: (String value) async {
                      setState(() {
                        _sortingValueSelected = value;
                      });
                    },
                  );
                },
              ).toList(),
            ),
          ),
          Divider(
            color: Theme.of(context).colorScheme.onPrimary,
            endIndent: 15,
            indent: 15,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.08,
            width: MediaQuery.of(context).size.width,
            child: FlatButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                "Sort",
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    .copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
              onPressed: () {
                widget.onSortingOrderChanged(_sortingValueSelected);
                Navigator.of(context).pop();
              },
            ),
          )
        ],
      ),
    );
  }
}
