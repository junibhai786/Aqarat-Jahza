import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:aqarat_app/features/properties/data/models/property_model.dart';
import 'package:aqarat_app/features/properties/domain/entities/property.dart';
import 'package:aqarat_app/features/properties/presentation/pages/property_details_page.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key, required this.repository});

  final BuyerRepository repository;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Property>> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = _load();
  }

  Future<List<Property>> _load() async {
    final favorites = await widget.repository.favorites();
    return favorites.map((item) {
      final property = item['property'];
      return PropertyModel.fromJson(
        (property is Map ? property : item).cast<String, dynamic>(),
      );
    }).toList();
  }

  Future<void> _toggle(Property property) async {
    try {
      await widget.repository.toggleFavorite(property.id);
      if (!mounted) return;
      setState(() => _favorites = _load());
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.tr('favourites')),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.search, size: 18),
                label: Text(context.tr('discoverProperties')),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<Property>>(
          future: _favorites,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final properties = snapshot.data ?? const <Property>[];
            if (properties.isEmpty) return _empty(context);
            return RefreshIndicator(
              onRefresh: () async => setState(() => _favorites = _load()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(context),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E9E4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(context.tr('placesWorthReturning'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                        Text('${properties.length} ${context.tr('savedPropertiesCount')}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]),
                      const SizedBox(height: 14),
                      ...properties.map(_card),
                    ]),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _header(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('yourPersonalSpace'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(context.tr('favourites'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(context.tr('allDetailsOnePlace'), style: const TextStyle(color: Colors.black54)),
        ],
      );

  Widget _empty(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.favorite_border, size: 48, color: Color(0xFF91AE9D)),
          const SizedBox(height: 12),
          Text(context.tr('noFavourites')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('discoverProperties'))),
        ]),
      );

  Widget _card(Property property) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4E9E6))),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PropertyDetailsPage(propertyId: property.id, preview: property))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 175,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  property.images.isEmpty ? Container(color: const Color(0xFFE9F2ED), child: const Icon(Icons.home_work_outlined, size: 54)) : Image.network(_imageUrl(property.images.first), fit: BoxFit.cover),
                  PositionedDirectional(top: 10, end: 10, child: Material(color: Colors.white, shape: const CircleBorder(), child: IconButton(onPressed: () => _toggle(property), icon: const Icon(Icons.favorite, color: Colors.red)))),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(children: [const Icon(Icons.location_on_outlined, size: 16), const SizedBox(width: 4), Expanded(child: Text(property.region, style: const TextStyle(fontSize: 12, color: Colors.black54)))]),
                const SizedBox(height: 8),
                Text('${property.price} EGP', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                Text('${property.area ?? 0} m²   |   ${property.rooms ?? 0} ${context.tr('bedrooms')}   |   ${property.baths ?? 0} ${context.tr('bathrooms')}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PropertyDetailsPage(propertyId: property.id, preview: property))), child: Text(context.tr('details')))),
              ]),
            ),
          ]),
        ),
      );

  String _imageUrl(String path) => path.startsWith('http') ? path : 'http://192.168.18.66:3000$path';
}
