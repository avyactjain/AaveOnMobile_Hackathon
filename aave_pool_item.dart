import 'package:AaveOnMobile/app/aave/aave_models/aave_pool.dart';
import 'package:AaveOnMobile/app/aave/screens/aave_pool_screen.dart';
import 'package:AaveOnMobile/common_widgets/crypto_icon.dart';
import 'package:AaveOnMobile/utils/colors.dart';
import 'package:flutter/material.dart';

class AavePoolItem extends StatelessWidget {
  final AavePool aavePool;
  AavePoolItem({@required this.aavePool});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => AavePoolScreen(
              aavePool: aavePool,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(8),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Container(
                child:
                    CryptoIcon(height: 42, width: 42, token: aavePool.symbol),
              ),
            ),
            Expanded(
                child: Text(aavePool.symbol,
                    style: Theme.of(context).textTheme.headline1)),
            Expanded(
              child: Text(
                aavePool.liquidityRate.toString() + "%",
                style: Theme.of(context).textTheme.headline1.copyWith(
                    color: Colours.aave_orange, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                aavePool.variableBorrowRate.toString() + "%",
                style: Theme.of(context).textTheme.headline1.copyWith(
                    color: Colours.aave_blue, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
