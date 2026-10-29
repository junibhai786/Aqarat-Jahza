import 'package:aqarat_app/core/localization/app_localizations.dart';
import 'package:aqarat_app/core/errors/exceptions.dart';
import 'package:aqarat_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqarat_app/injection_container.dart';
import 'package:aqarat_app/features/properties/domain/entities/property.dart';
import 'package:aqarat_app/features/properties/presentation/bloc/property_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailsPage extends StatefulWidget {
  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
    required this.preview,
  });

  final int propertyId;
  final Property preview;

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  final _bookingNote = TextEditingController();
  final _imageController = PageController();
  DateTime? _appointment;
  int _selectedImage = 0;
  bool _showBookingForm = false;
  bool _sendingBooking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        context.read<PropertyBloc>().add(
          PropertyDetailsRequested(widget.propertyId),
        );
    });
  }

  @override
  void dispose() {
    _bookingNote.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PropertyBloc, PropertyState>(
        builder: (context, state) {
          final property = state.selectedProperty?.id == widget.propertyId
              ? state.selectedProperty!
              : widget.preview;
          if (state.isDetailLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.detailError != null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(state.detailError!)),
            );
          }
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('propertyDetails'))),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (property.badge.isNotEmpty)
                  Text(
                    property.badge,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  property.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 5),
                    Expanded(child: Text(_location(property))),
                  ],
                ),
                const SizedBox(height: 18),
                _image(property),
                const SizedBox(height: 16),
                _priceAndContact(property),
                const SizedBox(height: 16),
                _facts(property),
                const SizedBox(height: 16),
                _details(property),
                const SizedBox(height: 16),
                _locationCard(property),
                const SizedBox(height: 16),
                Text(
                  context.tr('description'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  property.description.isEmpty
                      ? context.tr('noDescription')
                      : property.description,
                ),
              ],
            ),
          );
        },
      );

  Widget _image(Property property) {
    if (property.images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 245,
          width: double.infinity,
          child: _placeholder(),
        ),
      );
    }
    final selected = _selectedImage >= property.images.length
        ? 0
        : _selectedImage;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 245,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _imageController,
                  itemCount: property.images.length,
                  onPageChanged: (index) =>
                      setState(() => _selectedImage = index),
                  itemBuilder: (_, index) => Image.network(
                    _imageUrl(property.images[index]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
                ),
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${selected + 1}/${property.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (property.images.length > 1)
                  Positioned.fill(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: selected == 0
                              ? null
                              : () => _imageController.previousPage(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black38,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: selected == property.images.length - 1
                              ? null
                              : () => _imageController.nextPage(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black38,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (property.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: property.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => InkWell(
                onTap: () {
                  _imageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  );
                  setState(() => _selectedImage = index);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: index == selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFE1E9E4),
                      width: index == selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    _imageUrl(property.images[index]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFFE8F5F0)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _priceAndContact(Property property) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _price(property),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE9F4EF),
              child: Icon(
                Icons.business_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.officeName.isEmpty
                        ? context.tr('directOwner')
                        : property.officeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    context.tr('propertyAdvertiser'),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (property.whatsapp.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openWhatsApp(property.whatsapp),
              icon: const Icon(Icons.chat_outlined),
              label: Text(context.tr('contactAdvertiser')),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showContact(property.whatsapp),
              icon: const Icon(Icons.phone_outlined),
              label: Text(context.tr('callAdvertiser')),
            ),
          ),
        ],
        if (context.read<AuthBloc>().state.user?.role == 'buyer') ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _showBookingForm = !_showBookingForm),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(context.tr('chooseViewingAppointment')),
            ),
          ),
          if (_showBookingForm) ...[
            const SizedBox(height: 14),
            _bookingForm(property),
          ],
        ],
      ],
    ),
  );

  Widget _bookingForm(Property property) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('preferredAppointment'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _pickAppointment,
        icon: const Icon(Icons.event_outlined),
        label: Text(
          _appointment == null
              ? context.tr('selectAppointment')
              : _dateLabel(_appointment!),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _bookingNote,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: context.tr('notesOptional'),
          hintText: context.tr('notesHint'),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _sendingBooking ? null : () => _sendBooking(property),
          child: _sendingBooking
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(context.tr('sendViewingRequest')),
        ),
      ),
    ],
  );

  Future<void> _pickAppointment() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _appointment ?? today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 183)),
      helpText: context.tr('selectAppointment'),
    );
    if (selected != null && mounted) setState(() => _appointment = selected);
  }

  Future<void> _sendBooking(Property property) async {
    if (_appointment == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('selectAppointment'))));
      return;
    }
    setState(() => _sendingBooking = true);
    try {
      final repository = await InjectionContainer.buyerRepository();
      await repository.createBooking(
        propertyId: property.id,
        requestedFor: _appointment!,
        message: _bookingNote.text.trim().isEmpty
            ? null
            : _bookingNote.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _showBookingForm = false;
        _appointment = null;
        _bookingNote.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('viewingRequestSent'))));
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _sendingBooking = false);
    }
  }

  Widget _facts(Property property) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Expanded(
          child: _fact(
            Icons.straighten,
            '${property.area ?? 0} ${context.tr('metersSquared')}',
            context.tr('area'),
          ),
        ),
        Expanded(
          child: _fact(
            Icons.bed_outlined,
            '${property.rooms ?? 0}',
            context.tr('bedrooms'),
          ),
        ),
        Expanded(
          child: _fact(
            Icons.bathtub_outlined,
            '${property.baths ?? 0}',
            context.tr('bathrooms'),
          ),
        ),
        Expanded(
          child: _fact(
            Icons.apartment_outlined,
            _specified(property.floorName),
            context.tr('floor'),
          ),
        ),
      ],
    ),
  );

  Widget _details(Property property) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('propertyInformation'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        _detailRow(context.tr('propertyType'), _typeLabel(property.type)),
        _detailRow(context.tr('finishing'), _specified(property.finishType)),
        _detailRow(
          context.tr('verification'),
          property.isVerified
              ? context.tr('verified')
              : context.tr('notVerified'),
        ),
        _detailRow(context.tr('listingNumber'), '#${property.id}'),
        _detailRow(context.tr('views'), '${property.views}'),
      ],
    ),
  );

  Widget _locationCard(Property property) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('location'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_location(property)),
        if (property.whatsapp.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${context.tr('contactNumber')}: ${property.whatsapp}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ],
    ),
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _fact(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, color: const Color(0xFF007A61)),
      const SizedBox(height: 8),
      Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      ),
    ],
  );

  Widget _placeholder() => Container(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: const Icon(Icons.home_work_rounded, size: 72),
  );
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE3EAE6)),
  );
  String _imageUrl(String path) =>
      path.startsWith('http') ? path : 'http://192.168.18.66:3000$path';
  String _location(Property p) =>
      p.address.isNotEmpty ? '${p.region} — ${p.address}' : p.region;
  String _specified(String value) =>
      value.isEmpty ? context.tr('notSpecified') : value;
  String _price(Property p) =>
      '${p.price} EGP${p.priceUnit == 'monthly' ? ' / ${context.tr('monthly')}' : ''}';
  String _typeLabel(String type) => type == 'rent'
      ? context.tr('forRent')
      : type == 'sale'
      ? context.tr('forSale')
      : type;
  String _dateLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  Future<void> _openWhatsApp(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final internationalNumber = digits.startsWith('0')
        ? '20${digits.substring(1)}'
        : digits.startsWith('+')
        ? digits.substring(1)
        : digits;
    final url = Uri.parse('https://wa.me/$internationalNumber');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) _showContact(number);
    } on PlatformException {
      if (mounted) _showContact(number);
    } catch (_) {
      if (mounted) _showContact(number);
    }
  }

  void _showContact(String number) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('contactNumber')}: $number')),
      );
}
