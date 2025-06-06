import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';
import '../../providers/search_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product/enhanced_product_card.dart';
import '../products/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  late FocusNode _searchFocusNode;
  Timer? _debounceTimer;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _searchFocusNode = FocusNode();
    
    // Initialize search provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().initialize();
    });

    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
    
    // Add focus listener for suggestions
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().loadMoreResults();
    }
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final provider = context.read<SearchProvider>();
      if (query.isNotEmpty) {
        provider.generateSuggestions(query);
        setState(() {
          _showSuggestions = true;
        });
      } else {
        provider.clearSearch();
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchProvider>().search(query);
      _searchFocusNode.unfocus();
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  Future<void> _navigateToProduct(Product product) async {
    try {
      final productProvider = context.read<ProductProvider>();
      await productProvider.addToRecentlyViewed(product);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final crossAxisCount = isSmallScreen ? 2 : (constraints.maxWidth < 900 ? 3 : 4);
        final childAspectRatio = isSmallScreen ? 0.68 : 0.70;

        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          body: SafeArea(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                return Column(
                  children: [
                    // Search Header
                    _buildSearchHeader(isSmallScreen, searchProvider),
                    
                    // Content Area
                    Expanded(
                      child: Stack(
                        children: [
                          // Main Content
                          _buildMainContent(searchProvider, crossAxisCount, childAspectRatio, isSmallScreen),
                          
                          // Search Suggestions Overlay
                          if (_showSuggestions)
                            _buildSuggestionsOverlay(searchProvider, isSmallScreen),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchHeader(bool isSmallScreen, SearchProvider searchProvider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 8 : 12,
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              height: isSmallScreen ? 44 : 48,
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _searchFocusNode.hasFocus 
                      ? AppConstants.accentColor 
                      : AppConstants.borderColor.withValues(alpha: 0.3),
                  width: _searchFocusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onSubmitted: _performSearch,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: AppConstants.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products, brands, categories...',
                  hintStyle: TextStyle(
                    color: AppConstants.textSecondary.withValues(alpha: 0.6),
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppConstants.textSecondary,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            searchProvider.clearSearch();
                            setState(() {
                              _showSuggestions = false;
                            });
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppConstants.textSecondary,
                            size: isSmallScreen ? 18 : 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: isSmallScreen ? 12 : 16),
          
          // Filter Button
          Container(
            height: isSmallScreen ? 44 : 48,
            width: isSmallScreen ? 44 : 48,
            decoration: BoxDecoration(
              color: searchProvider.hasActiveFilters 
                  ? AppConstants.accentColor 
                  : AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: searchProvider.hasActiveFilters 
                    ? AppConstants.accentColor 
                    : AppConstants.borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => _showFilterModal(searchProvider, isSmallScreen),
              icon: Icon(
                searchProvider.hasActiveFilters 
                    ? Icons.filter_alt 
                    : Icons.filter_alt_outlined,
                color: searchProvider.hasActiveFilters 
                    ? Colors.white 
                    : AppConstants.textSecondary,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(SearchProvider searchProvider, int crossAxisCount, double childAspectRatio, bool isSmallScreen) {
    if (searchProvider.isLoading) {
      return _buildLoadingState(isSmallScreen);
    }

    if (searchProvider.hasError) {
      return _buildErrorState(searchProvider.error!, isSmallScreen);
    }

    if (searchProvider.currentQuery.isEmpty) {
      return _buildEmptySearchState(searchProvider, isSmallScreen);
    }

    if (searchProvider.searchResults.isEmpty && !searchProvider.isSearching) {
      return _buildNoResultsState(isSmallScreen);
    }

    return _buildSearchResults(searchProvider, crossAxisCount, childAspectRatio, isSmallScreen);
  }

  Widget _buildEmptySearchState(SearchProvider searchProvider, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (searchProvider.hasSearchHistory) ...[
            _buildSectionHeader('Recent Searches', isSmallScreen, 
              actionText: 'Clear All',
              onActionTap: () => searchProvider.clearSearchHistory(),
            ),
            const SizedBox(height: 12),
            _buildSearchChips(searchProvider.searchHistory, isSmallScreen, isHistory: true),
            SizedBox(height: isSmallScreen ? 24 : 32),
          ] else if (searchProvider.isLoading) ...[
            // Show loading for search history
            _buildSectionHeader('Recent Searches', isSmallScreen),
            const SizedBox(height: 12),
            _buildLoadingChips(isSmallScreen),
            SizedBox(height: isSmallScreen ? 24 : 32),
          ],
          
          // Popular Searches
          _buildSectionHeader('Popular Searches', isSmallScreen),
          const SizedBox(height: 12),
          if (searchProvider.isLoading)
            _buildLoadingChips(isSmallScreen)
          else
            _buildSearchChips(searchProvider.popularSearches, isSmallScreen),
          SizedBox(height: isSmallScreen ? 24 : 32),
          
          // Quick Categories
          _buildSectionHeader('Shop by Category', isSmallScreen),
          const SizedBox(height: 12),
          if (searchProvider.isLoading)
            _buildLoadingCategories(isSmallScreen)
          else
            _buildQuickCategories(searchProvider, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isSmallScreen, {String? actionText, VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        if (actionText != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: AppConstants.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchChips(List<String> items, bool isSmallScreen, {bool isHistory = false}) {
    return Wrap(
      spacing: isSmallScreen ? 8 : 12,
      runSpacing: isSmallScreen ? 8 : 12,
      children: items.map((item) => GestureDetector(
        onTap: () => _selectSuggestion(item),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppConstants.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHistory ? Icons.history_rounded : Icons.trending_up_rounded,
                size: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                item,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isHistory) ...[
                SizedBox(width: isSmallScreen ? 6 : 8),
                GestureDetector(
                  onTap: () => context.read<SearchProvider>().removeFromSearchHistory(item),
                  child: Icon(
                    Icons.close_rounded,
                    size: isSmallScreen ? 14 : 16,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildQuickCategories(SearchProvider searchProvider, bool isSmallScreen) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        crossAxisSpacing: isSmallScreen ? 12 : 16,
        mainAxisSpacing: isSmallScreen ? 12 : 16,
        childAspectRatio: isSmallScreen ? 2.2 : 2.5,
      ),
      itemCount: searchProvider.categories.length.clamp(0, 6),
      itemBuilder: (context, index) {
        final category = searchProvider.categories[index];
        return GestureDetector(
          onTap: () => searchProvider.applyCategoryFilter(category.id),
          child: Container(
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.borderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_rounded,
                  size: isSmallScreen ? 24 : 28,
                  color: AppConstants.accentColor,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsOverlay(SearchProvider searchProvider, bool isSmallScreen) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        child: Container(
          color: AppConstants.surfaceColor,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: searchProvider.searchSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = searchProvider.searchSuggestions[index];
              return ListTile(
                leading: Icon(
                  Icons.search_rounded,
                  color: AppConstants.textSecondary,
                  size: isSmallScreen ? 18 : 20,
                ),
                title: Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: AppConstants.textPrimary,
                  ),
                ),
                onTap: () => _selectSuggestion(suggestion),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchProvider searchProvider, int crossAxisCount, double childAspectRatio, bool isSmallScreen) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Results Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${searchProvider.searchResults.length} results for "${searchProvider.currentQuery}"',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSortModal(searchProvider, isSmallScreen),
                  icon: Icon(
                    Icons.sort_rounded,
                    size: isSmallScreen ? 16 : 18,
                    color: AppConstants.accentColor,
                  ),
                  label: Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppConstants.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Products Grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isSmallScreen ? 12 : 16,
              mainAxisSpacing: isSmallScreen ? 16 : 20,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = searchProvider.searchResults[index];
                return EnhancedProductCard(
                  product: product,
                  isSmallScreen: isSmallScreen,
                  onTap: () => _navigateToProduct(product),
                );
              },
              childCount: searchProvider.searchResults.length,
            ),
          ),
        ),
        
        // Load More Indicator
        if (searchProvider.isLoadingMore)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppConstants.accentColor,
                ),
              ),
            ),
          ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.accentColor,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'Initializing search...',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: isSmallScreen ? 64 : 80,
              color: AppConstants.errorColor,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              error,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            ElevatedButton(
              onPressed: () => context.read<SearchProvider>().refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: isSmallScreen ? 64 : 80,
              color: AppConstants.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'Try different keywords or check your spelling',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.read<SearchProvider>().clearFilters(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 24,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  child: Text(
                    'Clear Filters',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<SearchProvider>().clearSearch();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppConstants.accentColor),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 24,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  child: Text(
                    'New Search',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: AppConstants.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSortModal(SearchProvider searchProvider, bool isSmallScreen) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            ...SearchSortOption.values.map((option) => ListTile(
              leading: Icon(
                _getSortIcon(option),
                color: searchProvider.sortOption == option 
                    ? AppConstants.accentColor 
                    : AppConstants.textSecondary,
                size: isSmallScreen ? 20 : 22,
              ),
              title: Text(
                _getSortLabel(option),
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: searchProvider.sortOption == option 
                      ? FontWeight.w600 
                      : FontWeight.w500,
                  color: searchProvider.sortOption == option 
                      ? AppConstants.accentColor 
                      : AppConstants.textPrimary,
                ),
              ),
              trailing: searchProvider.sortOption == option
                  ? Icon(
                      Icons.check_circle,
                      color: AppConstants.accentColor,
                      size: isSmallScreen ? 20 : 22,
                    )
                  : null,
              onTap: () {
                searchProvider.updateSortOption(option);
                Navigator.pop(context);
              },
            )),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(SearchProvider searchProvider, bool isSmallScreen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Consumer<SearchProvider>(
        builder: (context, provider, child) => Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title and Clear All
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Results',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.clearFilters(),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Filter Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories
                      _buildCategoryFilter(provider, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      
                      // Price Range
                      _buildPriceFilter(provider, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      
                      // Rating
                      _buildRatingFilter(provider, isSmallScreen),
                    ],
                  ),
                ),
              ),
              
              // Apply Button
              Container(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 16 : 20,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 16 : 20,
                  MediaQuery.of(context).padding.bottom + (isSmallScreen ? 12 : 16),
                ),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: AppConstants.borderColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 16 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(SearchProvider provider, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 22 : 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Category',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        Wrap(
          spacing: isSmallScreen ? 8 : 12,
          runSpacing: isSmallScreen ? 8 : 12,
          children: [
            // All Categories option
            GestureDetector(
              onTap: () => provider.applyCategoryFilter(null),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: provider.selectedCategoryId == null
                      ? AppConstants.accentColor
                      : AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppConstants.accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: provider.selectedCategoryId == null
                        ? Colors.white
                        : AppConstants.accentColor,
                  ),
                ),
              ),
            ),
            
            // Individual categories
            ...provider.categories.map((category) => GestureDetector(
              onTap: () => provider.applyCategoryFilter(category.id),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: provider.selectedCategoryId == category.id
                      ? AppConstants.accentColor
                      : AppConstants.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppConstants.accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: provider.selectedCategoryId == category.id
                        ? Colors.white
                        : AppConstants.accentColor,
                  ),
                ),
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceFilter(SearchProvider provider, bool isSmallScreen) {
    final minPrice = provider.getMinPrice();
    final maxPrice = provider.getMaxPrice();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_money_rounded,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 22 : 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Price Range',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Current selection display
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppConstants.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.minPriceFilter.toInt()} IQD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'to',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${provider.maxPriceFilter.toInt()} IQD',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: isSmallScreen ? 4 : 6,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: isSmallScreen ? 10 : 12,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: isSmallScreen ? 18 : 22,
            ),
            activeTrackColor: AppConstants.accentColor,
            inactiveTrackColor: AppConstants.borderColor.withValues(alpha: 0.3),
            thumbColor: AppConstants.accentColor,
            overlayColor: AppConstants.accentColor.withValues(alpha: 0.2),
          ),
          child: RangeSlider(
            values: RangeValues(
              provider.minPriceFilter.clamp(minPrice, maxPrice),
              provider.maxPriceFilter.clamp(minPrice, maxPrice),
            ),
            min: minPrice,
            max: maxPrice,
            divisions: 20,
            onChanged: (values) {
              provider.applyPriceFilter(values.start, values.end);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter(SearchProvider provider, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              color: AppConstants.accentColor,
              size: isSmallScreen ? 22 : 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Minimum Rating',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        Wrap(
          spacing: isSmallScreen ? 8 : 12,
          runSpacing: isSmallScreen ? 8 : 12,
          children: [
            _buildRatingButton(provider, 0, 'All', isSmallScreen),
            _buildRatingButton(provider, 1, '1+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 2, '2+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 3, '3+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 4, '4+ ⭐', isSmallScreen),
            _buildRatingButton(provider, 5, '5 ⭐', isSmallScreen),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingButton(SearchProvider provider, double rating, String label, bool isSmallScreen) {
    final isSelected = provider.minRatingFilter == rating;
    
    return GestureDetector(
      onTap: () => provider.applyRatingFilter(rating),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.accentColor
              : AppConstants.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
          border: Border.all(
            color: AppConstants.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 15,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppConstants.accentColor,
          ),
        ),
      ),
    );
  }

  String _getSortLabel(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.relevance:
        return 'Relevance';
      case SearchSortOption.newest:
        return 'Newest First';
      case SearchSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SearchSortOption.priceHighToLow:
        return 'Price: High to Low';
      case SearchSortOption.highestRated:
        return 'Highest Rated';
      case SearchSortOption.mostPopular:
        return 'Most Popular';
    }
  }

  IconData _getSortIcon(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.relevance:
        return Icons.star_outline_rounded;
      case SearchSortOption.newest:
        return Icons.fiber_new_rounded;
      case SearchSortOption.priceLowToHigh:
        return Icons.trending_up_rounded;
      case SearchSortOption.priceHighToLow:
        return Icons.trending_down_rounded;
      case SearchSortOption.highestRated:
        return Icons.star_rounded;
      case SearchSortOption.mostPopular:
        return Icons.local_fire_department_rounded;
    }
  }

  Widget _buildLoadingChips(bool isSmallScreen) {
    return Wrap(
      spacing: isSmallScreen ? 8 : 12,
      runSpacing: isSmallScreen ? 8 : 12,
      children: List.generate(6, (index) => Container(
        width: 80 + (index * 20),
        height: isSmallScreen ? 32 : 36,
        decoration: BoxDecoration(
          color: AppConstants.borderColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
      )),
    );
  }

  Widget _buildLoadingCategories(bool isSmallScreen) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        crossAxisSpacing: isSmallScreen ? 12 : 16,
        mainAxisSpacing: isSmallScreen ? 12 : 16,
        childAspectRatio: isSmallScreen ? 2.2 : 2.5,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.borderColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
} 
