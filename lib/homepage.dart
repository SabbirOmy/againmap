



//import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';


class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late GoogleMapController mapController;
  late Position currentPosition; //storing the current position
   late BitmapDescriptor mapMarker; //storing custom marker icon
   late String searchAddress; //storing search address

  final LatLng _center = const LatLng(23.6850, 90.3563); //initial position

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  final Geolocator _geolocator = Geolocator();

  //Create a map of markers which will store our fetched markers
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  //make a call from the initState
  @override
  void initState() {
    super.initState();
    getMarkerData(); // initiating markers
    getCurrentLocation(); // initiating current location
    setCustomMarker(); // initiating custom marker icon
  }

  //current location
  getCurrentLocation() async {
    await _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        currentPosition = position;
        mapController
            .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        )));
      });
    });
  }

  //fetching the markers from the firestore
  getMarkerData() {
    // firestore database named as 'data'
    Firestore.instance.collection('markers').getDocuments().then((docs) {
      if (docs.documents.isNotEmpty) {
        for (int i = 0; i < docs.documents.length; i++) {
          initMarker(docs.documents[i].data, docs.documents[i].documentID);
        }
      }
    });
  }

  //creates a marker from the fetched data and adds it to the map of markers
  void initMarker(client, markerRef) {
    var markerIDVal = markerRef;
    final MarkerId markerId = MarkerId(markerIDVal);

    //new marker
    final Marker marker = Marker(
      position:
      // fetching location co-ordinates from 'location' data
      LatLng(client['positions'].latitude, client['positions'].longitude),
      icon: mapMarker,
      // fetching garage name from 'garage' data
      infoWindow: InfoWindow(title: 'Mecha shop', snippet: client['name']),
      markerId: markerId,
    );

    setState(() {
      markers[markerId] = marker; // adding a new marker to map
    });
  }

  // custom marker icon
  void setCustomMarker() async {
    mapMarker = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/images/Banani.png');
  }

  // search address result
  searchResult() {
    Geolocator().placemarkFromAddress(searchAddress).then((result) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target:
          LatLng(result[0].position.latitude, result[0].position.longitude),
          zoom: 13.0)));
    });
  }

  @override
  Widget build(BuildContext context) {
    // for status bar setup
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      //color set to transperent or set your own color
      statusBarIconBrightness: Brightness.dark,
      //set brightness for icons, like dark background light icons
    ));

    return MaterialApp(
      home: Scaffold(
        // appBar: AppBar(
        //   elevation: 0,
        //   brightness: Brightness.dark,
        //   title: Text('Mecha Map'),
        //   backgroundColor: Color(0xff053d45),
        // ),
        body: SafeArea(

            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  markers: Set<Marker>.of(markers.values),
                  onMapCreated: _onMapCreated,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                  ),
                ),
                Positioned(
                  top: 10.0,
                  right: 15.0,
                  left: 15.0,
                  child: Container(
                    height: 50.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.0),
                        color: Colors.white),
                    child: TextField(
                      //search by using enter from keyboard
                      onSubmitted: (value) {
                        if (searchAddress == null || searchAddress == "") {
                          return null;
                        } else {
                          searchResult();
                        }
                      },
                      decoration: InputDecoration(
                          hintText: 'Enter Address',
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.only(left: 15.0, top: 15.0),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            // bug fixed of search icon button
                            onPressed: () {
                              if (searchAddress == null ||
                                  searchAddress == "") {
                                return null;
                              } else {
                                searchResult();
                              }
                            },
                            iconSize: 30.0,
                          )),
                      onChanged: (val) {
                        setState(() {
                          searchAddress = val;
                        });
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        ),

      );


  }
}