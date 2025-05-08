import 'package:flutter/material.dart';
import 'package:psbs_app_flutter/pages/HomePage/hero.dart';
import 'package:psbs_app_flutter/pages/HomePage/services.dart';
import 'package:psbs_app_flutter/pages/HomePage/all_service.dart';
import 'package:psbs_app_flutter/pages/HomePage/about.dart';
import 'package:psbs_app_flutter/pages/HomePage/review.dart';
import 'package:psbs_app_flutter/pages/HomePage/contact.dart';
import 'package:psbs_app_flutter/pages/HomePage/footer.dart';
import 'package:psbs_app_flutter/pages/HomePage/copyright.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: HeroSection()),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(child: ServicesScreen()),
          SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(child: AllService()),
          SliverToBoxAdapter(child: AboutPage()),
          SliverToBoxAdapter(child: ReviewScreen()),
          SliverToBoxAdapter(child: ContactScreen()),
          SliverToBoxAdapter(child: Footer()),
          SliverToBoxAdapter(child: CopyrightWidget()),
        ],
      ),
    );
  }
}
