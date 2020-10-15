const ACCOUNT_LOCK_MUTATION = r'''
  mutation AccountLockMutation($publicKey: PublicKey!) {
    __typename
    lockAccount(input: {publicKey: $publicKey})
  }
''';

const ACCOUNT_UNLOCK_MUTATION = r'''
  mutation AccountUnlockMutation($publicKey: PublicKey!, $password: String!) {
    __typename
    unlockAccount(input: {publicKey: $publicKey, password: $password})
  }
''';

const CREATE_ACCOUNT_MUTATION = r'''
  mutation CreateAccountMutation($password: String!) {
    __typename
    createAccount(input: {password: $password}) {
      account {
        locked
        balance {
          total
        }
        publicKey
      }
    }
  }
''';