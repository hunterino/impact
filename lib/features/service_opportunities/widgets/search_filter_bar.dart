import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/project_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';

class SearchFilterBar extends StatefulWidget {
  final Function(String? query) onSearch;
  final Function({List<String>? causeAreas, DateTime? date}) onFilterChange;
  
  const SearchFilterBar({
    Key? key,
    required this.onSearch,
    required this.onFilterChange,
  }) : super(key: key);

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedCauseAreas = [];
  DateTime? _selectedDate;
  bool _isFilterVisible = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _toggleFilterVisibility() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }
  
  void _clearFilters() {
    setState(() {
      _selectedCauseAreas = [];
      _selectedDate = null;
    });
    widget.onFilterChange(causeAreas: null, date: null);
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onFilterChange(
        causeAreas: _selectedCauseAreas.isEmpty ? null : _selectedCauseAreas,
        date: picked,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearch(null);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDarkColor,
                  ),
                  onSubmitted: (value) {
                    widget.onSearch(value.isEmpty ? null : value);
                  },
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _toggleFilterVisibility,
                color: _isFilterVisible || _selectedCauseAreas.isNotEmpty || _selectedDate != null
                    ? AppTheme.primaryColor
                    : null,
              ),
            ],
          ),
        ),
        
        // Filter section
        if (_isFilterVisible)
          Consumer<ProjectProvider>(
            builder: (context, projectProvider, child) {
              final causeAreas = projectProvider.causeAreas;
              
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Cause Areas Filter
                    const Text(
                      'Cause Areas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Cause Areas Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: causeAreas.map((area) {
                        final isSelected = _selectedCauseAreas.contains(area);
                        return FilterChip(
                          label: Text(area),
                          selected: isSelected,
                          backgroundColor: Colors.grey[800],
                          selectedColor: AppTheme.primaryColor.withOpacity(0.7),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCauseAreas.add(area);
                              } else {
                                _selectedCauseAreas.remove(area);
                              }
                            });
                            widget.onFilterChange(
                              causeAreas: _selectedCauseAreas.isEmpty ? null : _selectedCauseAreas,
                              date: _selectedDate,
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Filter
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedDate != null
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedDate != null
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: _selectedDate != null
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate != null
                                  ? DateFormat.yMMMd().format(_selectedDate!)
                                  : 'Select Date',
                              style: TextStyle(
                                color: _selectedDate != null
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                              ),
                            ),
                            if (_selectedDate != null) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = null;
                                  });
                                  widget.onFilterChange(
                                    causeAreas: _selectedCauseAreas.isEmpty ? null : _selectedCauseAreas,
                                    date: null,
                                  );
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        
        // Active Filters Display
        if (!_isFilterVisible && (_selectedCauseAreas.isNotEmpty || _selectedDate != null))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Date filter chip
                if (_selectedDate != null)
                  Chip(
                    avatar: const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    label: Text(DateFormat.yMMMd().format(_selectedDate!)),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedDate = null;
                      });
                      widget.onFilterChange(
                        causeAreas: _selectedCauseAreas.isEmpty ? null : _selectedCauseAreas,
                        date: null,
                      );
                    },
                  ),
                  
                // Cause area filter chips
                ..._selectedCauseAreas.map((area) => Chip(
                  label: Text(area),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedCauseAreas.remove(area);
                    });
                    widget.onFilterChange(
                      causeAreas: _selectedCauseAreas.isEmpty ? null : _selectedCauseAreas,
                      date: _selectedDate,
                    );
                  },
                )),
              ],
            ),
          ),
      ],
    );
  }
}
