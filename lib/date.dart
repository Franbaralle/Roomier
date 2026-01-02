import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'routes.dart';
import 'auth_service.dart';

class DatePage extends StatefulWidget {
  @override
  _DatePageState createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  DateTime? selectedDate = DateTime.now();
  final DateTime currentDate = DateTime.now();
  String? warningMessage;

  Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _CustomDatePicker(
          initialDate: selectedDate ?? currentDate,
          firstDate: DateTime(currentDate.year - 100),
          lastDate: currentDate,
        );
      },
    );

    if (picked != null && picked != AuthService.getSelectedDate()) {
      setState(() {
        AuthService.setSelectedDate(picked);
        selectedDate = picked;
        _clearWarning();
      });
    }
  }

  bool isUnder18(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    DateTime minimumDate =
        DateTime(currentDate.year - 18, currentDate.month, currentDate.day);
    return birthDate.isAfter(minimumDate);
  }

  void _showWarning(String message) {
    setState(() {
      warningMessage = message;
    });
  }

  void _clearWarning() {
    setState(() {
      warningMessage = null;
    });
  }

  void _registerWithAuthService() async {
    if (selectedDate != null) {
      if (isUnder18(selectedDate!)) {
        _showWarning('Para continuar, debes ser de 18 años.');
      } else {
        try {
          AuthService.setSelectedDate(selectedDate!);
          Navigator.pushNamed(context, registerRoute);
        } catch (error) {
          print('Error durante la configuración de la fecha: $error');
        }
      }
    } else {
      _showWarning('Por favor, selecciona tu fecha de nacimiento.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fecha de Nacimiento'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cake_outlined,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 24),
              Text(
                '¿Cuál es tu fecha de nacimiento?',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Debes ser mayor de 18 años para continuar',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    await _selectDate(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha de nacimiento',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              selectedDate != null
                                  ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                  : 'Seleccionar fecha',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (warningMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warningMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _registerWithAuthService,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}

class _CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  _CustomDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<_CustomDatePicker> {
  late DateTime _currentDate;
  late DateTime _selectedDate;
  late int _selectedYear;
  bool _isYearSelection = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDate = widget.initialDate;
    _selectedYear = widget.initialDate.year;
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona tu fecha',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('d MMMM yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Calendar navigation
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: Color(0xFF6C63FF)),
                    onPressed: _previousMonth,
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isYearSelection = !_isYearSelection;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_currentDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(
                          _isYearSelection ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: Color(0xFF6C63FF),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: Color(0xFF6C63FF)),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),

            // Year selector or Calendar
            Container(
              height: 280,
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: _isYearSelection ? _buildYearSelector() : _buildCalendar(),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C63FF),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Aceptar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.lastDate.year - widget.firstDate.year + 1,
      itemBuilder: (context, index) {
        final year = widget.lastDate.year - index;
        final isSelected = year == _selectedYear;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedYear = year;
              _currentDate = DateTime(year, _currentDate.month, 1);
              _isYearSelection = false;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF6C63FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              year.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_currentDate.year, _currentDate.month, 1).weekday;
    final days = <Widget>[];

    // Week days header
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    for (var day in weekDays) {
      days.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Empty cells for days before month starts
    for (var i = 1; i < firstDayOfWeek; i++) {
      days.add(Container());
    }

    // Days of month
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      days.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedDate = date;
              _selectedYear = date.year;
            });
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF6C63FF) : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: Color(0xFF6C63FF), width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      children: days,
      physics: NeverScrollableScrollPhysics(),
    );
  }
}
