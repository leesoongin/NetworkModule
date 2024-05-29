// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Alamofire

public typealias AdditionalHeader = [String: String]

//MARK: - Define
public protocol NetworkBuilder {
    associatedtype ResponseType: Decodable
    
    var method: HTTPMethod { get }
    var header: HTTPHeaders? { get }
    var baseURL: String { get }
    var path: String { get }
    var parameters: Parameters? { get }
    var parameterEncoding: ParameterEncoding { get }
    var networkSession: Session { get }
    var additionalHeader: AdditionalHeader? { get }
}

//MARK: - Default Value Setting
public extension NetworkBuilder {
    var header: HTTPHeaders? {
        var defaultHeader: HTTPHeaders = .default

        header?.makeIterator().forEach {
            defaultHeader.update($0)
        }
        
        additionalHeader?.forEach { (key, value) in
            defaultHeader.update(name: key, value: value)
        }
        
        return defaultHeader
    }
    var parameterEncoding: ParameterEncoding {
        switch method {
        case .get:
            URLEncoding.default
        default:
            JSONEncoding.default
        }
    }
    var networkSession: Session {
        Session.default
    }
    var additionalHeader: AdditionalHeader? { nil }
}

extension NetworkBuilder {
    func decode(from data: Data) throws -> ResponseType {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ResponseType.self, from: data)
    }
}

extension NetworkBuilder {
    func decodeResponse(debug: Bool, response: HTTPURLResponse, data: Data) throws -> ResponseType {
        if debug {
            print("Network -> response : \(response)")
            print("Network -> \(String(decoding: data, as: UTF8.self))")
        }
        
        do {
            return try decode(from: data)
        } catch {
            throw error
        }
    }
}
