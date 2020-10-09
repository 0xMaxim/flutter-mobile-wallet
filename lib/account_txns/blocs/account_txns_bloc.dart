import 'package:coda_wallet/account_txns/blocs/account_txns_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'account_txns_events.dart';
import 'account_txns_states.dart';
import '../../service/coda_service.dart';

class AccountTxnsBloc extends Bloc<AccountTxnsEvents, AccountTxnsStates> {
  CodaService _service;
  List<AccountTxn> _accountTxns;
  String _lastCursor;
  bool _hasNextPage;
  bool _isTxnsLoading = false;

  AccountTxnsBloc(AccountTxnsStates state) : super(state) {
    _service = CodaService();
    _accountTxns = List<AccountTxn>();
    _lastCursor = null;
    _hasNextPage = false;
    _isTxnsLoading = false;
  }

  AccountTxnsStates get initState => FetchAccountTxnsLoading();
  String get lastCursor => _lastCursor;
  bool get hasNextPage => _hasNextPage;
  bool get isTxnsLoading => _isTxnsLoading;

  @override
  Stream<AccountTxnsStates> mapEventToState(AccountTxnsEvents event) async* {
    if (event is FetchAccountTxns) {
      yield* _mapFetchAccountTxnsToStates(event);
    }
  }

  Stream<AccountTxnsStates>
    _mapFetchAccountTxnsToStates(FetchAccountTxns event) async* {

    final query = event.query;
    final variables = event.variables ?? null;

    try {
      _isTxnsLoading = true;
      yield FetchAccountTxnsLoading();
      final result = await _service.performQuery(query, variables: variables);

      if (result.hasException) {
        print('account txns graphql errors: ${result.exception.graphqlErrors.toString()}');
        yield FetchAccountTxnsFail(result.exception.graphqlErrors[0]);
        return;
      }

      final List<dynamic> transactions =
        result.data['blocks']['nodes'] as List<dynamic>;
      List<AccountTxn> tmpTxns = List<AccountTxn>();
      tmpTxns = transactions
        .map((dynamic element) => _createAccountTxn(element))
        .toList();

      _accountTxns.addAll(tmpTxns);
      _hasNextPage = result.data['blocks']['pageInfo']['hasNextPage'];
      _lastCursor = result.data['blocks']['pageInfo']['lastCursor'];

      yield FetchAccountTxnsSuccess(_accountTxns);
      _isTxnsLoading = false;
    } catch (e) {
      print(e);
      yield FetchAccountTxnsFail(e.toString());
    }
  }

  AccountTxn _createAccountTxn(dynamic element) {
    Map<String, dynamic> transaction = element['transactions'] as Map<String, dynamic>;
    List<dynamic> userCommandList = transaction['userCommands'] as List<dynamic>;
    String dateTime = element['protocolState']['blockchainState']['date'] as String;

    List<UserCommand> userCommands = List<UserCommand>();

    if(userCommandList.length == 0) {
      userCommands = [];
    } else {
      userCommands = userCommandList
        .map((dynamic element) {
          return UserCommand(
            userCommandHash: element['hash'] as String,
            userCommandMemo: element['memo'] as String,
            fee: element['fee'] as String,
            toAccount: element['to'] as String,
            amount: element['amount'] as String,
            fromAccount: element['from'] as String,
            nonce: element['fromAccount']['nonce'] as String
          );
      })
      .toList();
    }

    return AccountTxn(
        userCommands: userCommands,
        coinbaseAccount: transaction['coinbaseReceiverAccount']['publicKey'] as String,
        coinbase: transaction['coinbase'] as String,
        dateTime: dateTime
    );
  }
}
