// Copyright 2015-present 650 Industries. All rights reserved.

import Foundation

struct CdpNetwork {
  // MARK: Types

  typealias Headers = [String: String]?
  typealias MonotonicTime = TimeInterval
  typealias RequestId = String
  typealias TimeSinceEpoch = TimeInterval

  enum ResourceType: String, Encodable {
    case image = "Image"
    case media = "Media"
    case font = "Font"
    case script = "Script"
    case fetch = "Fetch"
    case other = "Other"
  }

  struct ConnectTiming: Encodable {
    let requestTime: MonotonicTime
  }

  struct Request: Encodable {
    let url: String
    let method: String
    let headers: Headers
    let postData: String?

    init(_ request: URLRequest) {
      self.url = request.url?.absoluteString ?? ""
      self.method = request.httpMethod ?? "GET"
      self.headers = request.allHTTPHeaderFields ?? [:]
      if let httpBody = request.httpBodyData() {
        self.postData = String(data: httpBody, encoding: .utf8)
      } else {
        self.postData = nil
      }
    }
  }

  struct Response: Encodable {
    let url: String
    let status: Int
    let statusText: String
    let headers: Headers
    let mimeType: String
    let encodedDataLength: Int64

    init(_ response: HTTPURLResponse) {
      self.url = response.url?.absoluteString ?? ""
      self.status = response.statusCode
      self.statusText = ""
      let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, header in
        if let key = header.key as? String, let value = header.value as? String {
          result[key] = value
        }
      }
      self.headers = headers
      self.mimeType = response.value(forHTTPHeaderField: "Content-Type") ?? ""
      self.encodedDataLength = response.expectedContentLength
    }
  }

  // MARK: Events

  struct RequestWillBeSentParams: EventParms {
    let requestId: RequestId
    var loaderId = ""
    var documentURL = "mobile"
    let request: Request
    let timestamp: MonotonicTime
    let wallTime: TimeSinceEpoch
    var initiator = ["type": "script"]
    var redirectHasExtraInfo: Bool {
      return self.redirectResponse != nil
    }
    let redirectResponse: Response?
    var referrerPolicy = "no-referrer"
    let type: ResourceType

    init(now: TimeInterval, requestId: RequestId, request: URLRequest, redirectResponse: HTTPURLResponse?) {
      self.requestId = requestId
      self.request = Request(request)
      self.timestamp = now
      self.wallTime = now
      if let redirectResponse = redirectResponse {
        self.redirectResponse = Response(redirectResponse)
      } else {
        self.redirectResponse = nil
      }
      self.type = ResourceType.fetch
    }
  }

  struct RequestWillBeSentExtraInfoParams: EventParms {
    let requestId: RequestId
    var associatedCookies = [String: String]()
    let headers: Headers
    let connectTiming: ConnectTiming

    init(now: TimeInterval, requestId: RequestId, request: URLRequest) {
      self.requestId = requestId
      self.headers = request.allHTTPHeaderFields ?? [:]
      self.connectTiming = ConnectTiming(requestTime: now)
    }
  }

  struct ResponseReceivedParams: EventParms {
    let requestId: RequestId
    var loaderId = ""
    let timestamp: MonotonicTime
    let type: ResourceType
    let response: Response
    var hasExtraInfo = false

    init(now: TimeInterval, requestId: RequestId, request: URLRequest, response: HTTPURLResponse) {
      self.requestId = requestId
      self.timestamp = now
      self.type = ResourceType.fetch
      self.response = Response(response)
    }
  }

  struct LoadingFinishedParams: EventParms {
    let requestId: RequestId
    let timestamp: MonotonicTime
    let encodedDataLength: Int64

    init(now: TimeInterval, requestId: RequestId, request: URLRequest, response: HTTPURLResponse) {
      self.requestId = requestId
      self.timestamp = now
      self.encodedDataLength = response.expectedContentLength
    }
  }

  struct ExpoReceivedResponseBodyParams: EventParms {
    let requestId: RequestId
    let body: String
    let base64Encoded: Bool

    init(now: TimeInterval, requestId: RequestId, responseBody: Data, isText: Bool) {
      self.requestId = requestId
      let bodyString = isText ? String(data: responseBody, encoding: .utf8) : responseBody.base64EncodedString()
      if let bodyString = bodyString {
        self.body = bodyString
        self.base64Encoded = !isText
      } else {
        self.body = ""
        self.base64Encoded = false
      }
    }
  }

  typealias EventParms = Encodable

  struct Event<T: EventParms>: Encodable {
    let method: String
    let params: T
  }
}
