import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class PhotoUploadScreen extends ConsumerWidget {
  const PhotoUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('📸', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('Add your photos',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 8),
                  Text('Profiles with photos get 3× more matches!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSoft)),
                  const SizedBox(height: 32),

                  // Photo grid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add photos', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSoft)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Main photo slot
                          Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.terracottaSoft,
                              border: Border.all(color: AppColors.terracotta, width: 2, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('+', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.terracotta)),
                                Text('Main', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.terracotta)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ...List.generate(3, (i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                border: Border.all(color: AppColors.border, width: 2, style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.add, color: AppColors.textMuted, size: 24),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.terracottaSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.terracotta, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Photo upload available on mobile. You can add photos from your profile settings.',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.terracotta),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/onboarding/questionnaire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Continue to lifestyle quiz →',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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
}
