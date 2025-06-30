import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

Future<String> getCurrentLocation(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;
  final l10n = AppLocalizations.of(context)!;

  // Verifica se o serviço de localização está habilitado
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return l10n.locationServiceDisabled;
  }

  // Verifica as permissões de localização
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return l10n.locationPermissionDenied;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return l10n.locationPermissionPermanentlyDenied;
  }

  // Obtém a localização atual
  final position = await Geolocator.getCurrentPosition(
    // ignore: deprecated_member_use
    desiredAccuracy: LocationAccuracy.high,
  );

  return "${position.latitude}, ${position.longitude}";
}
