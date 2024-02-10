import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('404 Not Found'),
      ),
      body: Center(
        child: Text('La página solicitada no fue encontrada.'),
      ),
    );
  }
}
