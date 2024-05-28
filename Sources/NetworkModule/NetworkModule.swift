// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Alamofire

//MARK: - Define
public protocol NetworkBuilder {
    associatedtype ResponseType
    
    var method: HTTPMethod { get }
    var header: HTTPHeader? { get }
    var baseURL: String { get }
    var path: String { get }
    var parameters: Parameters? { get }
    var parameterEncoding: ParameterEncoding { get }
    var networkSession: Session { get }
    
    func decode(from data: Data) throws -> ResponseType
}

//MARK: - Default Value Setting
extension NetworkBuilder {
    var header: HTTPHeader? { nil }
    var parameterEncoding: ParameterEncoding {
        switch method {
        case .get:
            URLEncoding.default
        default:
            JSONEncoding.default
        }
    }
}
