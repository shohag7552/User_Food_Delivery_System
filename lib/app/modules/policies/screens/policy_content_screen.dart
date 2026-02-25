import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class PolicyContentScreen extends StatelessWidget {
  final String title;
  final String htmlContent;

  const PolicyContentScreen({
    super.key,
    required this.title,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorResource.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: ColorResource.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: poppinsBold.copyWith(
                  fontSize: Constants.fontSizeDefault,
                  color: ColorResource.textWhite,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: ColorResource.primaryGradient,
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    // Icon
                    Positioned(
                      bottom: 48,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconForTitle(title),
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: htmlContent.isNotEmpty
                ? _buildHtmlContent()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorResource.cardBackground,
        borderRadius: BorderRadius.circular(Constants.radiusLarge),
        boxShadow: ColorResource.customShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Html(
          data: htmlContent,
          style: {
            'body': Style(
              fontFamily: 'Poppins',
              fontSize: FontSize(14),
              color: ColorResource.textPrimary,
              lineHeight: LineHeight(1.7),
              padding: HtmlPaddings.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            'h1': Style(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: FontSize(20),
              color: ColorResource.primaryDark,
              margin: Margins.only(top: 12, bottom: 8),
            ),
            'h2': Style(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: FontSize(17),
              color: ColorResource.primaryDark,
              margin: Margins.only(top: 12, bottom: 6),
            ),
            'h3': Style(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: FontSize(15),
              color: ColorResource.primaryMedium,
              margin: Margins.only(top: 10, bottom: 4),
            ),
            'p': Style(
              margin: Margins.only(bottom: 10),
              fontSize: FontSize(14),
            ),
            'li': Style(
              fontSize: FontSize(14),
              margin: Margins.only(bottom: 4),
            ),
            'a': Style(
              color: ColorResource.primaryMedium,
              textDecoration: TextDecoration.underline,
            ),
            'strong': Style(
              fontWeight: FontWeight.w600,
              color: ColorResource.textPrimary,
            ),
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorResource.primaryDark.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForTitle(title),
              size: 48,
              color: ColorResource.primaryDark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Content Not Available',
            style: poppinsBold.copyWith(
              fontSize: Constants.fontSizeLarge,
              color: ColorResource.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This section is currently being updated.\nPlease check back later.',
            textAlign: TextAlign.center,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeDefault,
              color: ColorResource.textLight,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForTitle(String title) {
    if (title.toLowerCase().contains('about')) {
      return Icons.info_outline_rounded;
    } else if (title.toLowerCase().contains('terms')) {
      return Icons.description_outlined;
    } else {
      return Icons.privacy_tip_outlined;
    }
  }
}
