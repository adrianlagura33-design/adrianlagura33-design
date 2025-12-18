import 'package:flutter/material.dart';

class TestImagesScreen extends StatelessWidget {
  const TestImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleBraids = [
      {
        'name': 'Box Braids',
        'image': 'assets/Photo/boxbraids.jpg',
      },
      {
        'name': 'Cornrows',
        'image': 'assets/Photo/cornrows.jpeg',
      },
      {
        'name': 'Knotless Braids',
        'image': 'assets/Photo/knotlessbraids.jpeg',
      },
      {
        'name': 'Twists',
        'image': 'assets/Photo/twist.jpeg',
      },
      {
        'name': 'Fishtail Braids',
        'image': 'assets/Photo/fishtail-braids.jpg',
      },
      {
        'name': 'Stitch Braids',
        'image': 'assets/Photo/stitch-braids.jpg',
      },
      {
        'name': 'Zig Zag Braids',
        'image': 'assets/Photo/zigzag_cornrow.jpg',
      },
      {
        'name': 'Braided Man Bun',
        'image': 'assets/Photo/man_bun_braids.jpg',
      },
      {
        'name': 'Feed In Braids',
        'image': 'assets/Photo/feed_in.jpeg',
      },
      {
        'name': 'Men Pop Smoke',
        'image': 'assets/Photo/pop_smoke.jpg',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Images'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: sampleBraids.length,
        itemBuilder: (context, index) {
          final braid = sampleBraids[index];
          return Card(
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    braid['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(braid['name'] as String),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}