import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../pages/pagination_widget.dart';
import '../../domain/entities/hotel_entity.dart';
import '../../domain/usecases/search_hotels_usecase.dart';
import '../bloc/hotel_search_bloc.dart';
import '../bloc/hotel_search_event.dart';
import '../bloc/hotel_search_state.dart';
import '../pages/Wishlist_bloc.dart';
import '../widgets/image_preview_actions.dart';
import '../widgets/modify_booking_search_sheet.dart';
import 'hotel_room_page.dart';

/// Search results as [Sliver]s for [HomePage] — one scroll physics, no nested list lock-up.
class HotelSearchResultsSliverGroup extends StatefulWidget {
  final GlobalKey? anchorKey;

  const HotelSearchResultsSliverGroup({super.key, this.anchorKey});

  @override
  State<HotelSearchResultsSliverGroup> createState() =>
      _HotelSearchResultsSliverGroupState();
}

class _HotelSearchResultsSliverGroupState
    extends State<HotelSearchResultsSliverGroup> {
  final TextEditingController _searchCtrl = TextEditingController();

  SearchParams? _lastSearchParams;

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Recommended';

  int _currentPage = 1;
  static const int _perPage = 15;

  final _filterOptions = const [
    'All',
    '5 ★',
    '4 ★',
    '3 ★',
    '2 ★',
    'Budget',
    'Mid',
    'Luxury',
  ];
  final _sortOptions = const [
    'Recommended',
    'Price: Low to High',
    'Price: High to Low',
    'Rating: High to Low',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearchOnBlocReset() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _currentPage = 1;
      _selectedFilter = 'All';
      _selectedSort = 'Recommended';
    });
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
        case '2 ★':
          matchesCat = h.rating >= 2.0 && h.rating < 3.0;
          break;
        case 'Budget':
          matchesCat = h.bestPricePerNight > 0 && h.bestPricePerNight < 2000;
          break;
        case 'Mid':
          matchesCat =
              h.bestPricePerNight >= 2000 && h.bestPricePerNight <= 5000;
          break;
        case 'Luxury':
          matchesCat = h.bestPricePerNight > 5000;
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
    return BlocListener<HotelSearchBloc, HotelSearchState>(
      listenWhen: (prev, curr) =>
          (curr is HotelSearchInitial && prev is! HotelSearchInitial) ||
          (curr is HotelSearchLoaded && curr.searchParams != null),
      listener: (context, state) {
        if (state is HotelSearchInitial) {
          _clearSearchOnBlocReset();
          setState(() => _lastSearchParams = null);
        } else if (state is HotelSearchLoaded && state.searchParams != null) {
          setState(() => _lastSearchParams = state.searchParams);
        }
      },
      child: BlocBuilder<HotelSearchBloc, HotelSearchState>(
        builder: (context, state) {
          if (state is HotelSearchInitial) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          final chrome = widget.anchorKey != null
              ? KeyedSubtree(
                  key: widget.anchorKey,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: _buildResultsChrome(context, state),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: _buildResultsChrome(context, state),
                );
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: chrome),
              ..._buildBodySlivers(context, state),
            ],
          );
        },
      ),
    );
  }

  String? _fmtStayDate(String ymd) {
    if (ymd.isEmpty) return null;
    final d = DateTime.tryParse(ymd);
    if (d == null) return ymd;
    return DateFormat('dd MMM').format(d);
  }

  Widget _buildResultsChrome(BuildContext context, HotelSearchState state) {
    final params = state is HotelSearchLoaded ? state.searchParams : null;
    final effective = params ?? _lastSearchParams;
    final city = effective?.location ?? '';
    final checkInRaw = effective?.checkIn ?? '';
    final checkOutRaw = effective?.checkOut ?? '';
    final checkIn = _fmtStayDate(checkInRaw) ?? checkInRaw;
    final checkOut = _fmtStayDate(checkOutRaw) ?? checkOutRaw;
    final adults = effective?.adults ?? 0;
    final children = effective?.children ?? 0;
    final rooms = effective?.rooms ?? 1;
    final guestBits = <String>[
      '$adults adult${adults == 1 ? '' : 's'}',
      if (children > 0) '$children child${children == 1 ? '' : 'ren'}',
      '$rooms room${rooms == 1 ? '' : 's'}',
    ];
    final guestLine = guestBits.join(' · ');
    final hotelCount = state is HotelSearchLoaded ? state.totalCount : 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A6E), Color(0xFF1A4B8E), Color(0xFF2563EB)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A4B8E).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      city.isEmpty ? 'Search results' : city,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<HotelSearchBloc>().add(const ResetSearchEvent()),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      width: 34.w,
                      height: 34.h,
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
              ),
              if (city.isNotEmpty) ...[
                SizedBox(height: 10.h),
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
                          Flexible(
                            child: _pill(
                              Icons.people_rounded,
                              guestLine,
                            ),
                          ),
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
              ],
              if (effective != null) ...[
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        showModifyBookingSearchSheet(context, effective),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x66FFFFFF)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.12),
                    ),
                    icon: Icon(Icons.edit_calendar_outlined, size: 18.sp),
                    label: Text(
                      'Edit destination, dates & guests',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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

  List<Widget> _buildBodySlivers(BuildContext ctx, HotelSearchState state) {
    if (state is HotelSearchLoading) {
      return [
        SliverToBoxAdapter(child: _buildLoading()),
      ];
    }
    if (state is HotelSearchLoaded) {
      final filtered = _applyFiltersAndSort(state.hotels);
      return _buildListSlivers(ctx, filtered, state.searchParams);
    }
    if (state is HotelSearchEmpty) {
      return [SliverToBoxAdapter(child: _buildEmpty(ctx))];
    }
    if (state is HotelSearchError) {
      return [SliverToBoxAdapter(child: _buildError(ctx, state))];
    }
    return [SliverToBoxAdapter(child: _buildLoading())];
  }

  List<Widget> _buildListSlivers(
    BuildContext ctx,
    List<HotelEntity> all,
    dynamic searchParams,
  ) {
    if (all.isEmpty) {
      return [SliverToBoxAdapter(child: _buildNoResults())];
    }

    final totalPgs = _totalPages(all.length);
    if (_currentPage > totalPgs) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _currentPage = 1),
      );
    }
    final pageItems = _currentPageItems(all);
    final guests =
        (searchParams?.adults ?? 2) + (searchParams?.children ?? 0);

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildListHeader(all.length),
                );
              }
              if (i == pageItems.length + 1) {
                return Padding(
                  padding: EdgeInsets.only(top: 4.h, bottom: 20.h),
                  child: PaginationWidget(
                    currentPage: _currentPage,
                    totalPages: totalPgs,
                    onPageChanged: _onPageChanged,
                  ),
                );
              }
              final hotel = pageItems[i - 1];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: HotelSearchResultCard(
                  hotel: hotel,
                  checkIn: searchParams?.checkIn ?? '',
                  checkOut: searchParams?.checkOut ?? '',
                  guests: guests,
                  adults: searchParams?.adults ?? 2,
                  children: searchParams?.children ?? 0,
                  rooms: searchParams?.rooms ?? 1,
                  childAges: searchParams?.childAges,
                ),
              );
            },
            childCount: pageItems.length + 2,
          ),
        ),
      ),
    ];
  }

  Widget _buildListHeader(int total) {
    final totalPgs = _totalPages(total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your matches',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Page $_currentPage / $totalPgs',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A4B8E),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Text(
              '$total',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1D2E),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              ' properties',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              Expanded(
                child: Text(
                  ' · "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 10.h),
        Divider(height: 1, color: const Color(0xFFE2E8F0).withOpacity(0.9)),
      ],
    );
  }

  Widget _buildLoading() => Padding(
    padding: EdgeInsets.symmetric(vertical: 32.h),
    child: Center(
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
    ),
  );

  Widget _buildNoResults() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 18.w),
    child: Center(
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
    ),
  );

  Widget _buildEmpty(BuildContext ctx) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 18.w),
    child: Center(
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
              onPressed: () =>
                  ctx.read<HotelSearchBloc>().add(const ResetSearchEvent()),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Modify Search'),
            ),
          ),
        ],
      ),
    ),
    ),
  );

  Widget _buildError(BuildContext ctx, HotelSearchError state) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 18.w),
    child: Center(
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
              onPressed: () =>
                  ctx.read<HotelSearchBloc>().add(const ResetSearchEvent()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Dismiss'),
            ),
          ),
        ],
      ),
    ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hotel Card
// ─────────────────────────────────────────────────────────────────────────────
class HotelSearchResultCard extends StatelessWidget {
  final HotelEntity hotel;
  final String checkIn;
  final String checkOut;
  final int guests;
  final int adults;
  final int children;
  final int rooms;
  final List<int>? childAges;

  const HotelSearchResultCard({
    super.key,
    required this.hotel,
    this.checkIn = '',
    this.checkOut = '',
    this.guests = 2,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
    this.childAges,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = hotel.resolvedHotelGalleryUrls.isNotEmpty
        ? hotel.resolvedHotelGalleryUrls.first
        : hotel.frontImageUrl;
    final hasNetwork = imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

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
            adults: adults,
            children: children,
            rooms: rooms,
            childAges: childAges,
          ),
        ),
      ),
    );

    final loc = hotel.address.isNotEmpty ? hotel.address : hotel.city;

    Widget thumb() {
      if (hasNetwork) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ph(),
          loadingBuilder: (_, child, prog) => prog == null ? child : _shimmer(),
        );
      }
      if (imageUrl.isNotEmpty) {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ph(),
        );
      }
      return _ph();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: goToHotel,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE8ECF2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(11.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => openHotelImagePreview(context, hotel),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      width: 102.w,
                      height: 102.w,
                      child: thumb(),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hotel.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                height: 1.25,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFFDE68A).withOpacity(0.8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14.sp,
                                  color: const Color(0xFFD97706),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  hotel.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Icon(
                              Icons.place_outlined,
                              size: 15.sp,
                              color: const Color(0xFF1A4B8E).withOpacity(0.85),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              loc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                height: 1.35,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (hotel.availableRoomsCount > 0) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: hotel.availableRoomsCount <= 3
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 13.sp,
                                color: hotel.availableRoomsCount <= 3
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF15803D),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${hotel.availableRoomsCount} rooms left',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: hotel.availableRoomsCount <= 3
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 12.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₹${hotel.bestPricePerNight.toInt()}',
                                    style: TextStyle(
                                      fontSize: 19.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A4B8E),
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    ' / night',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A4B8E),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11.sp,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
