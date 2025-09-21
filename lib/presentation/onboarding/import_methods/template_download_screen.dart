import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TemplateDownloadScreen extends StatefulWidget {
  const TemplateDownloadScreen({Key? key}) : super(key: key);

  @override
  State<TemplateDownloadScreen> createState() => _TemplateDownloadScreenState();
}

class _TemplateDownloadScreenState extends State<TemplateDownloadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Template'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_rounded,
                size: 20.w,
                color: Colors.teal[300],
              ),
              SizedBox(height: 4.h),
              Text(
                'Template Download Coming Soon',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                'We\'re working on providing downloadable Excel and CSV templates that you can fill out and upload back to the app.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                  child: Text('Go Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
