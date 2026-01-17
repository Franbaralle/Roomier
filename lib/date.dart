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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Fecha de Nacimiento'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cake_outlined,
                  size: screenWidth * 0.16,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  '¿Cuál es tu fecha de nacimiento?',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'Debes ser mayor de 18 años para continuar',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.05),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await _selectDate(context);
                    },
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.025,
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
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                selectedDate != null
                                    ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                    : 'Seleccionar fecha',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).primaryColor,
                            size: screenWidth * 0.06,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (warningMessage != null) ...[
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[700],
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            warningMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: screenHeight * 0.05),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _registerWithAuthService,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.06),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: screenWidth * 0.1,
              offset: Offset(0, screenHeight * 0.025),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.06),
                  topRight: Radius.circular(screenWidth * 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona tu fecha',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    DateFormat('d MMMM yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Calendar navigation
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: Color(0xFF6C63FF),
                      size: screenWidth * 0.07,
                    ),
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
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(
                          _isYearSelection ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: Color(0xFF6C63FF),
                          size: screenWidth * 0.06,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: Color(0xFF6C63FF),
                      size: screenWidth * 0.07,
                    ),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),

            // Year selector or Calendar
            Container(
              height: screenHeight * 0.35,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
              child: _isYearSelection ? _buildYearSelector() : _buildCalendar(),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
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
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C63FF),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Aceptar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
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
    final screenWidth = MediaQuery.of(context).size.width;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
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
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF6C63FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Text(
              year.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    final screenWidth = MediaQuery.of(context).size.width;
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
              fontSize: screenWidth * 0.03,
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
          borderRadius: BorderRadius.circular(screenWidth * 0.125),
          child: Container(
            margin: EdgeInsets.all(screenWidth * 0.005),
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
                  fontSize: screenWidth * 0.0375,
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
