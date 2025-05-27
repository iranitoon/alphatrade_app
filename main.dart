import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(AlphaTradeApp());
}

class AlphaTradeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlphaTrade AI',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Interpreter? _interpreter;
  String _prediction = 'در حال بارگذاری مدل...';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
      setState(() {
        _prediction = 'مدل آماده است';
      });
    } catch (e) {
      setState(() {
        _prediction = 'خطا در بارگذاری مدل: $e';
      });
    }
  }

  Future<void> _runPrediction() async {
    if (_interpreter == null) return;

    var input = List.generate(1, (_) => List.generate(60, (_) => List.filled(10, 0.0)));
    var output = List.filled(3, 0.0).reshape([1, 3]);

    _interpreter!.run(input, output);

    int maxIndex = 0;
    double maxValue = output[0][0];
    for (int i = 1; i < 3; i++) {
      if (output[0][i] > maxValue) {
        maxValue = output[0][i];
        maxIndex = i;
      }
    }

    Map<int, String> decisions = {0: 'خرید', 1: 'فروش', 2: 'نگه‌داری'};

    setState(() {
      _prediction = 'تصمیم مدل: ${decisions[maxIndex]}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AlphaTrade ربات تریدر')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_prediction, style: TextStyle(fontSize: 24), textAlign: TextAlign.center),
              SizedBox(height: 40),
              ElevatedButton(onPressed: _runPrediction, child: Text('اجرای پیش‌بینی مدل')),
            ],
          ),
        ),
      ),
    );
  }
}

extension ListReshape<T> on List<T> {
  List<List<T>> reshape(List<int> dims) {
    int outer = dims[0];
    int inner = dims[1];
    if (length != outer * inner) throw Exception('طول لیست با ابعاد همخوانی ندارد');
    List<List<T>> reshaped = [];
    for (int i = 0; i < outer; i++) {
      reshaped.add(sublist(i * inner, (i + 1) * inner));
    }
    return reshaped;
  }
}