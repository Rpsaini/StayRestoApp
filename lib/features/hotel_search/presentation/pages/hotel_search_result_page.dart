import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../pages/pagination_widget.dart';
import '../../domain/entities/hotel_entity.dart';
import '../bloc/hotel_search_bloc.dart';
import '../bloc/hotel_search_state.dart';
import '../pages/Wishlist_bloc.dart';
import 'hotel_room_page.dart';

class HotelSearchResultPage extends StatefulWidget {
  const HotelSearchResultPage({super.key});

  @override
  State<HotelSearchResultPage> createState() => _HotelSearchResultPageState();
}

class _HotelSearchResultPageState extends State<HotelSearchResultPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Recommended';
  bool _showScrollTop = false;

  int _currentPage = 1;
  static const int _perPage = 15;

  final _filterOptions = const [
    'All',
    '5 ★',
    '4 ★',
    '3 ★',
    'Pool',
    'Spa',
    'Gym',
    'Parking',
  ];
  final _sortOptions = const [
    'Recommended',
    'Price: Low to High',
    'Price: High to Low',
    'Rating: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 200;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<HotelEntity> _applyFiltersAndSort(List<HotelEntity> hotels) {
    var filtered = hotels.where((h) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.city.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q);
      bool matchesCat = true;
      switch (_selectedFilter) {
        case '5 ★':
          matchesCat = h.rating >= 4.5;
          break;
        case '4 ★':
          matchesCat = h.rating >= 4.0 && h.rating < 4.5;
          break;
        case '3 ★':
          matchesCat = h.rating >= 3.0 && h.rating < 4.0;
          break;
        default:
          matchesCat = true;
      }
      return matchesQuery && matchesCat;
    }).toList();

    switch (_selectedSort) {
      case 'Price: Low to High':
        filtered.sort(
          (a, b) => a.bestPricePerNight.compareTo(b.bestPricePerNight),
        );
        break;
      case 'Price: High to Low':
        filtered.sort(
          (a, b) => b.bestPricePerNight.compareTo(a.bestPricePerNight),
        );
        break;
      case 'Rating: High to Low':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return filtered;
  }

  int _totalPages(int totalItems) => (totalItems / _perPage).ceil();

  List<HotelEntity> _currentPageItems(List<HotelEntity> all) {
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onFilterChanged(String val) => setState(() {
    _selectedFilter = val;
    _currentPage = 1;
  });
  void _onSortChanged(String val) => setState(() {
    _selectedSort = val;
    _currentPage = 1;
  });
  void _onSearchChanged(String val) => setState(() {
    _searchQuery = val;
    _currentPage = 1;
  });

  void _showSortSheet() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SortSheet(
      options: _sortOptions,
      selected: _selectedSort,
      onSelect: (v) {
        _onSortChanged(v);
        Navigator.pop(context);
      },
    ),
  );

  void _showFilterSheet() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(
      options: _filterOptions,
      selected: _selectedFilter,
      onSelect: (v) {
        _onFilterChanged(v);
        Navigator.pop(context);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      floatingActionButton: _showScrollTop
          ? FloatingActionButton.small(
              backgroundColor: const Color(0xFF1A4B8E),
              onPressed: () => _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
              ),
            )
          : null,
      body: BlocBuilder<HotelSearchBloc, HotelSearchState>(
        builder: (ctx, state) => NestedScrollView(
          controller: _scrollCtrl,
          headerSliverBuilder: (c, _) => [_buildAppBar(c, state)],
          body: _buildBody(ctx, state),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, HotelSearchState state) {
    final params = state is HotelSearchLoaded ? state.searchParams : null;
    final city = params?.cityName ?? '';
    final checkIn = params?.checkIn ?? '';
    final checkOut = params?.checkOut ?? '';
    final guests = (params?.adults ?? 0) + (params?.children ?? 0);
    final hotelCount = state is HotelSearchLoaded ? state.totalCount : 0;

    return SliverAppBar(
      expandedHeight: 230.h,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A4B8E),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: 16.sp,
            color: Colors.white,
          ),
        ),
      ),
      title: Text(
        city.isEmpty ? 'Search Results' : city,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _showSortSheet,
          child: Container(
            width: 34.w,
            height: 34.h,
            margin: EdgeInsets.only(top: 9.h, bottom: 9.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.swap_vert_rounded,
              size: 17.sp,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 6.w),
        GestureDetector(
          onTap: _showFilterSheet,
          child: Container(
            width: 34.w,
            height: 34.h,
            margin: EdgeInsets.only(top: 9.h, bottom: 9.h, right: 12.w),
            decoration: BoxDecoration(
              color: _selectedFilter != 'All'
                  ? Colors.white
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 17.sp,
              color: _selectedFilter != 'All'
                  ? const Color(0xFF1A4B8E)
                  : Colors.white,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3A6E), Color(0xFF1A4B8E), Color(0xFF2563EB)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 56.h, 14.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (city.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: _pill(
                                  Icons.calendar_today_rounded,
                                  '$checkIn → $checkOut',
                                ),
                              ),
                              SizedBox(width: 6.w),
                              _pill(Icons.people_rounded, '$guests guests'),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hotel_rounded,
                                size: 11.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$hotelCount found',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 10.h),
                  Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12.w),
                        Icon(
                          Icons.search_rounded,
                          size: 19.sp,
                          color: const Color(0xFF1A4B8E),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF1A1D2E),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search hotel by name or area...',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                            child: Padding(
                              padding: EdgeInsets.all(10.w),
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 17.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 12.w),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((f) {
                        final sel = _selectedFilter == f;
                        return GestureDetector(
                          onTap: () => _onFilterChanged(f),
                          child: Container(
                            margin: EdgeInsets.only(right: 6.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? const Color(0xFF1A4B8E)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _pill(IconData icon, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10.sp, color: Colors.white.withOpacity(0.9)),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );

  Widget _buildBody(BuildContext ctx, HotelSearchState state) {
    if (state is HotelSearchLoading) return _buildLoading();
    if (state is HotelSearchLoaded) {
      final filtered = _applyFiltersAndSort(state.hotels);
      // ✅ Pass dates from state to list builder
      return _buildList(ctx, filtered, state.searchParams);
    }
    if (state is HotelSearchEmpty) return _buildEmpty(ctx);
    if (state is HotelSearchError) return _buildError(ctx, state);
    return _buildLoading();
  }

  // ✅ FIXED: searchParams pass karo taaki dates HotelCard tak pahunche
  Widget _buildList(
    BuildContext ctx,
    List<HotelEntity> all,
    dynamic searchParams,
  ) {
    if (all.isEmpty) return _buildNoResults();

    final totalPgs = _totalPages(all.length);
    if (_currentPage > totalPgs) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _currentPage = 1),
      );
    }
    final pageItems = _currentPageItems(all);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      itemCount: pageItems.length + 2,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildListHeader(all.length);
        if (i == pageItems.length + 1) {
          return PaginationWidget(
            currentPage: _currentPage,
            totalPages: totalPgs,
            onPageChanged: _onPageChanged,
          );
        }
        final hotel = pageItems[i - 1];
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: _HotelCard(
            hotel: hotel,
            // ✅ KEY FIX: dates aur guests pass karo
            checkIn: searchParams?.checkIn ?? '',
            checkOut: searchParams?.checkOut ?? '',
            guests: (searchParams?.adults ?? 2) + (searchParams?.children ?? 0),
          ),
        );
      },
    );
  }

  Widget _buildListHeader(int total) {
    final totalPgs = _totalPages(total);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$total ',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1D2E),
                  ),
                ),
                TextSpan(
                  text: 'hotels',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Flexible(
              child: Text(
                ' for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Page $_currentPage of $totalPgs',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A4B8E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68.w,
          height: 68.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1A4B8E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1A4B8E),
              strokeWidth: 2.5,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Finding best hotels for you...',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'This may take a moment',
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9CA3AF)),
        ),
      ],
    ),
  );

  Widget _buildNoResults() => Center(
    child: Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 40.sp,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No results for "$_searchQuery"',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try a different name or clear the search',
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9CA3AF)),
          ),
          SizedBox(height: 20.h),
          TextButton.icon(
            onPressed: () {
              _searchCtrl.clear();
              _onSearchChanged('');
            },
            icon: const Icon(Icons.clear_rounded),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty(BuildContext ctx) => Center(
    child: Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88.w,
            height: 88.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Icon(
              Icons.hotel_rounded,
              size: 44.sp,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No Hotels Found',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "We couldn't find hotels matching your search.\nTry different dates or city.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9CA3AF)),
          ),
          SizedBox(height: 28.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B8E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Modify Search'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildError(BuildContext ctx, HotelSearchError state) => Center(
    child: Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88.w,
            height: 88.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Icon(
              state.isNetworkError
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: 44.sp,
              color: const Color(0xFFEF4444),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            state.isNetworkError
                ? 'No Internet Connection'
                : 'Something Went Wrong',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9CA3AF)),
          ),
          SizedBox(height: 28.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B8E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back & Retry'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hotel Card — ✅ FIXED: checkIn/checkOut/guests accept karo aur pass karo
// ─────────────────────────────────────────────────────────────────────────────
class _HotelCard extends StatelessWidget {
  final HotelEntity hotel;
  final String checkIn;
  final String checkOut;
  final int guests;

  const _HotelCard({
    required this.hotel,
    this.checkIn = '',
    this.checkOut = '',
    this.guests = 2,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = hotel.frontImageUrl;
    final hasNetwork = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    void goToHotel() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<WishlistBloc>(),
          child: HotelRoomPage(
            hotel: hotel,
            checkIn: checkIn,
            checkOut: checkOut,
            guests: guests,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: goToHotel,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A4B8E).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasNetwork
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(),
                            loadingBuilder: (_, child, prog) =>
                                prog == null ? child : _shimmer(),
                          )
                        : imageUrl.isNotEmpty
                        ? Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ph(),
                          )
                        : _ph(),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.52),
                          ],
                          stops: const [0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (hotel.availableRoomsCount > 0)
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: hotel.availableRoomsCount <= 3
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bed_rounded,
                              size: 10.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              '${hotel.availableRoomsCount} rooms',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12.sp,
                            color: const Color(0xFFFBBF24),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            hotel.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10.h,
                    left: 12.w,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${hotel.bestPricePerNight.toInt()}',
                          style: TextStyle(
                            fontSize: 21.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            '/night',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1D2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12.sp,
                          color: const Color(0xFF1A4B8E),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            hotel.address.isNotEmpty
                                ? hotel.address
                                : hotel.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(height: 1, color: const Color(0xFFF0F4F8)),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 42.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A4B8E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: goToHotel,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.arrow_forward_rounded, size: 15.sp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph() => Container(
    color: const Color(0xFFF1F5F9),
    child: Center(
      child: Icon(
        Icons.hotel_rounded,
        size: 48,
        color: const Color(0xFFCBD5E1),
      ),
    ),
  );
  Widget _shimmer() => Container(color: const Color(0xFFE2E8F0));
}

class _SortSheet extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _SortSheet({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Sort By',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 14.h),
          ...options.map((opt) {
            final sel = opt == selected;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF1A4B8E).withOpacity(0.06)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF1A4B8E).withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18.sp,
                      color: sel
                          ? const Color(0xFF1A4B8E)
                          : const Color(0xFF9CA3AF),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      opt,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel
                            ? const Color(0xFF1A4B8E)
                            : const Color(0xFF374151),
                      ),
                    ),
                    if (sel) ...[
                      const Spacer(),
                      Icon(
                        Icons.check_rounded,
                        size: 16.sp,
                        color: const Color(0xFF1A4B8E),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterSheet({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Filter Hotels',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1D2E),
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: options.map((opt) {
              final sel = opt == selected;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF1A4B8E)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF1A4B8E)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onSelect('All'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B8E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
