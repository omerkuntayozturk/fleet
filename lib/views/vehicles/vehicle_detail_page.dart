import 'package:fleet/services/vehicle_service.dart';
import 'package:flutter/material.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../models/vehicle.dart';

class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({super.key});
  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  late Vehicle v;
  final svc = VehicleService();
  final modelCtrl = TextEditingController();
  final plateCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    v = ModalRoute.of(context)!.settings.arguments as Vehicle;
    modelCtrl.text = v.model;
    plateCtrl.text = v.plate;
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: const TopBar(),
      drawer: const SideMenu(currentPage: 'detail'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildDetailForm(ctx),
      ),
    );
  }

  Widget _buildDetailForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(),
        const SizedBox(height: 24),
        _buildFormFields(),
        const SizedBox(height: 32),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        'Araç Detayları',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextField(
          controller: modelCtrl,
          decoration: const InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: plateCtrl,
          decoration: const InputDecoration(
            labelText: 'Plaka',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _saveVehicle,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _saveVehicle() {
    // Create a new Vehicle object instead of modifying the existing one
    final updatedVehicle = Vehicle(
      id: v.id,
      model: modelCtrl.text,
      plate: plateCtrl.text,
      year: v.year,
    );
    svc.update(updatedVehicle);
    Navigator.pop(context);
  }
}