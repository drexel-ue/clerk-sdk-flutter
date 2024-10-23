import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpStatus, HttpHeaders;

import 'package:clerk_auth/clerk_api/token_cache.dart';
import 'package:clerk_auth/clerk_auth.dart';
import 'package:common/common.dart';
import 'package:http/http.dart' as http;

enum HttpMethod {
  delete,
  get,
  patch,
  post,
  put;

  bool get isGet => this == get;
  bool get isNotGet => isGet == false;

  @override
  String toString() => name.toUpperCase();
}

class Api with Logging {
  Api._({required this.tokenCache, required this.domain});

  factory Api({
    required String publishableKey,
    required String publicKey,
    Persistor? persistor,
  }) =>
      _instance ??= Api._(
        tokenCache: TokenCache(publicKey, persistor),
        domain: deriveDomainFrom(publishableKey),
      );

  final TokenCache tokenCache;
  final String domain;

  static final _client = http.Client();
  static Api? _instance;

  static const _scheme = 'https';
  static const _kJwtKey = 'jwt';
  static const _kIsNative = '_is_native';
  static const _kClerkSessionId = '_clerk_session_id';
  static const _kClerkJsVersion = '_clerk_js_version';
  static const _kErrorsKey = 'errors';
  static const _kClientKey = 'client';
  static const _kResponseKey = 'response';

  // environment & client

  Future<Environment> environment() async {
    final resp = await _fetch(path: '/environment', method: HttpMethod.get);
    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      final xxx = Environment.fromJson(body);
      return xxx;
    }
    return Environment.empty;
  }

  Future<Client> createClient() async {
    final resp = await _fetch(path: '/client');
    if (resp.statusCode == HttpStatus.ok) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      final xxx = Client.fromJson(body[_kResponseKey]);
      return xxx;
    }
    return Client.empty;
  }

  Future<ApiResponse> currentClient() => _fetchApiResponse('/client', method: HttpMethod.get);

  // Sign out / delete user

  Future<Client> deleteUser() async {
    await _delete('/me');
    return Client.empty;
  }

  Future<Client> signOut() async {
    await _delete('/client');
    return Client.empty;
  }

  Future<bool> _delete(String path) async {
    try {
      final headers = _headers(HttpMethod.delete);
      final resp = await _fetch(method: HttpMethod.delete, path: path, headers: headers);
      if (resp.statusCode == 200) {
        tokenCache.clear();
        return true;
      } else {
        logSevere('HTTP error on DELETE $path: ${resp.statusCode}', resp);
      }
    } catch (error, stacktrace) {
      logSevere('Error during DELETE $path', error, stacktrace);
    }

    return false;
  }

  // Sign Up API

  Future<ApiResponse> createSignUp({
    Strategy? strategy,
    String? username,
    String? firstName,
    String? lastName,
    String? password,
    String? emailAddress,
    String? phoneNumber,
    String? web3Wallet,
    String? code,
    String? token,
    Map<String, dynamic>? metadata,
  }) {
    return _fetchApiResponse(
      '/client/sign_ups',
      params: {
        'strategy': strategy,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'email_address': emailAddress,
        'phone_number': phoneNumber,
        'web3_wallet': web3Wallet,
        'code': code,
        'token': token,
        if (metadata is Map) //
          'unsafe_metadata': jsonEncode(metadata!),
      },
    );
  }

  Future<ApiResponse> updateSignUp(
    SignUp signUp, {
    Strategy? strategy,
    String? username,
    String? firstName,
    String? lastName,
    String? password,
    String? emailAddress,
    String? phoneNumber,
    String? web3Wallet,
    String? code,
    String? token,
    Map<String, dynamic>? metadata,
  }) {
    return _fetchApiResponse(
      '/client/sign_ups/${signUp.id}',
      method: HttpMethod.patch,
      params: {
        'strategy': strategy,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'email_address': emailAddress,
        'phone_number': phoneNumber,
        'web3_wallet': web3Wallet,
        'code': code,
        'token': token,
        if (metadata is Map) //
          'unsafe_metadata': jsonEncode(metadata!),
      },
    );
  }

  Future<ApiResponse> prepareSignUp(
    SignUp signUp, {
    required Strategy strategy,
    String? redirectUrl,
  }) async {
    return _fetchApiResponse(
      '/client/sign_ups/${signUp.id}/prepare_verification',
      params: {
        'strategy': strategy,
      },
    );
  }

  Future<ApiResponse> attemptSignUp(
    SignUp signUp, {
    required Strategy strategy,
    String? code,
    String? signature,
  }) async {
    return _fetchApiResponse(
      '/client/sign_ups/${signUp.id}/attempt_verification',
      params: {
        'strategy': strategy,
        'code': code,
      },
    );
  }

  // Sign In API

  Future<ApiResponse> createSignIn({
    Strategy? strategy,
    String? identifier,
    String? password,
    String? redirectUrl,
  }) =>
      _fetchApiResponse(
        '/client/sign_ins',
        params: {
          'strategy': strategy,
          'identifier': identifier,
          'password': password,
          'redirect_url': redirectUrl,
        },
      );

  Future<ApiResponse> retrieveSignIn(SignIn signIn) =>
      _fetchApiResponse('/client/sign_ins/${signIn.id}', method: HttpMethod.get);

  Future<ApiResponse> prepareSignIn(
    SignIn signIn, {
    required Stage stage,
    required Strategy strategy,
    String? redirectUrl,
  }) async {
    final factor = signIn.factorFor(strategy, stage);
    if (factor is! Factor) {
      return ApiResponse(
        status: HttpStatus.badRequest,
        errors: [ApiError(message: 'Strategy $strategy unsupported')],
      );
    }

    return _fetchApiResponse(
      '/client/sign_ins/${signIn.id}/prepare_${stage}_factor',
      params: {
        'strategy': strategy,
        'email_address_id': factor.emailAddressId,
        'phone_number_id': factor.phoneNumberId,
        'web3_wallet_id': factor.web3WalletId,
        'passkey_id': factor.passkeyId,
        'redirect_url': redirectUrl,
      },
    );
  }

  Future<ApiResponse> attemptSignIn(
    SignIn signIn, {
    required Stage stage,
    required Strategy strategy,
    String? code,
    String? password,
  }) async {
    final factor = signIn.factorFor(strategy, stage);
    if (factor is! Factor) {
      return ApiResponse(status: HttpStatus.badRequest);
    }

    return _fetchApiResponse(
      '/client/sign_ins/${signIn.id}/attempt_${stage}_factor',
      params: {
        'strategy': strategy,
        'code': code,
        'password': password,
      },
    );
  }

  // User

  Future<ApiResponse> getUser() => _fetchApiResponse('/me', method: HttpMethod.get);

  Future<ApiResponse> updateUser(User user) async {
    return _fetchApiResponse(
      '/me',
      method: HttpMethod.patch,
      params: {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'primary_email_address_id': user.primaryEmailAddressId,
        'primary_phone_number_id': user.primaryPhoneNumberId,
        'primary_web3_wallet_id': user.primaryWeb3WalletId,
      },
    );
  }

  // Email

  Future<ApiResponse> addEmailAddressToCurrentUser(String emailAddress) async {
    return _fetchApiResponse(
      '/me/email_addresses',
      requiresSessionId: true,
      params: {
        'email_address': emailAddress,
      },
    );
  }

  Future<ApiResponse> deleteEmailAddress(String emailAddressId) => _fetchApiResponse(
        '/me/email_addresses/$emailAddressId',
        requiresSessionId: true,
        method: HttpMethod.delete,
      );

  // Phone Number

  Future<ApiResponse> addPhoneNumberToCurrentUser(String phoneNumber) async {
    return _fetchApiResponse(
      '/me/phone_numbers',
      requiresSessionId: true,
      params: {
        'phone_number': phoneNumber,
      },
    );
  }

  Future<ApiResponse> deletePhoneNumber(String phoneNumberId) => _fetchApiResponse(
        '/me/phone_numbers/$phoneNumberId',
        requiresSessionId: true,
        method: HttpMethod.delete,
      );

  // Session

  Future<String> sessionToken() async {
    if (tokenCache.sessionToken.isEmpty && tokenCache.canRefreshSessionToken) {
      final resp = await _fetch(path: '/client/sessions/${tokenCache.sessionId}/tokens');
      if (resp.statusCode == HttpStatus.ok) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        tokenCache.sessionToken = body[_kJwtKey] as String;
      }
    }
    return tokenCache.sessionToken;
  }

  // Internal

  Future<ApiResponse> _fetchApiResponse(
    String url, {
    HttpMethod method = HttpMethod.post,
    Map<String, String>? headers,
    Map<String, dynamic>? params,

    /// for requests that require a `_client_session_id` query parameter,
    /// set this to true. see: https://clerk.com/docs/reference/frontend-api/tag/Email-Addresses#operation/createEmailAddresses
    bool requiresSessionId = false,
  }) async {
    try {
      final fullHeaders = _headers(method, headers);
      final resp = await _fetch(
        method: method,
        path: url,
        params: params,
        headers: fullHeaders,
        requiresSessionId: requiresSessionId,
      );

      final body = json.decode(resp.body) as Map<String, dynamic>;
      final errors = body[_kErrorsKey] != null
          ? List<Map<String, dynamic>>.from(body[_kErrorsKey]).map(ApiError.fromJson).toList()
          : null;
      final clientData = switch (body[_kClientKey]) {
        Map<String, dynamic> client when client.isNotEmpty => client,
        _ => body[_kResponseKey],
      };
      if (clientData case Map<String, dynamic> clientJson) {
        final client = Client.fromJson(clientJson);
        tokenCache.updateFrom(resp, client.activeSession);
        return ApiResponse(client: client, status: resp.statusCode, errors: errors);
      } else {
        logSevere(body);
        return ApiResponse(status: resp.statusCode, errors: errors);
      }
    } catch (error, stacktrace) {
      print('ERROR: $error');
      logSevere('Error during fetch', error, stacktrace);
      return ApiResponse(
        status: HttpStatus.internalServerError,
        errors: [ApiError(message: error.toString())],
      );
    }
  }

  Future<http.Response> _fetch({
    required String path,
    HttpMethod method = HttpMethod.post,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    bool requiresSessionId = false,
  }) async {
    params?.removeWhere((key, value) => value == null);
    final queryParams = {
      _kIsNative: true,
      _kClerkJsVersion: Auth.jsVersion,
      if (requiresSessionId) //
        _kClerkSessionId: tokenCache.sessionId,
      if (method.isGet) //
        ...?params,
    };
    final body = method.isNotGet ? params : null;
    final uri = _uri(path, queryParams);

    logInfo('$method $uri ${body.toString()}');

    final resp = await _client.sendHttpRequest(method, uri, body: body, headers: headers);

    if (resp.statusCode == HttpStatus.tooManyRequests) {
      final delay = int.tryParse(resp.headers['retry-after'] ?? '') ?? 500;
      logSevere('Delaying ${delay}secs');
      await Future.delayed(Duration(seconds: delay));
      return _fetch(
        path: path,
        method: method,
        headers: headers,
        params: params,
        requiresSessionId: requiresSessionId,
      );
    }

    return resp;
  }

  Uri _uri(String path, Map<String, dynamic> params) =>
      Uri(scheme: _scheme, host: domain, path: 'v1$path', queryParameters: params.toStringMap());

  Map<String, String> _headers(HttpMethod method, [Map<String, String>? headers]) {
    return {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader:
          method.isGet ? 'application/json' : 'application/x-www-form-urlencoded',
      if (tokenCache.clientToken.isNotEmpty) //
        HttpHeaders.authorizationHeader: tokenCache.clientToken,
      ...?headers,
    };
  }

  static String deriveDomainFrom(String key) {
    final domainStartPosition = key.lastIndexOf('_') + 1;
    if (domainStartPosition < 1) {
      throw FormatException('Public key not in correct format');
    }

    // base64 requires quad-byte aligned strings, but the string that comes from Clerk
    // isn't. This removes Clerk's padding, adds our own to the correct length,
    // decodes the string and then removes unnecessary trailing characters.
    // It's messy, and should be improved. I've probably missed something obvious.
    final domainPart = key.substring(domainStartPosition);
    final encodedPart = domainPart.padRight(((domainPart.length - 1) ~/ 4) * 4 + 4, '=');
    final encodedDomain = utf8.decode(base64.decode(encodedPart));
    return encodedDomain.split('\$').first;
  }
}

extension SendExtension on http.Client {
  Future<http.Response> sendHttpRequest(
    HttpMethod method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method.toString(), uri);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (body != null) {
      request.bodyFields = body.toStringMap();
    }
    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }
}

extension StringMapExtension on Map {
  Map<String, String> toStringMap() => map((k, v) => MapEntry(k.toString(), v.toString()));
}
