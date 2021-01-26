import 'package:AaveOnMobile/app/aave/aave_models/aave_pool.dart';
import 'package:AaveOnMobile/app/aave/aave_pool_item.dart';
import 'package:AaveOnMobile/common_widgets/FirebaseStreamObserver.dart';
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

  @override
  Widget build(BuildContext context) {
    final streams = Provider.of<FirebaseStreams>(context, listen: false);
    final aaveMarketInfoStream = streams.getAaveMArketInfoStream;

    return Scaffold(
      appBar: AppBar(
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

            return Column(
              children: [
                Container(
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
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, position) {
                      return Divider(
                        indent: 30,
                        endIndent: 30,
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

// Widget _dataTable() {
//               return DataTable(
//                 showCheckboxColumn: false,
//                 columnSpacing: 30,
//                 dataRowHeight: 80,
//                 dividerThickness: 0,
//                 columns: [
//                   DataColumn(label: Container()),
//                   DataColumn(
//                     label: Text("Asset",
//                         style: Theme.of(context).textTheme.subtitle1),
//                   ),
//                   DataColumn(
//                     label: Text("Deposit",
//                         style: Theme.of(context).textTheme.subtitle1),
//                   ),
//                   DataColumn(
//                     label: Text("Borrow",
//                         style: Theme.of(context).textTheme.subtitle1),
//                   )
//                 ],
//                 rows: listAavePool
//                     .map(
//                       (e) => DataRow(
//                         onSelectChanged: (bool x) {
//                           print(e.symbol);
//                         },
//                         cells: [
//                           DataCell(
//                             CryptoIcon(
//                               token: e.symbol,
//                               height: 36,
//                               width: 36,
//                             ),
//                           ),
//                           DataCell(Text(e.symbol)),
//                           DataCell(Text(e.ltv.toString())),
//                           DataCell(
//                             Text(e.variableBorrowRate.toStringAsFixed(4)),
//                           )
//                         ],
//                       ),
//                     )
//                     .toList(),
//               );
//             }
