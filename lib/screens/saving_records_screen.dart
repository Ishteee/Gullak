import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class SavingRecordsScreen extends StatefulWidget {
  const SavingRecordsScreen({Key? key}) : super(key: key);

  @override
  _SavingRecordsScreenState createState() => _SavingRecordsScreenState();
}

class _SavingRecordsScreenState extends State<SavingRecordsScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  String? _selectedMemberId;
  String? _selectedType;
  String _sortDate = 'Newest First';
  String _sortAmount = 'None';
  DateTime? _selectedDate;

  Future<List<Widget>> _fetchSavingRecords(int groupId) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    debugPrint('Sorting: Amount=$_sortAmount, Date=$_sortDate, SelectedDate=$_selectedDate');
    var query = Supabase.instance.client
        .from('savings_entries')
        .select('id, member_id, amount, created_at, type, note')
        .eq('group_id', groupId);

    if (_selectedMemberId != null) {
      query = query.eq('member_id', _selectedMemberId!);
    }
    if (_selectedType != null && _selectedType != 'All') {
      query = query.eq('type', _selectedType!);
    }
    if (_selectedDate != null) {
      final localStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final localEnd = localStart.add(Duration(days: 1));
      final utcStart = localStart.toUtc();
      final utcEnd = localEnd.toUtc();
      query = query
          .gte('created_at', utcStart.toIso8601String())
          .lt('created_at', utcEnd.toIso8601String());
      debugPrint('Date filter (UTC): created_at BETWEEN ${utcStart.toIso8601String()} AND ${utcEnd.toIso8601String()}');
    }

    try {
      final response = await query.order('created_at', ascending: false);
      debugPrint('Supabase response: $response');
      final List<Map<String, dynamic>> records = response.map((record) {
        debugPrint('Record created_at: ${record['created_at']}');
        return Map<String, dynamic>.from(record);
      }).toList();

      for (var record in records) {
        final memberResponse = await Supabase.instance.client
            .from('members')
            .select('name')
            .eq('id', record['member_id'])
            .single();
        record['member_name'] = memberResponse['name'] as String;
      }

      records.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at']) ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['created_at']) ?? DateTime(1970);
        final amountA = a['amount'] as num;
        final amountB = b['amount'] as num;

        if (_sortAmount == 'None') {
          return _sortDate == 'Oldest First' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        } else {
          int amountCompare = _sortAmount == 'Highest First' ? amountB.compareTo(amountA) : amountA.compareTo(amountB);
          if (amountCompare != 0) return amountCompare;
          return _sortDate == 'Oldest First' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        }
      });

      final List<Widget> widgets = [];
      int widgetIndex = 0;

      if (_sortAmount == 'Highest First' || _sortAmount == 'Lowest First') {
        for (var record in records) {
          final isDeposit = record['type'] == 'Deposit';
          widgets.add(
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
              child: GestureDetector(
                onTap: () => _showEditRecordDialog(groupId, record),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                      border: Border.all(color: Color(0xFFFFD700), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: screenWidth * 0.03,
                          spreadRadius: screenWidth * 0.008,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(
                                    isDeposit ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isDeposit ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Flexible(
                                    child: Text(
                                      record['member_name'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: math.min(screenWidth * 0.045, 18),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                isDeposit
                                    ? '₹${(record['amount'] as num).toStringAsFixed(0)}'
                                    : '-₹${(record['amount'] as num).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isDeposit ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                  fontSize: math.min(screenWidth * 0.045, 18),
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(record['created_at']),
                              style: TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: math.min(screenWidth * 0.035, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatTime(record['created_at']),
                              style: TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: math.min(screenWidth * 0.035, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (!isDeposit && record['note'] != null && record['note'].toString().isNotEmpty) ...[
                          SizedBox(height: screenHeight * 0.015),
                          Text(
                            'Note: ${record['note']}',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: math.min(screenWidth * 0.035, 14),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 1000.ms, delay: (widgetIndex * 150).ms).slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 1000.ms,
                      curve: Curves.easeOut,
                      delay: (widgetIndex * 150).ms,
                    ),
              ),
            ),
          );
          widgetIndex++;
        }
      } else {
        final Map<String, List<Map<String, dynamic>>> groupedRecords = {};
        if (_selectedDate != null && records.isNotEmpty) {
          final date = _formatDate(records.first['created_at']);
          groupedRecords[date] = records;
        } else {
          for (var record in records) {
            final date = _formatDate(record['created_at']);
            if (!groupedRecords.containsKey(date)) {
              groupedRecords[date] = [];
            }
            groupedRecords[date]!.add(record);
          }
        }

        final sortedDates = groupedRecords.keys.toList()
          ..sort((a, b) {
            final dateA = DateFormat('dd/MM/yyyy').parse(a);
            final dateB = DateFormat('dd/MM/yyyy').parse(b);
            return _sortDate == 'Oldest First' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
          });

        for (var date in sortedDates) {
          debugPrint('Banner: $date - ${DateFormat('EEEE').format(DateFormat('dd/MM/yyyy').parse(date))}');
          widgets.add(
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFFFFD700)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    border: Border.all(color: Color(0xFFFFD700), width: 1),
                  ),
                  child: Text(
                    '$date - ${DateFormat('EEEE').format(DateFormat('dd/MM/yyyy').parse(date))}',
                    style: TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: math.min(screenWidth * 0.045, 18),
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ).animate().fadeIn(duration: 1000.ms, delay: (widgetIndex * 150).ms).slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 1000.ms,
                    curve: Curves.easeOut,
                    delay: (widgetIndex * 150).ms,
                  ),
            ),
          );
          widgetIndex++;

          for (var record in groupedRecords[date]!) {
            final isDeposit = record['type'] == 'Deposit';
            widgets.add(
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
                child: GestureDetector(
                  onTap: () => _showEditRecordDialog(groupId, record),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.035),
                        border: Border.all(color: Color(0xFFFFD700), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: screenWidth * 0.03,
                            spreadRadius: screenWidth * 0.008,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Icon(
                                      isDeposit ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isDeposit ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                      size: screenWidth * 0.06,
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Flexible(
                                      child: Text(
                                        record['member_name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: math.min(screenWidth * 0.045, 18),
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  isDeposit
                                      ? '₹${(record['amount'] as num).toStringAsFixed(0)}'
                                      : '-₹${(record['amount'] as num).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isDeposit ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                    fontSize: math.min(screenWidth * 0.045, 18),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(record['created_at']),
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: math.min(screenWidth * 0.035, 14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatTime(record['created_at']),
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: math.min(screenWidth * 0.035, 14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (!isDeposit && record['note'] != null && record['note'].toString().isNotEmpty) ...[
                            SizedBox(height: screenHeight * 0.015),
                            Text(
                              'Note: ${record['note']}',
                              style: TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: math.min(screenWidth * 0.035, 14),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 1000.ms, delay: (widgetIndex * 150).ms).slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 1000.ms,
                        curve: Curves.easeOut,
                        delay: (widgetIndex * 150).ms,
                      ),
                ),
              ),
            );
            widgetIndex++;
          }
        }
      }

      return widgets;
    } catch (e) {
      debugPrint('Supabase query error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMembers(int groupId) async {
    try {
      final response = await Supabase.instance.client
          .from('members')
          .select('id, name')
          .eq('group_id', groupId);
      final members = response.map((m) => Map<String, dynamic>.from(m)).toList();
      debugPrint('Fetched members: $members');
      return members;
    } catch (e) {
      debugPrint('Error fetching members: $e');
      return [];
    }
  }

  String _formatDate(String createdAt) {
    final dateTime = DateTime.parse(createdAt).toLocal();
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String _formatTime(String createdAt) {
    final dateTime = DateTime.parse(createdAt).toLocal();
    return DateFormat('hh:mm a').format(dateTime);
  }

  void _showEditRecordDialog(int groupId, Map<String, dynamic> record) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          initialIndex: record['type'] == 'Deposit' ? 0 : 1,
          length: 2,
          child: Dialog(
            backgroundColor: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: screenWidth * 0.85,
              ),
              child: _EditRecordDialogContent(
                groupId: groupId,
                record: record,
                refreshCallback: () => setState(() {}),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog(int groupId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    String? tempMemberId = _selectedMemberId;
    String? tempType = _selectedType;
    String tempSortDate = _sortDate;
    String tempSortAmount = _sortAmount;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
              title: Text(
                'Filter Records',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w700,
                  fontSize: math.min(screenWidth * 0.05, 20),
                ),
              ),
              content: SingleChildScrollView(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchMembers(groupId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SpinKitCubeGrid(
                          color: Color(0xFFFFD700),
                          size: screenWidth * 0.125,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      debugPrint('Member fetch error: ${snapshot.error}');
                      return Text(
                        'Error loading members',
                        style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: math.min(screenWidth * 0.04, 16),
                        ),
                      );
                    }
                    final members = snapshot.data ?? [];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: tempMemberId,
                          decoration: InputDecoration(
                            labelText: 'Member',
                            labelStyle: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: math.min(screenWidth * 0.04, 16),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0B0B45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: math.min(screenWidth * 0.04, 16),
                          ),
                          dropdownColor: const Color(0xFF0B0B45),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'All Members',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                            ...members.map((member) {
                              return DropdownMenuItem<String>(
                                value: member['id'].toString(),
                                child: Text(
                                  member['name'],
                                  style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              tempMemberId = value;
                            });
                          },
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        DropdownButtonFormField<String>(
                          value: tempType ?? 'All',
                          decoration: InputDecoration(
                            labelText: 'Type',
                            labelStyle: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: math.min(screenWidth * 0.04, 16),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0B0B45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: math.min(screenWidth * 0.04, 16),
                          ),
                          dropdownColor: const Color(0xFF0B0B45),
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                'All Types',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Deposit',
                              child: Text(
                                'Deposit',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Withdrawal',
                              child: Text(
                                'Withdrawal',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              tempType = value;
                            });
                          },
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        DropdownButtonFormField<String>(
                          value: tempSortDate,
                          decoration: InputDecoration(
                            labelText: 'Sort by Date',
                            labelStyle: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: math.min(screenWidth * 0.04, 16),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0B0B45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: math.min(screenWidth * 0.04, 16),
                          ),
                          dropdownColor: const Color(0xFF0B0B45),
                          items: [
                            DropdownMenuItem(
                              value: 'Newest First',
                              child: Text(
                                'Newest First',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Oldest First',
                              child: Text(
                                'Oldest First',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              tempSortDate = value!;
                            });
                          },
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        DropdownButtonFormField<String>(
                          value: tempSortAmount,
                          decoration: InputDecoration(
                            labelText: 'Sort by Amount',
                            labelStyle: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: math.min(screenWidth * 0.04, 16),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0B0B45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: math.min(screenWidth * 0.04, 16),
                          ),
                          dropdownColor: const Color(0xFF0B0B45),
                          items: [
                            DropdownMenuItem(
                              value: 'None',
                              child: Text(
                                'No Sorting',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Highest First',
                              child: Text(
                                'Highest First',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Lowest First',
                              child: Text(
                                'Lowest First',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              tempSortAmount = value!;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempMemberId = null;
                      tempType = null;
                      tempSortDate = 'Newest First';
                      tempSortAmount = 'None';
                      _selectedDate = null;
                    });
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: math.min(screenWidth * 0.04, 16),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: math.min(screenWidth * 0.04, 16),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0B0B45),
                    foregroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedMemberId = tempMemberId;
                      _selectedType = tempType == 'All' ? null : tempType;
                      _sortDate = tempSortDate;
                      _sortAmount = tempSortAmount;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Apply',
                    style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                  ),
                ).animate().scale(
                      duration: 400.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(0.95, 0.95),
                      curve: Curves.easeInOut,
                    ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                );
          },
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              onPrimary: Color(0xFF0B0B45),
              surface: Color(0xFF1A237E),
              onSurface: Color(0xFFE0E0E0),
            ),
            dialogBackgroundColor: const Color(0xFF0B0B45),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && (picked.year != _selectedDate?.year || picked.month != _selectedDate?.month || picked.day != _selectedDate?.day)) {
      setState(() {
        _selectedDate = DateTime.utc(picked.year, picked.month, picked.day);
        debugPrint('Selected date: $_selectedDate');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final groupId = args['groupId'] as int;
    final groupName = args['groupName'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B45),
      body: Stack(
        children: [
          ...List.generate(12, (index) {
            return Positioned(
              left: math.Random().nextDouble() * screenWidth,
              top: math.Random().nextDouble() * screenHeight,
              child: AnimatedOpacity(
                opacity: math.Random().nextDouble() * 0.5 + 0.3,
                duration: Duration(milliseconds: 2000 + index * 300),
                child: Container(
                  width: math.max(screenWidth * 0.008, 4),
                  height: math.max(screenWidth * 0.008, 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
          RefreshIndicator(
            key: _refreshIndicatorKey,
            color: const Color(0xFFFFD700),
            backgroundColor: const Color(0xFF0B0B45),
            onRefresh: () async {
              setState(() {});
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF0B0B45),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          groupName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFFFD700),
                            fontSize: math.min(screenWidth * 0.045, 18),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFD700).withOpacity(0.6),
                                blurRadius: screenWidth * 0.03,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ).animate().fadeIn(duration: 600.ms),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          'Records',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFFFD700),
                            fontSize: math.min(screenWidth * 0.075, 30),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFD700).withOpacity(0.6),
                                blurRadius: screenWidth * 0.03,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms),
                      ],
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B0B45), Color(0xFF1A237E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  expandedHeight: screenHeight * 0.18,
                  floating: true,
                  pinned: true,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFFD700),
                      size: screenWidth * 0.07,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Saving Records',
                            style: TextStyle(
                              color: const Color(0xFFFFD700),
                              fontSize: math.min(screenWidth * 0.06, 24),
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.6),
                                  blurRadius: screenWidth * 0.03,
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: Color(0xFFFFD700),
                                size: screenWidth * 0.06,
                              ),
                              onPressed: _selectDate,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color: Color(0xFFFFD700),
                                size: screenWidth * 0.06,
                              ),
                              onPressed: () => _showFilterDialog(groupId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1000.ms),
                ),
                FutureBuilder<List<Widget>>(
                  future: _fetchSavingRecords(groupId),
                  key: ValueKey('$_selectedMemberId-$_selectedType-$_sortDate-$_sortAmount-$_selectedDate'),
                  builder: (context, AsyncSnapshot<List<Widget>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: screenHeight * 0.5,
                          child: Center(
                            child: SpinKitCubeGrid(
                              color: Color(0xFFFFD700),
                              size: screenWidth * 0.125,
                            ),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      debugPrint('Fetch error: ${snapshot.error}');
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: screenHeight * 0.5,
                          child: Center(
                            child: Text(
                              'Error loading saving records: ${snapshot.error}',
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontSize: math.min(screenWidth * 0.045, 18),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }
                    final widgets = snapshot.data ?? [];
                    if (widgets.isEmpty) {
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: screenHeight * 0.5,
                          child: Center(
                            child: Text(
                              'No saving records found.',
                              style: TextStyle(
                                color: const Color(0xFFFFD700),
                                fontSize: math.min(screenWidth * 0.045, 18),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildListDelegate([
                        ...widgets,
                        SizedBox(height: screenHeight * 0.12),
                      ]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRecordDialogContent extends StatefulWidget {
  final int groupId;
  final Map<String, dynamic> record;
  final VoidCallback refreshCallback;

  const _EditRecordDialogContent({
    required this.groupId,
    required this.record,
    required this.refreshCallback,
  });

  @override
  _EditRecordDialogContentState createState() => _EditRecordDialogContentState();
}

class _EditRecordDialogContentState extends State<_EditRecordDialogContent> {
  String? _selectedMemberId;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _dateTimeController = TextEditingController();
  DateTime? _selectedDateTime;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.record['member_id'].toString();
    _amountController.text = (widget.record['amount'] as num).toString();
    _reasonController.text = widget.record['note']?.toString() ?? '';
    _selectedDateTime = DateTime.parse(widget.record['created_at']).toLocal();
    _dateTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime!);
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final response = await Supabase.instance.client
          .from('members')
          .select('id, name')
          .eq('group_id', widget.groupId);
      final members = response.map((m) => Map<String, dynamic>.from(m)).toList();
      setState(() {
        _members = members;
        _isLoading = false;
        debugPrint('Fetched members: $members');
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading members: $e';
        debugPrint('Error fetching members: $e');
      });
    }
  }

  Future<void> _pickDateTime() async {
    final screenWidth = MediaQuery.of(context).size.width;
    debugPrint("Date picker opened");
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              onPrimary: Color(0xFF0B0B45),
              surface: Color(0xFF1A237E),
              onSurface: Color(0xFFE0E0E0),
            ),
            dialogBackgroundColor: const Color(0xFF0B0B45),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      debugPrint("Picked date: $pickedDate");
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFFD700),
                onPrimary: Color(0xFF0B0B45),
                surface: Color(0xFF1A237E),
                onSurface: Color(0xFFE0E0E0),
              ),
              dialogBackgroundColor: const Color(0xFF0B0B45),
              textTheme: TextTheme(
                bodyMedium: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final selected = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        debugPrint("Picked full DateTime: $selected");
        setState(() {
          _selectedDateTime = selected;
          _dateTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(selected);
          debugPrint("Updated _selectedDateTime: $_selectedDateTime");
        });
      } else {
        debugPrint("Time not selected");
      }
    } else {
      debugPrint("Date not selected");
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return SizedBox(
        height: screenHeight * 0.3,
        child: Center(
          child: SpinKitCubeGrid(
            color: Color(0xFFFFD700),
            size: screenWidth * 0.125,
          ),
        ),
      );
    }
    if (_errorMessage != null) {
      return SizedBox(
        height: screenHeight * 0.3,
        child: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: math.min(screenWidth * 0.04, 16),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.06, screenHeight * 0.025, screenWidth * 0.06, 0),
            child: Text(
              'Edit Record',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w700,
                fontSize: math.min(screenWidth * 0.05, 20),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(screenWidth * 0.06, screenHeight * 0.02, screenWidth * 0.06, screenHeight * 0.02),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      labelColor: const Color(0xFFFFD700),
                      unselectedLabelColor: const Color(0xFFE0E0E0),
                      labelStyle: TextStyle(
                        fontSize: math.min(screenWidth * 0.04, 16),
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: math.min(screenWidth * 0.04, 16),
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorColor: const Color(0xFFFFD700),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Deposit'),
                        Tab(text: 'Withdrawal'),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight * 0.3,
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: TabBarView(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedMemberId,
                                decoration: InputDecoration(
                                  labelText: 'Member',
                                  labelStyle: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.04, 16),
                                ),
                                dropdownColor: const Color(0xFF0B0B45),
                                items: _members.map((member) {
                                  return DropdownMenuItem<String>(
                                    value: member['id'].toString(),
                                    child: Text(
                                      member['name'],
                                      style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMemberId = value;
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              TextField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  labelText: 'Amount (₹)',
                                  labelStyle: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.04, 16),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              TextField(
                                readOnly: true,
                                controller: _dateTimeController,
                                decoration: InputDecoration(
                                  labelText: 'Date & Time',
                                  labelStyle: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFFFFD700),
                                    size: screenWidth * 0.06,
                                  ),
                                  hintText: 'Select Date & Time',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFE0E0E0).withOpacity(0.7),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.04, 16),
                                ),
                                onTap: _pickDateTime,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedMemberId,
                                decoration: InputDecoration(
                                  labelText: 'Member',
                                  labelStyle: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.04, 16),
                                ),
                                dropdownColor: const Color(0xFF0B0B45),
                                items: _members.map((member) {
                                  return DropdownMenuItem<String>(
                                    value: member['id'].toString(),
                                    child: Text(
                                      member['name'],
                                      style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMemberId = value;
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              TextField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  labelText: 'Amount (₹)',
                                  labelStyle: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.04, 16),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              TextField(
                                readOnly: true,
                                controller: _dateTimeController,
                                decoration: InputDecoration(
                                  labelText: 'Date & Time',
                                  labelStyle: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFFFFD700),
                                    size: screenWidth * 0.06,
                                  ),
                                  hintText: 'Select Date & Time',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFE0E0E0).withOpacity(0.7),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.04, 16),
                                ),
                                onTap: _pickDateTime,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              TextField(
                                controller: _reasonController,
                                decoration: InputDecoration(
                                  labelText: 'Reason for Withdrawal',
                                  labelStyle: TextStyle(
                                    color: Color(0xFFE0E0E0),
                                    fontSize: math.min(screenWidth * 0.04, 16),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0B0B45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.04, 16),
                                ),
                                maxLines: 2,
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
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.06, screenHeight * 0.01, screenWidth * 0.06, screenHeight * 0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        try {
                          final originalMemberId = widget.record['member_id'].toString();
                          final originalAmount = widget.record['amount'] as num;
                          final originalType = widget.record['type'] as String;
                          final originalSavings = await Supabase.instance.client
                              .from('members')
                              .select('total_savings')
                              .eq('id', originalMemberId)
                              .single()
                              .then((res) => res['total_savings'] as num);

                          final newSavings = originalType == 'Deposit'
                              ? originalSavings - originalAmount
                              : originalSavings + originalAmount;
                          await Supabase.instance.client
                              .from('members')
                              .update({'total_savings': newSavings})
                              .eq('id', originalMemberId);

                          await Supabase.instance.client
                              .from('savings_entries')
                              .delete()
                              .eq('id', widget.record['id']);

                          Navigator.pop(context);
                          widget.refreshCallback();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Record deleted successfully!',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                              backgroundColor: Color(0xFF0B0B45),
                            ),
                          );
                        } catch (e) {
                          debugPrint('Delete record error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to delete record.',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                              backgroundColor: Color(0xFF0B0B45),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFF44336),
                          fontSize: math.min(screenWidth * 0.04, 16),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: math.min(screenWidth * 0.04, 16),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0B0B45),
                    foregroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                  ),
                  onPressed: () async {
                    if (_selectedMemberId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select a member.',
                            style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                          ),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    final isDeposit = DefaultTabController.of(context)!.index == 0;
                    final amount = double.tryParse(_amountController.text);

                    if (_amountController.text.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a valid amount.',
                            style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                          ),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    if (!isDeposit && _reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a reason for withdrawal.',
                            style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                          ),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                      return;
                    }

                    try {
                      final originalMemberId = widget.record['member_id'].toString();
                      final newMemberId = _selectedMemberId!;
                      final originalAmount = widget.record['amount'] as num;
                      final originalType = widget.record['type'] as String;

                      final originalSavings = await Supabase.instance.client
                          .from('members')
                          .select('total_savings')
                          .eq('id', originalMemberId)
                          .single()
                          .then((res) => res['total_savings'] as num);

                      final newSavings = originalMemberId == newMemberId
                          ? originalSavings
                          : await Supabase.instance.client
                              .from('members')
                              .select('total_savings')
                              .eq('id', newMemberId)
                              .single()
                              .then((res) => res['total_savings'] as num);

                      if (!isDeposit) {
                        final memberSavings = originalMemberId == newMemberId ? originalSavings : newSavings;
                        final effectiveSavings = originalType == 'Deposit'
                            ? memberSavings - originalAmount
                            : memberSavings + originalAmount;
                        if (amount > effectiveSavings) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Withdrawal amount exceeds member savings.',
                                style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                              ),
                              backgroundColor: Color(0xFF0B0B45),
                            ),
                          );
                          return;
                        }
                      }

                      if (originalMemberId == newMemberId) {
                        final reverseOriginal = originalType == 'Deposit' ? -originalAmount : originalAmount;
                        final applyNew = isDeposit ? amount : -amount;
                        final newTotalSavings = originalSavings + reverseOriginal + applyNew;
                        debugPrint(
                            'Same member: originalSavings=$originalSavings, reverseOriginal=$reverseOriginal, applyNew=$applyNew, newTotalSavings=$newTotalSavings');
                        await Supabase.instance.client
                            .from('members')
                            .update({'total_savings': newTotalSavings})
                            .eq('id', newMemberId);
                      } else {
                        final originalMemberNewSavings = originalType == 'Deposit'
                            ? originalSavings - originalAmount
                            : originalSavings + originalAmount;
                        final newMemberNewSavings = isDeposit ? newSavings + amount : newSavings - amount;
                        debugPrint(
                            'Different members: originalMemberNewSavings=$originalMemberNewSavings, newMemberNewSavings=$newMemberNewSavings');
                        await Supabase.instance.client
                            .from('members')
                            .update({'total_savings': originalMemberNewSavings})
                            .eq('id', originalMemberId);
                        await Supabase.instance.client
                            .from('members')
                            .update({'total_savings': newMemberNewSavings})
                            .eq('id', newMemberId);
                      }

                      final updatedEntry = {
                        'group_id': widget.groupId,
                        'member_id': _selectedMemberId,
                        'amount': amount,
                        'type': isDeposit ? 'Deposit' : 'Withdrawal',
                        'note': isDeposit ? null : _reasonController.text.trim(),
                      };

                      debugPrint('Selected DateTime before update: $_selectedDateTime');
                      if (_selectedDateTime != null) {
                        final utcDateTime = _selectedDateTime!.toUtc();
                        updatedEntry['created_at'] = utcDateTime.toIso8601String();
                        debugPrint('Updated created_at: ${updatedEntry['created_at']}');
                      }

                      await Supabase.instance.client
                          .from('savings_entries')
                          .update(updatedEntry)
                          .eq('id', widget.record['id']);

                      _amountController.clear();
                      _reasonController.clear();
                      _dateTimeController.clear();
                      _selectedMemberId = null;
                      _selectedDateTime = null;

                      Navigator.pop(context);
                      widget.refreshCallback();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Record updated successfully!',
                            style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                          ),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Update record error: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update record.',
                            style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                          ),
                          backgroundColor: Color(0xFF0B0B45),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Update',
                    style: TextStyle(fontSize: math.min(screenWidth * 0.04, 16)),
                  ),
                ).animate().scale(
                      duration: 400.ms,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(0.95, 0.95),
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(
            begin: 0.2,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}