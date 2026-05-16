import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ParcelListScreen extends StatefulWidget {
  final String token;
  ParcelListScreen({required this.token});

  @override
  _ParcelListScreenState createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  List parcels = [];

  @override
  void initState() {
    super.initState();
    _fetchParcels();
  }

  Future<void> _fetchParcels() async {
    final url = Uri.parse('http://10.0.2.2:8000/parcels');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        parcels = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mis Parcelas')),
      body: ListView.builder(
        itemCount: parcels.length,
        itemBuilder: (context, index) {
          final parcel = parcels[index];
          return ListTile(
            title: Text(parcel['name']),
            subtitle: Text('Ubicación: ${parcel['location']} - Suelo: ${parcel['soil_type']}'),
            trailing: Icon(Icons.agriculture),
          );
        },
      ),
    );
  }
}