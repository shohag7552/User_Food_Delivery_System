import 'package:appwrite_user_app/app/common/widgets/custom_button.dart';
import 'package:appwrite_user_app/app/common/widgets/custom_text_field.dart';
import 'package:appwrite_user_app/app/controllers/coupon_controller.dart';
import 'package:appwrite_user_app/app/models/coupon_model.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCouponDialog extends StatefulWidget {
  final CouponModel? coupon;
  const AddCouponDialog({super.key, this.coupon});

  @override
  State<AddCouponDialog> createState() => _AddCouponDialogState();
}

class _AddCouponDialogState extends State<AddCouponDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _usageLimitController = TextEditingController();

  final CouponController _controller = Get.find<CouponController>();

  DateTime? _validFrom;
  DateTime? _validUntil;

  @override
  void initState() {
    super.initState();

    if (widget.coupon != null) {
      _codeController.text = widget.coupon!.code;
      _descriptionController.text = widget.coupon!.description;
      _discountValueController.text = widget.coupon!.discountValue.toString();
      _minOrderController.text = widget.coupon!.minOrderAmount?.toString() ?? '';
      _maxDiscountController.text = widget.coupon!.maxDiscount?.toString() ?? '';
      _usageLimitController.text = widget.coupon!.usageLimit?.toString() ?? '';
      _validFrom = widget.coupon!.validFrom;
      _validUntil = widget.coupon!.validUntil;
      _controller.setDiscountType(widget.coupon!.discountType, withUpdate: false);
      _controller.toggleActiveStatus(widget.coupon!.isActive, withUpdate: false);
    } else {
      _validFrom = DateTime.now();
      _validUntil = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _validFrom! : _validUntil!,
      firstDate: isStartDate ? DateTime.now() : _validFrom!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _validFrom = picked;
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  void _saveCoupon() {
    if (_formKey.currentState!.validate()) {
      if (widget.coupon == null) {
        // Add new coupon
        _controller.addCoupon(
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim(),
          discountValue: double.parse(_discountValueController.text.trim()),
          minOrderAmount: _minOrderController.text.trim().isNotEmpty 
              ? double.parse(_minOrderController.text.trim())
              : null,
          maxDiscount: _maxDiscountController.text.trim().isNotEmpty
              ? double.parse(_maxDiscountController.text.trim())
              : null,
          usageLimit: _usageLimitController.text.trim().isNotEmpty
              ? int.parse(_usageLimitController.text.trim())
              : null,
          validFrom: _validFrom!,
          validUntil: _validUntil!,
        ).then((success) {
          if (success) {
            Get.back();
          }
        });
      } else {
        // Update existing coupon
        _controller.updateCoupon(
          id: widget.coupon!.id!,
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim(),
          discountValue: double.parse(_discountValueController.text.trim()),
          minOrderAmount: _minOrderController.text.trim().isNotEmpty
              ? double.parse(_minOrderController.text.trim())
              : null,
          maxDiscount: _maxDiscountController.text.trim().isNotEmpty
              ? double.parse(_maxDiscountController.text.trim())
              : null,
          usageLimit: _usageLimitController.text.trim().isNotEmpty
              ? int.parse(_usageLimitController.text.trim())
              : null,
          validFrom: _validFrom!,
          validUntil: _validUntil!,
          usedCount: widget.coupon!.usedCount,
        ).then((success) {
          if (success) {
            Get.back();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: GetBuilder<CouponController>(
                builder: (couponController) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_offer_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.coupon == null
                                  ? 'Add Coupon'
                                  : 'Edit Coupon',
                              style: poppinsBold.copyWith(
                                fontSize: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Coupon Code
                      CustomTextField(
                        controller: _codeController,
                        label: 'Coupon Code *',
                        hintText: 'e.g., SAVE20',
                        icon: Icons.confirmation_number_rounded,
                        validator: couponController.validateCode,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description *',
                        hintText: 'e.g., 20% off on orders above \$50',
                        icon: Icons.description_rounded,
                        validator: couponController.validateDescription,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Discount Type Selector
                      Text(
                        'Discount Type *',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DiscountTypeButton(
                              label: 'Percentage',
                              isSelected: couponController.discountType == 'percentage',
                              icon: Icons.percent_rounded,
                              onTap: () => couponController.setDiscountType('percentage'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DiscountTypeButton(
                              label: 'Fixed Amount',
                              isSelected: couponController.discountType == 'fixed',
                              icon: Icons.attach_money_rounded,
                              onTap: () => couponController.setDiscountType('fixed'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Discount Value
                      CustomTextField(
                        controller: _discountValueController,
                        label: couponController.discountType == 'percentage'
                            ? 'Discount Percentage *'
                            : 'Discount Amount *',
                        hintText: couponController.discountType == 'percentage'
                            ? 'e.g., 20'
                            : 'e.g., 10.00',
                        icon: couponController.discountType == 'percentage'
                            ? Icons.percent_rounded
                            : Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        validator: couponController.validateDiscountValue,
                      ),
                      const SizedBox(height: 16),

                      // Min Order Amount (Optional)
                      CustomTextField(
                        controller: _minOrderController,
                        label: 'Minimum Order Amount',
                        hintText: 'e.g., 50.00 (optional)',
                        icon: Icons.shopping_cart_rounded,
                        keyboardType: TextInputType.number,
                        validator: couponController.validateMinOrder,
                      ),
                      const SizedBox(height: 16),

                      // Max Discount (for percentage type)
                      if (couponController.discountType == 'percentage')
                        Column(
                          children: [
                            CustomTextField(
                              controller: _maxDiscountController,
                              label: 'Maximum Discount Cap',
                              hintText: 'e.g., 100.00 (optional)',
                              icon: Icons.discount_rounded,
                              keyboardType: TextInputType.number,
                              validator: couponController.validateMinOrder,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Usage Limit
                      CustomTextField(
                        controller: _usageLimitController,
                        label: 'Usage Limit',
                        hintText: 'e.g., 100 (leave empty for unlimited)',
                        icon: Icons.people_rounded,
                        keyboardType: TextInputType.number,
                        validator: couponController.validateUsageLimit,
                      ),
                      const SizedBox(height: 16),

                      // Validity Period
                      Text(
                        'Validity Period *',
                        style: poppinsMedium.copyWith(
                          fontSize: Constants.fontSizeDefault,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DateSelector(
                              label: 'Valid From',
                              date: _validFrom,
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateSelector(
                              label: 'Valid Until',
                              date: _validUntil,
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active Status Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.toggle_on_rounded,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Active Status',
                                style: poppinsMedium.copyWith(
                                  fontSize: Constants.fontSizeDefault,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            Switch(
                              value: couponController.isActive,
                              onChanged: couponController.toggleActiveStatus,
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: poppinsMedium.copyWith(
                                  fontSize: Constants.fontSizeDefault,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              height: 50,
                              elevation: 0,
                              onPressed: couponController.isLoading ? null : _saveCoupon,
                              isLoading: couponController.isLoading,
                              buttonText: widget.coupon == null ? 'Add' : 'Update',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for discount type selection
class _DiscountTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _DiscountTypeButton({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: poppinsMedium.copyWith(
                fontSize: 14,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for date selection
class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: poppinsRegular.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Select Date',
                  style: poppinsMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
