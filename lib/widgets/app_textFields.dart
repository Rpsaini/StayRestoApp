import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextFields {
  static Widget customTextField(
    BuildContext context,
    TextEditingController controller,
    String hintText,
  ) {
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        color: Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
          prefixIcon: Icon(
            Icons.location_on_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }
}
