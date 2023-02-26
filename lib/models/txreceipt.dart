class TransactionReceipt {

  final String slotData;
  final String transactionHash;
  final int? transactionIndex;
  final String? blockHash;
  final int? blockNumber;
  final String? from;
  final String? to;
  final int? cumulativeGasUsed;
  final int? gasUsed;
  final bool? status;
  final String date;
  final int timestamp;

  TransactionReceipt(this.slotData, this.transactionHash, this.transactionIndex, this.blockHash, this.blockNumber, this.from, this.to, this.cumulativeGasUsed, this.gasUsed, this.status, this.date, this.timestamp);

  TransactionReceipt.fromJson(Map<String, dynamic> json)
      : slotData = json['slotData'] as String,
        transactionHash = json['transactionHash'] as String,
        transactionIndex = json['transactionIndex'] as int,
        blockHash = json['blockHash'] as String,
        blockNumber = json['blockNumber'] as int,
        from = json['from'] as String,
        to = json['to'] as String,
        cumulativeGasUsed = json['cumulativeGasUsed'] as int,
        gasUsed = json['gasUsed'] as int,
        status = json['status'] as bool,
        date = json['date'] as String,
        timestamp = json['timestamp'] as int;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'slotData': slotData,
    'transactionHash': transactionHash,
    'transactionIndex': transactionIndex,
    'blockHash': blockHash,
    'blockNumber': blockNumber,
    'from': from,
    'to': to,
    'cumulativeGasUsed': cumulativeGasUsed,
    'gasUsed': gasUsed,
    'status': status,
    'date': date,
    'timestamp': timestamp
  };

}