import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/product.dart';

class ProductCard extends HookConsumerWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: product.imagePath.isEmpty 
                  ? Container(
                      color: AppColors.outlineVariant,
                      child: const Center(child: Icon(Icons.image_not_supported, color: AppColors.outline)),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Skeletonizer(
                        enabled: true,
                        child: Bone.square(size: 400),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.outlineVariant,
                        child: const Center(child: Icon(Icons.error, color: AppColors.outline)),
                      ),
                    ),
            ),

          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.unit ?? '',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs. ${product.price.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: onAdd,
                      borderRadius: AppRadius.circularSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: AppRadius.circularSm,
                        ),
                        child: const Text(
                          'ADD',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
