import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/business_catalogue_service.dart';
import '../../models/business_catalogue_template.dart';
import 'catalogue_preview_edit_screen.dart';

class BusinessTypeSelectionScreen extends StatefulWidget {
  final bool isFirstTimeSetup;
  final String? returnRoute; // Where to navigate back after completion

  const BusinessTypeSelectionScreen({
    Key? key,
    this.isFirstTimeSetup = false,
    this.returnRoute,
  }) : super(key: key);

  @override
  State<BusinessTypeSelectionScreen> createState() =>
      _BusinessTypeSelectionScreenState();
}

class _BusinessTypeSelectionScreenState
    extends State<BusinessTypeSelectionScreen> {
  final BusinessCatalogueService _catalogueService =
      BusinessCatalogueService.instance;
  final Set<String> _selectedTemplateIds = {};
  bool _isCustomSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Choose Your Business Type'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBusinessTypeGrid(),
                  SizedBox(height: 3.h),
                  _buildCustomOption(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[100]!, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store_outlined,
                size: 7.w,
                color: Colors.blue[700],
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  widget.isFirstTimeSetup
                      ? 'Set up your catalogue'
                      : 'Add items to catalogue',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Select one or more business types that match your store. You can customize items later.',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (_selectedTemplateIds.isNotEmpty || _isCustomSelected) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 4.w),
                  SizedBox(width: 2.w),
                  Text(
                    _isCustomSelected
                        ? 'Custom catalogue selected'
                        : '${_selectedTemplateIds.length} ${_selectedTemplateIds.length == 1 ? 'type' : 'types'} selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBusinessTypeGrid() {
    final templates = BusinessCatalogueService.allTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Types',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(),
            childAspectRatio: _getAspectRatio(),
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            return _buildBusinessTypeCard(templates[index]);
          },
        ),
      ],
    );
  }

  int _getCrossAxisCount() {
    // Responsive grid columns
    if (SizerUtil.width < 600) return 2; // Mobile
    if (SizerUtil.width < 900) return 3; // Tablet portrait
    return 4; // Tablet landscape / Desktop
  }

  double _getAspectRatio() {
    // Responsive card aspect ratio
    if (SizerUtil.width < 600) return 0.85; // Mobile
    if (SizerUtil.width < 900) return 0.95; // Tablet portrait
    return 1.0; // Tablet landscape / Desktop
  }

  Widget _buildBusinessTypeCard(BusinessCatalogueTemplate template) {
    final isSelected = _selectedTemplateIds.contains(template.id);

    return GestureDetector(
      onTap: () => _toggleTemplateSelection(template.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? template.color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? template.color : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? template.color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: template.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      template.icon,
                      size: 8.w,
                      color: template.color,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Text(
                    template.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${template.items.length} items',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    template.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.5.sp,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 2.w,
                right: 2.w,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: template.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 4.w,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or start fresh',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: _toggleCustomSelection,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _isCustomSelected ? Colors.amber[50] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCustomSelected ? Colors.amber[700]! : Colors.grey[300]!,
                width: _isCustomSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isCustomSelected
                      ? Colors.amber.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isCustomSelected ? 8 : 4,
                  offset: Offset(0, _isCustomSelected ? 4 : 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_business,
                    size: 7.w,
                    color: Colors.amber[700],
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Other / Custom',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (_isCustomSelected) ...[
                            SizedBox(width: 2.w),
                            Icon(
                              Icons.check_circle,
                              color: Colors.amber[700],
                              size: 5.w,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Start with an empty catalogue or browse suggested items',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 4.w,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final canProceed = _selectedTemplateIds.isNotEmpty || _isCustomSelected;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!widget.isFirstTimeSetup)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ),
            if (!widget.isFirstTimeSetup) SizedBox(width: 4.w),
            Expanded(
              flex: widget.isFirstTimeSetup ? 1 : 2,
              child: ElevatedButton(
                onPressed: canProceed ? _proceedToPreview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isCustomSelected
                          ? 'Start Custom'
                          : 'Continue',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(Icons.arrow_forward, size: 5.w),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTemplateSelection(String templateId) {
    setState(() {
      if (_selectedTemplateIds.contains(templateId)) {
        _selectedTemplateIds.remove(templateId);
      } else {
        _selectedTemplateIds.add(templateId);
        _isCustomSelected = false; // Deselect custom if selecting template
      }
    });
  }

  void _toggleCustomSelection() {
    setState(() {
      _isCustomSelected = !_isCustomSelected;
      if (_isCustomSelected) {
        _selectedTemplateIds.clear(); // Clear templates if selecting custom
      }
    });
  }

  void _proceedToPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CataloguePreviewEditScreen(
          selectedTemplateIds: _selectedTemplateIds.toList(),
          isCustomMode: _isCustomSelected,
          isFirstTimeSetup: widget.isFirstTimeSetup,
          returnRoute: widget.returnRoute,
        ),
      ),
    );
  }
}
