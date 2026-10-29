import 'package:aqarat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqarat_app/features/auth/presentation/pages/login_page.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/features/buyer/presentation/pages/favorites_page.dart';
import 'package:aqarat_app/features/buyer/presentation/pages/buyer_dashboard_page.dart';
import 'package:aqarat_app/features/buyer/presentation/pages/profile_page.dart';
import 'package:aqarat_app/features/buyer/presentation/pages/leads_page.dart';
import 'package:aqarat_app/features/buyer/presentation/pages/bookings_page.dart';
import 'package:aqarat_app/features/seller/presentation/pages/seller_workspace_page.dart';
import 'package:aqarat_app/features/seller/presentation/pages/seller_activity_pages.dart';
import 'package:aqarat_app/injection_container.dart';
import 'package:aqarat_app/features/properties/domain/entities/property.dart';
import 'package:aqarat_app/features/properties/presentation/bloc/property_bloc.dart';
import 'package:aqarat_app/features/properties/presentation/pages/property_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  final _priceRange = TextEditingController();
  String? _sort;
  String? _region;
  String? _type;
  String? _kind;
  String? _rooms;
  String? _selectedCategory;
  Set<int> _favoriteIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PropertyBloc>().add(const PropertiesRequested());
        _loadBuyerOverview();
      }
    });
  }

  @override
  void dispose() {
    _priceRange.dispose();
    super.dispose();
  }

  void _filter() {
    final filters = <String, dynamic>{};
    if (_sort != null) {
      filters['sort'] = _sort;
    }
    if (_region != null) filters['region'] = _region;
    if (_type != null) filters['type'] = _type;
    if (_kind != null) filters['kind'] = _kind;
    final prices = _priceRange.text
        .replaceAll(',', '')
        .split(RegExp(r'\s*[-–]\s*'))
        .where((value) => value.trim().isNotEmpty)
        .toList();
    if (prices.isNotEmpty) filters['min'] = prices.first.trim();
    if (prices.length > 1) filters['max'] = prices[1].trim();
    if (_rooms != null) filters['rooms'] = _rooms;
    context.read<PropertyBloc>().add(PropertiesRequested(filters: filters));
  }

  bool get _isBuyer => context.read<AuthBloc>().state.user?.role == 'buyer';
  bool get _isSeller => context.read<AuthBloc>().state.user?.role == 'seller';

  Future<void> _loadBuyerOverview() async {
    if (!_isBuyer) return;
    try {
      final repository = await InjectionContainer.buyerRepository();
      final favorites = await repository.favorites();
      if (!mounted) return;
      setState(() {
        _favoriteIds = favorites.map(_favoritePropertyId).whereType<int>().toSet();
      });
    } on ApiException {
      // The public property list remains usable if a buyer endpoint fails.
    }
  }

  int? _favoritePropertyId(Map<String, dynamic> item) {
    final property = item['property'];
    final rawId = property is Map ? property['id'] : item['property_id'] ?? item['id'];
    return int.tryParse(rawId?.toString() ?? '');
  }

  Future<void> _toggleFavorite(Property property) async {
    if (!_isBuyer) return;
    final wasFavorite = _favoriteIds.contains(property.id);
    setState(() {
      if (wasFavorite) {
        _favoriteIds.remove(property.id);
      } else {
        _favoriteIds.add(property.id);
      }
    });
    try {
      final repository = await InjectionContainer.buyerRepository();
      await repository.toggleFavorite(property.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(wasFavorite ? 'favouriteRemoved' : 'favouriteAdded'))));
      _loadBuyerOverview();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.add(property.id);
        } else {
          _favoriteIds.remove(property.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
        listener: (context, s) {
          if (s.status == AuthStatus.initial) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              (_) => false,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Image.asset(_logoAsset(context), height: 34),
            centerTitle: false,
          ),
          drawer: _tab == 0 ? Drawer(child: SafeArea(child: _drawer())) : null,
          body: SafeArea(
            child: IndexedStack(
              index: _tab,
              children: [_list(true), _list(false), _settings()],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: context.tr('home'),
              ),
              NavigationDestination(
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment),
                label: context.tr('properties'),
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: context.tr('settings'),
              ),
            ],
          ),
        ),
      );

  Widget _list(bool home) => BlocBuilder<PropertyBloc, PropertyState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: () async => _filter(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (home) ...[
                _hero(),
                const SizedBox(height: 20),
                Text(
                  context.tr('browseByCategory'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                _categories(),
                const SizedBox(height: 24),
              ],
              Text(
                home ? context.tr('featuredProperties') : context.tr('properties'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _filters(),
              const SizedBox(height: 18),
              if (state.status == PropertyStatus.loading &&
                  state.properties.isEmpty)
                Padding(
                  padding: EdgeInsets.all(50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == PropertyStatus.failure)
                _error(state.error ?? 'Could not load properties')
              else if (state.properties.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(50),
                  child: Center(child: Text(context.tr('noProperties'))),
                )
              else
                ...state.properties.map(_card),
              if (state.hasMore)
                OutlinedButton(
                  onPressed: () => context
                      .read<PropertyBloc>()
                      .add(const NextPropertiesRequested()),
                  child: Text(context.tr('loadMore')),
                ),
            ],
          ),
        ),
      );

  Widget _hero() => Container(
        height: 235,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF003F35), Color(0xFF098063)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -25,
              child: Icon(
                Icons.location_city_rounded,
                size: 255,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    _logoAsset(context),
                    height: 36,
                    width: 160,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Text(
                    context.tr('findProperty'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('verifiedListings'),
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00735A),
                    ),
                    onPressed: () => setState(() => _tab = 1),
                    icon: const Icon(Icons.search),
                    label: Text(context.tr('exploreProperties')),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _openFavorites() async {
    if (!_isBuyer) return;
    final repository = await InjectionContainer.buyerRepository();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FavoritesPage(repository: repository)));
    _loadBuyerOverview();
  }

  Future<void> _openDashboard() async {
    if (!_isBuyer) return;
    final repository = await InjectionContainer.buyerRepository();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BuyerDashboardPage(
        repository: repository,
        name: context.read<AuthBloc>().state.user?.fullName ?? '',
      ),
    ));
    _loadBuyerOverview();
  }

  Future<void> _openLeads() async {
    if (!_isBuyer) return;
    final repository = await InjectionContainer.buyerRepository();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LeadsPage(
        repository: repository,
        regions: context.read<PropertyBloc>().state.regions,
      ),
    ));
  }

  Future<void> _openBookings() async {
    if (!_isBuyer) return;
    final repository = await InjectionContainer.buyerRepository();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookingsPage(repository: repository)),
    );
  }

  Future<void> _openSellerWorkspace() async {
    if (!_isSeller) return;
    final repository = await InjectionContainer.sellerRepository();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SellerWorkspacePage(
        repository: repository,
        name: context.read<AuthBloc>().state.user?.fullName ?? '',
      ),
    ));
  }

  Future<T?> _openSellerPage<T>(Widget Function(dynamic repository) page) async {
    if (!_isSeller) return null;
    final repository = await InjectionContainer.sellerRepository();
    if (!mounted) return null;
    return Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page(repository)));
  }

  void _selectCategory(String label, {String? type, String? kind}) {
    setState(() {
      final isSelected = _selectedCategory == label;
      _selectedCategory = isSelected ? null : label;
      _type = isSelected ? null : type;
      _kind = isSelected ? null : kind;
    });
    _filter();
  }

  Widget _categories() => SizedBox(
        height: 78,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _Category(
              icon: Icons.home_work_outlined,
              label: context.tr('forSale'),
              selected: _selectedCategory == 'For Sale',
              onTap: () => _selectCategory('For Sale', type: 'sale'),
            ),
            _Category(
              icon: Icons.key_outlined,
              label: context.tr('forRent'),
              selected: _selectedCategory == 'For Rent',
              onTap: () => _selectCategory('For Rent', type: 'rent'),
            ),
            _Category(
              icon: Icons.weekend_outlined,
              label: context.tr('furnished'),
              selected: _selectedCategory == 'Furnished',
              onTap: () => _selectCategory('Furnished', kind: 'furnished'),
            ),
            _Category(
              icon: Icons.storefront_outlined,
              label: context.tr('commercial'),
              selected: _selectedCategory == 'Commercial',
              onTap: () => _selectCategory('Commercial', kind: 'commercial'),
            ),
            _Category(
              icon: Icons.business_outlined,
              label: context.tr('offices'),
              selected: _selectedCategory == 'Offices',
              onTap: () => _selectCategory('Offices', kind: 'office'),
            ),
          ],
        ),
      );

  Widget _filters() {
    final regions = context.read<PropertyBloc>().state.regions;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14)],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: _region, isExpanded: true, hint: Text(context.tr('area')), items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => _region = v))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(value: _type, hint: Text(context.tr('anyType')), items: [DropdownMenuItem(value: 'sale', child: Text(context.tr('forSale'))), DropdownMenuItem(value: 'rent', child: Text(context.tr('forRent'))), DropdownMenuItem(value: 'admin', child: Text(context.tr('administrative')))], onChanged: (v) => setState(() => _type = v))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _priceRange, keyboardType: TextInputType.text, decoration: InputDecoration(labelText: '${context.tr('priceFrom')} - ${context.tr('priceTo')}', hintText: '5000 - 10000'))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(value: _rooms, hint: Text(context.tr('bedrooms')), items: [DropdownMenuItem(value: '1', child: Text('1 ${context.tr('bedroom')}')), DropdownMenuItem(value: '2', child: Text('2 ${context.tr('bedrooms')}')), DropdownMenuItem(value: '3', child: Text('3 ${context.tr('bedrooms')}')), DropdownMenuItem(value: '4', child: Text('4+ ${context.tr('bedrooms')}'))], onChanged: (v) => setState(() => _rooms = v))),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _filter, icon: const Icon(Icons.search), label: Text(context.tr('search')))),
        TextButton(onPressed: () { _priceRange.clear(); setState(() { _region = null; _type = null; _kind = null; _rooms = null; _sort = null; _selectedCategory = null; }); _filter(); }, child: Text(context.tr('clearFilters'))),
      ]),
    );
  }

  Widget _card(Property p) => Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => PropertyDetailsPage(propertyId: p.id, preview: p)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 155,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    p.images.isEmpty
                        ? Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.home_work_outlined, size: 48),
                        )
                        : Image.network(
                            _imageUrl(p.images.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: const Icon(Icons.home_work_outlined, size: 48),
                            ),
                          ),
                    if (_isBuyer)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => _toggleFavorite(p),
                            icon: Icon(
                              _favoriteIds.contains(p.id) ? Icons.favorite : Icons.favorite_border,
                              color: _favoriteIds.contains(p.id) ? Colors.red : const Color(0xFF007A61),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${p.kind} - ${p.region}'),
                    const SizedBox(height: 8),
                    Text(
                      '${p.price} EGP',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('${p.area ?? 0} ${context.tr('metersSquared')}  |  ${p.rooms ?? 0} ${context.tr('bedrooms')}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  String _imageUrl(String path) =>
      path.startsWith('http') ? path : 'http://192.168.18.66:3000$path';

  String _logoAsset(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar'
          ? 'assets/images/aqarat_jahza_logo_ar.png'
          : 'assets/images/aqarat_jahza_logo.png';

  Widget _error(String text) => Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              Text(text),
              TextButton(
                onPressed: _filter,
                child: Text(context.tr('tryAgain')),
              ),
            ],
          ),
        ),
      );

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.tr('settings'),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(context.tr('myProfile')),
          subtitle: Text(context.tr('profileSubtitle')),
          onTap: _openProfile,
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(context.tr('language')),
          subtitle: Text(AppLocaleController.instance.value.languageCode == 'ar' ? context.tr('arabic') : context.tr('english')),
          onTap: () => _languageDialog(),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(context.tr('logout')),
          onTap: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
          title: Text(context.tr('deleteAccount'), style: const TextStyle(color: Colors.red)),
          subtitle: Text(context.tr('deleteAccountSubtitle')),
          onTap: _deleteAccountDialog,
        ),
      ],
    );
  }

  Future<void> _languageDialog() async {
    await showModalBottomSheet<void>(context: context, builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(title: Text(context.tr('language'), style: const TextStyle(fontWeight: FontWeight.bold))), ListTile(leading: const Text('EN'), title: Text(context.tr('english')), onTap: () async { await AppLocaleController.instance.setLanguage('en'); if (sheetContext.mounted) Navigator.pop(sheetContext); }), ListTile(leading: const Text('ع'), title: Text(context.tr('arabic')), onTap: () async { await AppLocaleController.instance.setLanguage('ar'); if (sheetContext.mounted) Navigator.pop(sheetContext); })])));
  }

  Future<void> _openProfile() async {
    if (!_isBuyer && !_isSeller) return;
    if (!mounted) return;
    if (_isBuyer) {
      final repository = await InjectionContainer.buyerRepository();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfilePage(repository: repository)));
    } else {
      final repository = await InjectionContainer.sellerRepository();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SellerAccountPage(repository: repository)));
    }
  }

  Future<void> _deleteAccountDialog() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(context.tr('deleteAccountQuestion')), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('deleteAccountWarning')), const SizedBox(height: 16), TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: context.tr('currentPassword')))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(context.tr('cancel'))), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(dialogContext, true), child: Text(context.tr('delete')))]));
    if (confirmed != true || password.text.isEmpty || !mounted) { password.dispose(); return; }
    try {
      await InjectionContainer.buyerRepository().then((repository) => repository.deleteAccount(currentPassword: password.text));
      if (mounted) context.read<AuthBloc>().add(const AuthLogoutRequested());
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally { password.dispose(); }
  }

  Widget _drawer() {
    final user = context.read<AuthBloc>().state.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 14, 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('workspaceTitle'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 5),
              Text(user?.fullName ?? 'Aqarat Jahza', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ])),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(context.tr('workspace'), style: const TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.black45, fontWeight: FontWeight.bold))),
        const SizedBox(height: 14),
        if (_isBuyer)
          _drawerItem(Icons.grid_view_rounded, context.tr('dashboard'), false, () async {
            Navigator.pop(context);
            await _openDashboard();
          }),
        if (_isBuyer)
          _drawerItem(Icons.favorite_border, context.tr('favourites'), false, () async {
            final repository = await InjectionContainer.buyerRepository();
            if (!mounted) return;
            final navigator = Navigator.of(context);
            navigator.pop();
            await navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => FavoritesPage(repository: repository),
              ),
            );
            _loadBuyerOverview();
          }),
        if (_isBuyer)
          _drawerItem(Icons.calendar_month_outlined, context.tr('viewings'), false, () async {
            Navigator.pop(context);
            await _openBookings();
          }),
        if (_isBuyer)
          _drawerItem(Icons.chat_bubble_outline, context.tr('requests'), false, () async {
            Navigator.pop(context);
            await _openLeads();
          }),
        if (_isSeller) ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('YOUR PROPERTY WORKSPACE', style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          _drawerItem(Icons.grid_view_rounded, 'Dashboard', false, () async { Navigator.pop(context); await _openSellerWorkspace(); }),
          _drawerItem(Icons.apartment_outlined, 'Properties', false, () async { Navigator.pop(context); await _openSellerPage((repository) => SellerListingsPage(repository: repository)); }),
          Padding(padding: const EdgeInsets.fromLTRB(16, 5, 16, 10), child: SizedBox(width: double.infinity, height: 46, child: FilledButton.icon(onPressed: () async { Navigator.pop(context); await _openSellerPage((repository) => SellerListingFormPage(repository: repository)); }, icon: const Icon(Icons.add), label: const Text('Add a property')))),
          _drawerItem(Icons.calendar_month_outlined, 'Viewings', false, () async { Navigator.pop(context); await _openSellerPage((repository) => SellerBookingsPage(repository: repository)); }),
          _drawerItem(Icons.chat_bubble_outline, 'Property requests', false, () async { Navigator.pop(context); await _openSellerPage((repository) => SellerLeadsPage(repository: repository)); }),
          _drawerItem(Icons.show_chart_outlined, 'Reports', false, () => _comingSoon('Reports')),
          _drawerItem(Icons.notifications_none, 'Notifications', false, () async { Navigator.pop(context); await _openSellerPage((repository) => SellerNotificationsPage(repository: repository)); }),
          _drawerItem(Icons.settings_outlined, 'Account settings', false, _openProfile),
        ],
        if (_isBuyer)
          _drawerItem(Icons.notifications_none, context.tr('notifications'), false, () => _comingSoon(context.tr('notifications'))),
        const SizedBox(height: 24),
        Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF5F8F3), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.forum_outlined, color: Color(0xFF007A61)), const SizedBox(height: 10), Text(context.tr('supportTitle'), style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(context.tr('supportSubtitle'), style: const TextStyle(fontSize: 12, color: Colors.black54)), const SizedBox(height: 12), Text('${context.tr('contactSupport')}  ←', style: const TextStyle(fontSize: 12, color: Color(0xFF007A61), fontWeight: FontWeight.bold))])),
        const Spacer(),
      ],
    );
  }

  Widget _drawerItem(IconData icon, String label, bool selected, VoidCallback onTap, {bool isLogout = false}) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3), child: ListTile(onTap: onTap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tileColor: selected ? const Color(0xFF007A61) : null, leading: Icon(icon, color: selected ? Colors.white : (isLogout ? Colors.redAccent : const Color(0xFF708078))), title: Text(label, style: TextStyle(color: selected ? Colors.white : (isLogout ? Colors.redAccent : const Color(0xFF5C6A64)), fontWeight: selected ? FontWeight.bold : FontWeight.normal))));

  void _comingSoon(String name) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name ${context.tr('availableSoon')}')));
  }
}

class _Category extends StatelessWidget {
  const _Category({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
        width: 94,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFE7ECE9),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ));
}
