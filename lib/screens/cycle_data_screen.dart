import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';

class CycleDataScreen extends StatefulWidget {
  const CycleDataScreen({super.key});

  @override
  State<CycleDataScreen> createState() => _CycleDataScreenState();
}

class _CycleDataScreenState extends State<CycleDataScreen> {
  DateTime? _pickedDate;
  late TextEditingController _cycleLengthController;
  late TextEditingController _periodDurationController;

  @override
  void initState() {
    super.initState();
    final cycle = context.read<CycleProvider>();
    _pickedDate = cycle.cycleData.lastPeriodStart;
    _cycleLengthController = TextEditingController(
      text: cycle.cycleLength.toString(),
    );
    _periodDurationController = TextEditingController(
      text: cycle.periodDuration.toString(),
    );
  }

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _periodDurationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _pickedDate = picked);
    }
  }

  void _saveAndCalculate(BuildContext context) {
    final cycleProvider = context.read<CycleProvider>();

    final cycleLength = int.tryParse(_cycleLengthController.text);
    final periodDuration = int.tryParse(_periodDurationController.text);

    if (_pickedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your last period start date'),
        ),
      );
      return;
    }
    if (cycleLength == null || cycleLength < 21 || cycleLength > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cycle length should be between 21 and 40 days'),
        ),
      );
      return;
    }
    if (periodDuration == null || periodDuration < 2 || periodDuration > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Period duration should be between 2 and 10 days'),
        ),
      );
      return;
    }

    cycleProvider.updateLastPeriodStart(_pickedDate!);
    cycleProvider.updateCycleLength(cycleLength);
    cycleProvider.updatePeriodDuration(periodDuration);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cycle data saved')));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Wellness Saheli', style: AppTextStyles.serif(size: 20)),
                ],
              ),
              const SizedBox(height: 24),
              _cycleDataCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cycleDataCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Cycle Data', style: AppTextStyles.serif(size: 20)),
          const SizedBox(height: 18),

          Text(
            'LAST PERIOD START DATE',
            style: AppTextStyles.sans(
              size: 10,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _pickedDate != null
                        ? _formatDate(_pickedDate!)
                        : 'Set Date',
                    style: AppTextStyles.sans(
                      size: 13,
                      color: _pickedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _numberField(
                  label: 'CYCLE LENGTH',
                  controller: _cycleLengthController,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _numberField(
                  label: 'PERIOD DURATION',
                  controller: _periodDurationController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _saveAndCalculate(context),
              child: Text(
                'Save & Calculate',
                style: AppTextStyles.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.sans(
            size: 10,
            weight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTextStyles.sans(size: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
