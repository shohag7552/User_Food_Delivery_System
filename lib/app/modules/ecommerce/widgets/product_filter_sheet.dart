import 'package:appwrite_user_app/app/controllers/category_controller.dart';
import 'package:appwrite_user_app/app/controllers/product_controller.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/models/product_filter_model.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Opens the storefront product filter and applies the result.
///
/// Presentation follows the width, not the platform: a modal bottom sheet on
/// phones (thumb-reachable, keyboard-aware) and a centred dialog once there is
/// desktop-class width — the same split the rest of the app uses.
abstract class ProductFilterFlow {
  const ProductFilterFlow._();

  /// Wide-layout breakpoint, matching the storefront's own `isWide`.
  static const double _dialogBreakpoint = 900;
  static const double _dialogWidth = 520;

  static Future<void> open(BuildContext context) async {
    final productController = Get.find<ProductController>();
    final current = productController.productFilter;
    final useDialog =
        MediaQuery.sizeOf(context).width >= _dialogBreakpoint;

    final ProductFilter? result = useDialog
        ? await showDialog<ProductFilter>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(Constants.paddingSizeLarge),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _dialogWidth),
                child: _ProductFilterForm(initial: current, isDialog: true),
              ),
            ),
          )
        : await showModalBottomSheet<ProductFilter>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) =>
                _ProductFilterForm(initial: current, isDialog: false),
          );

    if (result != null) {
      await productController.applyProductFilter(result);
    }
  }
}

class _ProductFilterForm extends StatefulWidget {
  final ProductFilter initial;
  final bool isDialog;

  const _ProductFilterForm({required this.initial, required this.isDialog});

  @override
  State<_ProductFilterForm> createState() => _ProductFilterFormState();
}

class _ProductFilterFormState extends State<_ProductFilterForm> {
  late bool _onlyOffers = widget.initial.onlyOffers;
  late String? _categoryId = widget.initial.categoryId;
  late final TextEditingController _minController = TextEditingController(
    text: _formatBound(widget.initial.minPrice),
  );
  late final TextEditingController _maxController = TextEditingController(
    text: _formatBound(widget.initial.maxPrice),
  );

  /// Set when the entered range is inverted; blocks Apply until corrected.
  bool _rangeInvalid = false;

  /// Trims a trailing `.0` so a previously applied bound reads as "500", not
  /// "500.0", when the sheet is reopened.
  static String _formatBound(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  double? get _min => double.tryParse(_minController.text.trim());
  double? get _max => double.tryParse(_maxController.text.trim());

  void _reset() {
    setState(() {
      _onlyOffers = false;
      _categoryId = null;
      _minController.clear();
      _maxController.clear();
      _rangeInvalid = false;
    });
  }

  void _apply() {
    final min = _min;
    final max = _max;

    if (min != null && max != null && min >= max) {
      setState(() => _rangeInvalid = true);
      return;
    }

    Navigator.of(context).pop(
      ProductFilter(
        onlyOffers: _onlyOffers,
        minPrice: min,
        maxPrice: max,
        categoryId: _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isDialog
        ? BorderRadius.circular(Constants.radiusExtraLarge)
        : const BorderRadius.vertical(
            top: Radius.circular(Constants.radiusExtraLarge),
          );

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: borderRadius,
      ),
      // Bottom sheets must clear the keyboard when the price fields focus.
      padding: EdgeInsets.only(
        bottom: widget.isDialog
            ? 0
            : MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isDialog) _buildDragHandle(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Constants.paddingSizeLarge,
                  Constants.paddingSizeSmall,
                  Constants.paddingSizeLarge,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTitleRow(),
                    const SizedBox(height: Constants.paddingSizeDefault),
                    _buildOffersToggle(),
                    const SizedBox(height: Constants.paddingSizeLarge),
                    _sectionLabel('category'.tr),
                    _buildCategoryChips(),
                    const SizedBox(height: Constants.paddingSizeLarge),
                    _sectionLabel('price_range'.tr),
                    _buildPriceFields(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: Constants.paddingSizeSmall),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.textLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(Constants.radiusSmall),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'filters'.tr,
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeExtraLarge,
              color: context.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          color: context.textSecondary,
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Constants.paddingSizeSmall),
      child: Text(
        text,
        style: poppinsBold.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _buildOffersToggle() {
    return InkWell(
      onTap: () => setState(() => _onlyOffers = !_onlyOffers),
      borderRadius: BorderRadius.circular(Constants.radiusDefault),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Constants.paddingSizeExtraSmall,
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 20,
              color: ColorResource.primaryDark,
            ),
            const SizedBox(width: Constants.paddingSizeSmall),
            Expanded(
              child: Text(
                'on_sale_only'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: context.textPrimary,
                ),
              ),
            ),
            Switch(
              value: _onlyOffers,
              onChanged: (value) => setState(() => _onlyOffers = value),
              activeThumbColor: ColorResource.textWhite,
              activeTrackColor: ColorResource.primaryDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        final categories = categoryController.categories;

        return Wrap(
          spacing: Constants.paddingSizeSmall,
          runSpacing: Constants.paddingSizeSmall,
          children: [
            _choiceChip(
              label: 'all_categories'.tr,
              selected: _categoryId == null,
              onSelected: () => setState(() => _categoryId = null),
            ),
            for (final category in categories)
              _choiceChip(
                label: category.nameMap.trLanguage,
                selected: _categoryId == category.id,
                onSelected: () => setState(() => _categoryId = category.id),
              ),
          ],
        );
      },
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      backgroundColor: context.scaffoldBackground,
      selectedColor: ColorResource.primaryDark.withValues(alpha: 0.12),
      labelStyle: poppinsMedium.copyWith(
        fontSize: Constants.fontSizeSmall,
        color: selected ? ColorResource.primaryDark : context.textSecondary,
      ),
      side: BorderSide(
        color: selected
            ? ColorResource.primaryDark
            : context.textLight.withValues(alpha: 0.35),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.radiusDefault),
      ),
    );
  }

  Widget _buildPriceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _priceField(_minController, 'min_price'.tr)),
            const SizedBox(width: Constants.paddingSizeSmall),
            Expanded(child: _priceField(_maxController, 'max_price'.tr)),
          ],
        ),
        const SizedBox(height: Constants.paddingSizeExtraSmall),
        Text(
          _rangeInvalid
              ? 'invalid_price_range'.tr
              : 'filter_by_list_price'.tr,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeExtraSmall,
            color: _rangeInvalid ? ColorResource.error : context.textLight,
          ),
        ),
      ],
    );
  }

  Widget _priceField(TextEditingController controller, String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Constants.radiusDefault),
      borderSide: BorderSide(color: color),
    );

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      // Clear the inverted-range error as soon as the user edits either side.
      onChanged: (_) {
        if (_rangeInvalid) setState(() => _rangeInvalid = false);
      },
      style: poppinsMedium.copyWith(
        fontSize: Constants.fontSizeDefault,
        color: context.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: poppinsRegular.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: context.textLight,
        ),
        prefixText: '${PriceHelper.getCurrencySymbol()} ',
        prefixStyle: poppinsMedium.copyWith(
          fontSize: Constants.fontSizeDefault,
          color: context.textSecondary,
        ),
        filled: true,
        fillColor: context.scaffoldBackground,
        border: border(context.textLight.withValues(alpha: 0.35)),
        enabledBorder: border(
          _rangeInvalid
              ? ColorResource.error
              : context.textLight.withValues(alpha: 0.35),
        ),
        focusedBorder: border(ColorResource.primaryDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Constants.paddingSizeDefault,
          vertical: Constants.paddingSizeSmall,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(Constants.paddingSizeLarge),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textSecondary,
                padding: const EdgeInsets.symmetric(
                  vertical: Constants.paddingSizeDefault,
                ),
                side: BorderSide(
                  color: context.textLight.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
              ),
              child: Text(
                'reset'.tr,
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                ),
              ),
            ),
          ),
          const SizedBox(width: Constants.paddingSizeSmall),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorResource.primaryDark,
                foregroundColor: ColorResource.textWhite,
                padding: const EdgeInsets.symmetric(
                  vertical: Constants.paddingSizeDefault,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Constants.radiusDefault),
                ),
              ),
              child: Text(
                'apply'.tr,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
