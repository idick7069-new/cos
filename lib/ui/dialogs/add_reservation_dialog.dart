import 'package:cos_connect/data/models/reservation.dart';
import 'package:flutter/material.dart';

class AddReservationDialog extends StatefulWidget {
  final Function(IdentityType identity, String character) onConfirm;

  const AddReservationDialog({required this.onConfirm});

  @override
  _AddReservationDialogState createState() => _AddReservationDialogState();
}

class _AddReservationDialogState extends State<AddReservationDialog> {
  IdentityType? _selectedIdentity;
  final TextEditingController _characterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('選擇身份並輸入角色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<IdentityType>(
            hint: Text('選擇身份'),
            value: _selectedIdentity,
            onChanged: (IdentityType? newValue) {
              setState(() {
                _selectedIdentity = newValue;
              });
            },
            items: IdentityType.values.map<DropdownMenuItem<IdentityType>>((IdentityType value) {
              return DropdownMenuItem<IdentityType>(
                value: value,
                child: Text(value.toString().split('.').last),
              );
            }).toList(),
          ),
          TextField(
            controller: _characterController,
            decoration: InputDecoration(labelText: '角色'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_selectedIdentity != null) {
              widget.onConfirm(_selectedIdentity!, _characterController.text);
              Navigator.of(context).pop();
            }
          },
          child: Text('確認'),
        ),
      ],
    );
  }
}