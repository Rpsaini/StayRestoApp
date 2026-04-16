import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppText {
  static Widget heading(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 18.sp,
      ),
    );
  }

  static Widget title(BuildContext context, String text, {Color? color}) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static Widget body(BuildContext context, String text, {Color? color}) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: color, fontSize: 14.sp),
    );
  }

  static Widget small(BuildContext context, String text, {Color? color}) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontSize: 12.sp, color: color),
    );
  }
}
