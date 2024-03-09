/// http请求

import 'dart:async';
import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/material.dart';

export 'package:dio/dio.dart';
import 'package:dio/dio.dart';

import '../constants/api.dart';
import '../utils/index.dart';

enum HttpDioType {
  none,
  api,
  upload,
}

class Http {
  static Dio dio = createInstance();

  /// default options
  static const Duration CONNECT_TIEMOUT = Duration(seconds: 10);
  static const Duration RECEIVE_TIMEOUT = Duration(seconds: 10);

  /// http request methods
  static const String GET = 'get';
  static const String POST = 'post';
  static const String PUT = 'put';
  static const String PATCH = 'patch';
  static const String DELETE = 'delete';

  static BuildContext? CONTENT;

  static String get USERAGENT {
    return "client-phone";
  }

  static of(BuildContext content) {
    return CONTENT = content;
  }

  /// request method
  static Future request(
    String url, {
    String httpDioValue = "network_service_request",
    HttpDioType httpDioType = HttpDioType.api,
    Object? data = const {},
    Map<String, dynamic>? parame,
    method = GET,
    Map<String, dynamic>? headers,
  }) async {
    Response result = Response(
      data: {},
      requestOptions: RequestOptions(
        path: '/',
        validateStatus: (_) => true,
      ),
    );
    headers = headers ?? {};

    if (headers.isNotEmpty && Http.USERAGENT.isNotEmpty) {
      headers.addAll({HttpHeaders.userAgentHeader: Http.USERAGENT});
    }

    String domain = "";
    switch (httpDioType) {
      case HttpDioType.api:
        domain = httpDioValue.isEmpty ? "" : Config.apiHost[httpDioValue]!.url;
        break;
      case HttpDioType.none:
      default:
        domain = "";
        break;
    }

    String path = "${domain.isEmpty ? "" : "$domain/"}$url";

    try {
      Response response = await dio.request(
        path,
        data: data,
        queryParameters: parame,
        options: Options(
          method: method,
          headers: headers,
          validateStatus: (_) => true,
        ),
      );

      result = response;
    } on DioExceptionType catch (e) {
      switch (e) {
        case DioExceptionType.receiveTimeout:
          return Response(
            data: {'error': -1},
            requestOptions: RequestOptions(path: url, method: method),
          );
        case DioExceptionType.connectionTimeout:
          return Response(
            data: {'error': -4},
            requestOptions: RequestOptions(path: url, method: method),
          );
        case DioExceptionType.sendTimeout:
          return Response(
            data: {'error': -6},
            requestOptions: RequestOptions(path: url, method: method),
          );
        case DioExceptionType.badCertificate:
          return Response(
            data: {'error': -2, 'message': 'bad certificate'},
            requestOptions: RequestOptions(path: url, method: method),
          );
          break;
        case DioExceptionType.badResponse:
          return Response(
            data: {'error': -2, 'message': 'bad response'},
            requestOptions: RequestOptions(path: url, method: method),
          );
        case DioExceptionType.cancel:
          return Response(
            data: {'error': -3},
            requestOptions: RequestOptions(path: url, method: method),
          );
        case DioExceptionType.connectionError:
          return Response(
            data: {'error': -2, 'message': 'connection error'},
            requestOptions: RequestOptions(path: url, method: method),
          );
        case DioExceptionType.unknown:
          return Response(
            data: {'error': -2, 'message': 'unknown'},
            requestOptions: RequestOptions(path: url, method: method),
          );
      }
    }
    return result;
  }

  static Dio createInstance() {
    /// 全局属性：请求前缀、连接超时时间、响应超时时间
    BaseOptions options = BaseOptions(
      connectTimeout: CONNECT_TIEMOUT,
      receiveTimeout: RECEIVE_TIMEOUT,
    );
    dio = Dio(options);

    // 缓存实例
    // by https://pub.dev/packages/dio_cache_interceptor
    dio.interceptors.add(DioCacheInterceptor(
      options: CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.request,
        hitCacheOnErrorExcept: [],
        maxStale: const Duration(days: 7),
        priority: CachePriority.normal,
        cipher: null,
        keyBuilder: CacheOptions.defaultCacheKeyBuilder,
        allowPostMethod: false,
      ),
    ));

    // Add the interceptor
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print,
      retries: 2,
      retryDelays: const [
        Duration(seconds: 3),
        Duration(seconds: 10),
      ],
    ));

    return dio;
  }
}
