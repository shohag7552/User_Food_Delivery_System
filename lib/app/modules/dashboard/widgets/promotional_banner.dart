import 'dart:async';
import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/models/banner_model.dart';

class PromotionalBanner extends StatefulWidget {
  final List<BannerModel> banners;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Duration autoScrollDuration;

  const PromotionalBanner({
    super.key,
    required this.banners,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.autoScrollDuration = const Duration(seconds: 4),
  });

  @override
  State<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends State<PromotionalBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(widget.autoScrollDuration, (timer) {
        if (_currentPage < widget.banners.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    // Error state
    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    // Empty state
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return GestureDetector(
                onTap: () {
                  // Handle banner tap based on action type
                  if (banner.hasAction) {
                    _handleBannerTap(banner);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: ColorResource.shadowMedium,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Constants.radiusLarge),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Banner image
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: ColorResource.primaryGradient,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.local_offer,
                                  size: 60,
                                  color:
                                      ColorResource.textWhite.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        ),
                        CustomNetworkImage(image: banner.imageUrl, width: double.infinity, height: double.infinity),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                        // Banner text
                        if (banner.title != null || banner.subtitle != null)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (banner.title != null)
                                  Text(
                                    banner.title!,
                                    style: poppinsBold.copyWith(
                                      fontSize: Constants.fontSizeExtraLarge,
                                      color: ColorResource.textWhite,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (banner.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    banner.subtitle!,
                                    style: poppinsRegular.copyWith(
                                      fontSize: Constants.fontSizeSmall,
                                      color: ColorResource.textWhite,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dot indicators
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? ColorResource.primaryDark
                      : ColorResource.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: ColorResource.shadowMedium,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorResource.primaryDark),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        border: Border.all(
          color: ColorResource.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: ColorResource.error,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load banners',
                style: poppinsMedium.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textPrimary,
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text(
                    'Retry',
                    style: poppinsMedium.copyWith(
                      fontSize: Constants.fontSizeDefault,
                      color: ColorResource.primaryDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleBannerTap(BannerModel banner) {
    // TODO: Implement navigation based on action type
    // This can be implemented when needed
    print('Banner tapped: ${banner.actionType} - ${banner.actionValue}');
  }
}
