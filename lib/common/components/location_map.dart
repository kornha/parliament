import 'dart:async';
import 'dart:math';

import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:country_flags/country_flags.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/location.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class LocationMap extends StatefulWidget {
  final Location location;
  final double? size;

  const LocationMap({
    super.key,
    this.size,
    required this.location,
  });

  // static const CameraPosition _kGooglePlex = CameraPosition(
  //   target: LatLng(37.42796133580664, -122.085749655962),
  //   zoom: 14.4746,
  // );

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late GoogleMapController mapController;
  late String name;

  @override
  void initState() {
    super.initState();
    try {
      //Country country = CountryParser.parse(widget.locations.first);
      // name = country.name;
    } catch (e) {
      // name = "us";
    }
    // for static map, ios key. need to enabled other platforms
    // follow these steps for secret:
    // https://developers.google.com/maps/documentation/maps-static/digital-signature#get-secret

    // // make http request to get static image
    // http.get(Uri.parse(url)).then((response) {
    //   print(response.body);
    // });

    // rootBundle.loadString('assets/maps/dark_map.json').then((string) {
    //   _mapStyle = string;
    // });
  }

  @override
  Widget build(BuildContext context) {
    var side = widget.size ?? context.iconSizeStandard;
    var mapId = context.isDarkMode ? "7aa7b886141674ae" : "1dc9a09ef62c1212";

    var url = "https://maps.googleapis.com/maps/api/staticmap?"
        "size=150x150"
        "&zoom=5"
        "&visible=${widget.location.geoPoint.latitude},${widget.location.geoPoint.longitude}"
        "&map_id=$mapId"
        "&key=AIzaSyBGG9WeljnVJwbKOJEKrBE_wQNYFHTSEto";

    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: [
        Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
            borderRadius: BRadius.circular,
            border: Border.all(
              color: context.backgroundColor,
              width: 3.0,
            ),
          ),
        ),
        // CountryFlag.fromCountryCode(
        //   widget.locations.isEmpty ? "us" : widget.locations.first,
        //   height: side > IconSize.large
        //       ? context.iconSizeStandard
        //       : context.iconSizeSmall,
        //   width: side > IconSize.large
        //       ? context.iconSizeStandard
        //       : context.iconSizeSmall,
        //   borderRadius: 2,
        // ),
      ],
    );
    // return SizedBox(
    //   width: 250, // some padding for map
    //   height: 250,
    //   child: GoogleMap(
    //     initialCameraPosition: LocationMap._kGooglePlex,
    //     onMapCreated: (GoogleMapController controller) {
    //       mapController = controller;
    //       mapController.setMapStyle(_mapStyle);
    //     },
    //   ),
    // );
  }
}
