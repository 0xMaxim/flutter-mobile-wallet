class Account {
  const Account({this.publicKey, this.locked, this.balance});

  final String publicKey;
  final String balance;
  final bool locked;
}