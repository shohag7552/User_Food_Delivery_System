import 'package:appwrite_user_app/app/controllers/address_controller.dart';
import 'package:appwrite_user_app/app/models/address_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Quick-edit sheet for a delivery address's textual details
/// (name, phone, city, postal). Street line and map location are preserved.
class EditAddressInfoBottomSheet extends StatefulWidget {
  final AddressModel address;

  const EditAddressInfoBottomSheet({super.key, required this.address});

  static Future<void> show(BuildContext context, AddressModel address) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAddressInfoBottomSheet(address: address),
    );
  }

  @override
  State<EditAddressInfoBottomSheet> createState() =>
      _EditAddressInfoBottomSheetState();
}

class _EditAddressInfoBottomSheetState
    extends State<EditAddressInfoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address.name);
    _phoneController = TextEditingController(text: widget.address.phone);
    _cityController = TextEditingController(text: widget.address.city);
    _postalController = TextEditingController(text: widget.address.postalCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Preserve street line, lat/lng and default flag — only text fields change.
    final updated = widget.address.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalController.text.trim(),
    );

    final saved = await Get.find<AddressController>()
        .updateAddress(widget.address.id, updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    // Navigation stays in the view: close the sheet once the save succeeds.
    if (saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: ColorResource.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Constants.radiusExtraLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ColorResource.textLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'edit_delivery_details'.tr,
                    style: poppinsBold.copyWith(
                      fontSize: Constants.fontSizeLarge,
                      color: ColorResource.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    controller: _nameController,
                    label: 'full_name'.tr,
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'required'.tr
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _phoneController,
                    label: 'phone_number'.tr,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'required'.tr;
                      if (v.trim().length < 10) return 'invalid_phone'.tr;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _cityController,
                          label: 'city'.tr,
                          icon: Icons.location_city_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'required'.tr
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildField(
                          controller: _postalController,
                          label: 'postal_code'.tr,
                          icon: Icons.markunread_mailbox_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'required'.tr
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorResource.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Constants.radiusLarge),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: ColorResource.textWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'save'.tr,
                              style: poppinsBold.copyWith(
                                fontSize: Constants.fontSizeLarge,
                                color: ColorResource.textWhite,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: poppinsRegular.copyWith(fontSize: Constants.fontSizeDefault),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Constants.radiusDefault),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
