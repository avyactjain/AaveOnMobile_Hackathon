import 'package:AaveOnMobile/utils/cache.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AaveWalletDetailsScreen extends StatefulWidget {
  final String walletAddress;

  AaveWalletDetailsScreen({@required this.walletAddress});
  @override
  _AaveWalletDetailsScreenState createState() =>
      _AaveWalletDetailsScreenState();
}

class _AaveWalletDetailsScreenState extends State<AaveWalletDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final appCacheProvider = Provider.of<AppCache>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.walletAddress),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              FutureBuilder(
                  future: appCacheProvider.getAaveWalletDistData(
                      walletAddress: "0x25a88Ff5BbD4dC53b88178CE9185e959d438522e"),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Text(snapshot.data.toString());
                    }
                    return CircularProgressIndicator();
                  })
            ],
          ),
        ),
      ),
    );
  }
}
