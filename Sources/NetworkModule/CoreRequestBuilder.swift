//
//  CoreRequestBuilder.swift
//
//
//  Created by 이숭인 on 5/29/24.
//

import Foundation
import Combine
import Alamofire

private enum AssociatedKeys {
    static var dataRequestWrapperKey: UInt8 = 0
}

@available(macOS 10.15, *)
public protocol CoreRequestBuilder: NetworkBuilder {
    typealias DataRequestWrapper = Result<DataRequest, CommonNetworkError>
    
    func request(debug: Bool) -> AnyPublisher<ResponseType, Error>
    func mockRequest(from string: String) -> AnyPublisher<ResponseType, Error>
    func cancel()
}

//MARK: - DataRequestWrapper
@available(macOS 10.15, *)
extension CoreRequestBuilder {
    private var dataRequestWrapper: DataRequestWrapper {
        /// wrapper의 레퍼런스가 등록되어있는지 확인
        if let wrapper = objc_getAssociatedObject(self, &AssociatedKeys.dataRequestWrapperKey) as? DataRequestWrapper {
            return wrapper
        }
        
        let wrapper = createDataRequestWrapper()
        /// wapper의 레퍼런스 등록
        objc_setAssociatedObject(self, &AssociatedKeys.dataRequestWrapperKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return wrapper
    }
    
    private func createDataRequestWrapper() -> DataRequestWrapper {
        guard let convertedURL = createURL() else {
            return .failure(CommonNetworkError.invalidURL)
        }
        
        let request = networkSession.request(convertedURL,
                                             method: method,
                                             parameters: parameters,
                                             encoding: parameterEncoding,
                                             headers: header)
        
        return .success(request)
    }
    
    private func createURL() -> URL? {
        (baseURL + path).toURL
    }
}

//MARK: - Request
@available(macOS 10.15, *)
extension CoreRequestBuilder {
    public func request(debug: Bool) -> AnyPublisher<ResponseType, Error> {
        return Deferred {
            self.defaultRequest(debug: debug)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    public func defaultRequest(debug: Bool) -> AnyPublisher<ResponseType, Error> {
        Future<ResponseType, Error> { promise in
            if case .failure(let error) = self.dataRequestWrapper {
                promise(.failure(error))
            }
            
            guard case .success(let dataRequest) = self.dataRequestWrapper else {
                return promise(.failure(CommonNetworkError.unknown))
            }
            
            if debug {
                print("Network -> URL(\(self.method.rawValue)) : \(String(describing: dataRequest.convertible.urlRequest?.url))")
                print("Network -> request header : \(String(describing: self.header))")
                print("Network -> parameters : \(String(describing: self.parameters))")
            }
            
            dataRequest.responseData { dataResponse in
                if dataRequest.isCancelled {
                    return promise(.failure(CommonNetworkError.cancelled))
                }
                
                if let error = dataRequest.error {
                    return promise(.failure(error))
                }
                
                guard let response = dataResponse.response, let data = dataResponse.data else {
                    return promise(.failure(CommonNetworkError.invalidResponse))
                }
                
                do {
                    let response = try decodeResponse(debug: debug, response: response, data: data)
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

@available(macOS 10.15, *)
extension CoreRequestBuilder {
    public func mockRequest(from string: String) -> AnyPublisher<ResponseType, Error> {
        guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
            return Fail(error: CommonNetworkError.unknown).eraseToAnyPublisher()
        }

        return Deferred {
            Future<ResponseType, Error> { promise in
                do {
                    let decoded = try decode(from: data)
                    promise(.success(decoded))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}


extension String {
    public var toURL: URL? {
        if !isEscaped(), let encoded = addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: encoded)
        } else {
            return URL(string: self)
        }
    }
    
    private func isEscaped() -> Bool {
        removingPercentEncoding != self
    }
}
