import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dumppi/src/features/resorts/data/resort_model.dart';
import 'package:dumppi/src/features/resorts/logic/resort_provider.dart';

/// Screen showing a searchable list of ski resorts.
class ResortListScreen extends StatefulWidget {
  const ResortListScreen({
    required this.onResortSelected, super.key,
  });

  final void Function(Resort) onResortSelected;

  @override
  State<ResortListScreen> createState() => _ResortListScreenState();
}

class _ResortListScreenState extends State<ResortListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        title: Text(
          'SKI RESORTS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name or country...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0DB9F2)),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withAlpha(13)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withAlpha(13)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: Consumer<ResortProvider>(
        builder: (context, provider, _) {
          final filteredResorts = provider.resorts.where((resort) {
            final nameMatch = resort.name.toLowerCase().contains(_searchQuery.toLowerCase());
            final countryMatch = resort.country.toLowerCase().contains(_searchQuery.toLowerCase());
            return nameMatch || countryMatch;
          }).toList();

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (filteredResorts.isEmpty) {
            return const Center(
              child: Text(
                'No resorts found',
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredResorts.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final resort = filteredResorts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                       color: resort.isCustom 
                          ? const Color(0xFF7B61FF).withAlpha(26) 
                          : const Color(0xFF0DB9F2).withAlpha(26),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      resort.isCustom ? Icons.adjust : Icons.snowboarding,
                      color: resort.isCustom ? const Color(0xFF7B61FF) : const Color(0xFF0DB9F2),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    resort.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    resort.id == 'custom_point' 
                        ? 'SECRET STASH' 
                        : '${resort.country.toUpperCase()} • ${resort.baseAlt}M - ${resort.topAlt}M',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      resort.isFavorite ? Icons.star : Icons.star_border,
                      color: resort.isFavorite ? Colors.amber : Colors.white10,
                    ),
                    onPressed: () => provider.toggleFavorite(resort),
                  ),
                  onTap: () => widget.onResortSelected(resort),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
