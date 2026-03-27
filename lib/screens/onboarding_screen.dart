import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/singers_data.dart';
import '../models/user_preferences.dart';
import '../app.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isEditing;
  const OnboardingScreen({super.key, this.isEditing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedRegion = 'All';
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final prefs = Hive.box<UserPreferences>('user_preferences').get('prefs');
      if (prefs != null) {
        _selectedIds.addAll(prefs.favouriteSingerIds);
      }
    }
  }

  List<Singer> get _filteredSingers {
    final allSingers = allSingerCategories.expand((c) => c.singers).toList();
    if (_selectedRegion == 'All') return allSingers;
    return allSingers.where((s) => s.region.contains(_selectedRegion)).toList();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = UserPreferences(
      hasCompletedOnboarding: true,
      favouriteSingerIds: _selectedIds.toList(),
      onboardingCompletedAt: DateTime.now(),
    );
    await Hive.box<UserPreferences>('user_preferences').put('prefs', prefs);

    if (widget.isEditing) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const ResponsiveLayout(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              '🎵 Welcome to Musenzy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your favourite singers',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick at least 3 to get started',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Region filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  'All',
                  'Bollywood',
                  'Hollywood',
                  'K-Pop',
                  'Tamil',
                  'Telugu',
                  'Arabic',
                  'Latin',
                  'Bengali'
                ].map((region) {
                  final isSelected = _selectedRegion == region;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRegion = region),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF7B5EA7) : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF7B5EA7) : const Color(0xFF333333),
                        ),
                      ),
                      child: Text(
                        region,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Singer Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 5 : (MediaQuery.of(context).size.width > 600 ? 4 : 3),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _filteredSingers.length,
                itemBuilder: (context, index) {
                  final singer = _filteredSingers[index];
                  final isSelected = _selectedIds.contains(singer.id);
                  return GestureDetector(
                    onTap: () => _toggleSelection(singer.id),
                    child: _buildSingerCard(singer, isSelected),
                  );
                },
              ),
            ),

            // Bottom sticky bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(top: BorderSide(color: Color(0xFF222222))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedIds.length < 3
                        ? 'Select ${3 - _selectedIds.length} more to continue'
                        : '✓ ${_selectedIds.length} singers selected',
                    style: TextStyle(
                      color: _selectedIds.length >= 3 ? const Color(0xFF7B5EA7) : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: _selectedIds.length >= 3 ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedIds.length >= 3 ? _completeOnboarding : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B5EA7),
                          disabledBackgroundColor: const Color(0xFF7B5EA7),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isEditing ? 'Save Preferences' : 'Continue →',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingerCard(Singer singer, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: const Color(0xFF7B5EA7), width: 3)
            : Border.all(color: Colors.transparent, width: 3),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: CachedNetworkImage(
              imageUrl: singer.photoUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.person, color: Colors.grey, size: 40),
              ),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.grey, size: 30),
                      Text(
                        singer.name[0],
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(204)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: const Color(0xFF7B5EA7).withAlpha(38),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  singer.region,
                  style: TextStyle(color: Colors.grey[400], fontSize: 9),
                ),
                Text(
                  singer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF7B5EA7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
