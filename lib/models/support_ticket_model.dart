class SupportTicket {
  final int ticketID;
  final int farmerID;
  final String subject;
  final String description;
  final String status; // Open, In Progress, Resolved, Closed
  final String priority; // Low, Medium, High, Urgent
  final String? category;
  final int? assignedTo;
  final String? response;
  final String? resolution;
  final String? resolvedAt;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? farmer;
  final Map<String, dynamic>? assignedAdmin;

  SupportTicket({
    required this.ticketID,
    required this.farmerID,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.category,
    this.assignedTo,
    this.response,
    this.resolution,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.farmer,
    this.assignedAdmin,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      ticketID:      json['ticketID']     ?? json['ticket_id']    ?? 0,
      farmerID:      json['farmerID']     ?? json['farmer_id']    ?? 0,
      subject:       json['subject']      ?? '',
      description:   json['description']  ?? '',
      status:        json['status']       ?? 'Open',
      priority:      json['priority']     ?? 'Medium',
      category:      json['category'],
      assignedTo:    json['assignedTo']   ?? json['assigned_to'],
      response:      json['response'],
      resolution:    json['resolution'],
      resolvedAt:    json['resolvedAt']   ?? json['resolved_at'],
      createdAt:     json['createdAt']    ?? json['created_at'],
      updatedAt:     json['updatedAt']    ?? json['updated_at'],
      farmer:        json['farmer']       != null ? Map<String, dynamic>.from(json['farmer'])       : null,
      assignedAdmin: json['assignedAdmin'] != null ? Map<String, dynamic>.from(json['assignedAdmin']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'farmerID':    farmerID,
    'subject':     subject,
    'description': description,
    'priority':    priority,
    'category':    category,
  };

  // Helper getters
  bool get isOpen       => status == 'Open';
  bool get isInProgress => status == 'In Progress';
  bool get isResolved   => status == 'Resolved';
  bool get isClosed     => status == 'Closed';
  bool get isUrgent     => priority == 'Urgent';
  bool get hasResponse  => response != null && response!.isNotEmpty;

  String get farmerName {
    if (farmer == null) return 'Farmer #$farmerID';
    return '${farmer!['firstName'] ?? ''} ${farmer!['lastName'] ?? ''}'.trim();
  }
}