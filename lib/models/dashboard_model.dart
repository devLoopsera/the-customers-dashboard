class DashboardSummary {
  final int totalJobs;
  final int completedJobs;
  final int pendingJobs;
  final int runningJobs;
  final int cancelledJobs;
  final double totalHoursThisMonth;
  final double totalHoursAllTime;

  DashboardSummary({
    required this.totalJobs,
    required this.completedJobs,
    required this.pendingJobs,
    required this.runningJobs,
    required this.cancelledJobs,
    required this.totalHoursThisMonth,
    required this.totalHoursAllTime,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalJobs: json['total_jobs'] ?? 0,
      completedJobs: json['completed_jobs'] ?? 0,
      pendingJobs: json['pending_jobs'] ?? 0,
      runningJobs: json['running_jobs'] ?? 0,
      cancelledJobs: json['cancelled_jobs'] ?? 0,
      totalHoursThisMonth: (json['total_hours_this_month'] ?? 0).toDouble(),
      totalHoursAllTime: (json['total_hours_all_time'] ?? 0).toDouble(),
    );
  }
}

class Job {
  final String jobId;
  final String customerName;
  final String date;
  final String status;
  final double hours;
  final String address;
  final String? customerStartTime;
  final String? customerStopTime;
  final String? employeeStartTime;
  final String? employeeEndTime;
  final double? employeeTotalHours;
  final String? cancelledDateTime;

  final double? price;
  final String? serviceName;
  
  // New fields from updated webhook
  final String? optionalProducts;
  final String? customerMessage;
  final double? servicePriceNetto;
  final String? unit;
  final double? bruttoCustomerPay;
  final double? taxValue;
  final double? taxPercent;
  final double? customerPriceNetto;

  Job({
    required this.jobId,
    required this.customerName,
    required this.date,
    required this.status,
    required this.hours,
    required this.address,
    this.customerStartTime,
    this.customerStopTime,
    this.employeeStartTime,
    this.employeeEndTime,
    this.employeeTotalHours,
    this.cancelledDateTime,
    this.price,
    this.serviceName,
    this.optionalProducts,
    this.customerMessage,
    this.servicePriceNetto,
    this.unit,
    this.bruttoCustomerPay,
    this.taxValue,
    this.taxPercent,
    this.customerPriceNetto,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final custPriceNetto = parseDouble(json['customer_price_netto']);
    final oldPrice = parseDouble(json['price']);

    String? service = json['service']?.toString().trim();
    String? serviceNameField = json['service_name']?.toString().trim();
    String fallbackName = json['customer_name']?.toString().trim() ?? 'Unnamed Service';

    // Prioritize the specific 'service' key mentioned by the user
    String finalServiceName = (service != null && service.isNotEmpty) 
        ? service 
        : (serviceNameField != null && serviceNameField.isNotEmpty)
            ? serviceNameField
            : fallbackName;

    return Job(
      jobId: json['job_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      hours: parseDouble(json['hours']) ?? 0.0,
      address: json['address'] ?? '',
      customerStartTime: json['customer_start_time'],
      customerStopTime: json['customer_stop_time'],
      employeeStartTime: json['employee_start_time'],
      employeeEndTime: json['employee_end_time'],
      employeeTotalHours: parseDouble(json['employee_total_hours']),
      cancelledDateTime: json['cancelled_date_time'],
      price: custPriceNetto ?? oldPrice,
      serviceName: finalServiceName,
      optionalProducts: json['optional_products'],
      customerMessage: json['customer_message'],
      servicePriceNetto: parseDouble(json['service_price_netto']),
      unit: json['unit'],
      bruttoCustomerPay: parseDouble(json['brutto_customer_pay']),
      taxValue: parseDouble(json['tax_value']),
      taxPercent: parseDouble(json['tax_percent']),
      customerPriceNetto: custPriceNetto,
    );
  }
}

class Invoice {
  final String customerName;
  final int invoiceNumber;
  final String issueDate;
  final String invoiceLink;

  Invoice({
    required this.customerName,
    required this.invoiceNumber,
    required this.issueDate,
    required this.invoiceLink,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      customerName: json['customer_name'] ?? '',
      invoiceNumber: json['invoice_number'] ?? 0,
      issueDate: json['issue_date'] ?? '',
      invoiceLink: json['invoice_link'] ?? '',
    );
  }
}

class DashboardData {
  final bool success;
  final DashboardSummary summary;
  final List<Job> completedJobs;
  final List<Job> pendingJobs;
  final List<Job> runningJobs;
  final List<Job> cancelledJobs;
  final List<Invoice> invoices;

  DashboardData({
    required this.success,
    required this.summary,
    required this.completedJobs,
    required this.pendingJobs,
    required this.runningJobs,
    required this.cancelledJobs,
    required this.invoices,
  });

  factory DashboardData.fromList(List<dynamic> list) {
    if (list.isEmpty) throw Exception("Empty response");
    final json = list[0] as Map<String, dynamic>;
    
    return DashboardData(
      success: json['success'] ?? false,
      summary: DashboardSummary.fromJson(json['summary'] ?? {}),
      completedJobs: (json['completed_jobs'] as List?)?.map((e) => Job.fromJson(e)).toList() ?? [],
      pendingJobs: (json['pending_jobs'] as List?)?.map((e) => Job.fromJson(e)).toList() ?? [],
      runningJobs: (json['running_jobs'] as List?)?.map((e) => Job.fromJson(e)).toList() ?? [],
      cancelledJobs: (json['cancelled_jobs'] as List?)?.map((e) => Job.fromJson(e)).toList() ?? [],
      invoices: (json['invoices'] as List?)?.map((e) => Invoice.fromJson(e)).toList() ?? [],
    );
  }
}
