import 'package:flutter/material.dart';

class R {
  static double w(BuildContext c) => MediaQuery.of(c).size.width;
  static double h(BuildContext c) => MediaQuery.of(c).size.height;
  static bool small(BuildContext c) => w(c) < 360;
  static bool medium(BuildContext c) => w(c) >= 360 && w(c) < 600;
  static bool large(BuildContext c) => w(c) >= 600;

  static double pad(BuildContext c) => small(c) ? 12.0 : (medium(c) ? 16.0 : 24.0);
  static double gap(BuildContext c) => small(c) ? 8.0 : 12.0;
  static double font(BuildContext c, double base) => small(c) ? base - 1 : base;
  static double btnH(BuildContext c) => small(c) ? 44.0 : 52.0;
  static double cardRadius(BuildContext c) => 12.0;
  static double iconSize(BuildContext c) => small(c) ? 20.0 : 24.0;
}