import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../services/audio_handler.dart';
import '../services/sleep_timer_service.dart';

class SleepTimerSheet extends StatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  int? _selectedMinutes;

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTimerService>(
      builder: (_, timer, __) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined,
                      color: Color(0xFF7B5EA7), size: 22),
                  const SizedBox(width: 10),
                  const Text('Sleep Timer',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Show active countdown if timer running
                  if (timer.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B5EA7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF7B5EA7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer,
                              color: Color(0xFF7B5EA7), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            timer.remainingSeconds == -1
                                ? 'End of song'
                                : timer.remainingFormatted,
                            style: const TextStyle(
                              color: Color(0xFF7B5EA7),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                timer.isActive
                    ? timer.status == SleepTimerStatus.finishing
                        ? '🎵 Fading out...'
                        : 'Music will stop after the timer ends'
                    : 'Music will automatically stop',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Timer preset grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: SleepTimerService.presets.length,
                itemBuilder: (_, i) {
                  final preset = SleepTimerService.presets[i];
                  final minutes = preset['minutes'] as int;
                  final label = preset['label'] as String;
                  final isSelected = _selectedMinutes == minutes ||
                      (timer.isActive &&
                          timer.selectedDuration?.inMinutes == minutes);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = minutes),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7B5EA7)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7B5EA7)
                              : const Color(0xFF333333),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  // Cancel timer button (only if active)
                  if (timer.isActive) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          GetIt.I<MusicAudioHandler>().cancelSleepTimer();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red[400]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel Timer',
                            style: TextStyle(
                                color: Colors.red[400], fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Set timer button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedMinutes == null
                          ? null
                          : () {
                              final audioHandler = GetIt.I<MusicAudioHandler>();
                              if (_selectedMinutes == -1) {
                                // End of song mode
                                GetIt.I<SleepTimerService>()
                                    .startEndOfSong(onNextSongStart: () {});
                              } else {
                                audioHandler.startSleepTimer(_selectedMinutes!);
                              }
                              Navigator.pop(context);
                              // Show confirmation snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.bedtime,
                                          color: Color(0xFF7B5EA7), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedMinutes == -1
                                            ? 'Stops after current song'
                                            : 'Sleep timer set for ${SleepTimerService.presets.firstWhere((p) => p["minutes"] == _selectedMinutes)["label"]}',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  margin: const EdgeInsets.only(
                                      bottom: 80, left: 16, right: 16),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedMinutes != null
                            ? const Color(0xFF7B5EA7)
                            : const Color(0xFF333333),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        timer.isActive ? 'Update Timer' : 'Set Timer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
