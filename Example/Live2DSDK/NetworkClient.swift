//
//  NetworkClient.swift
//  sst
//
//  Created by NY on 2025/4/18.
//


import Foundation


enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

class NetworkClient {
    
    // 共享实例
    static let shared = NetworkClient()
    
    private init() {}
    
    // 发起网络请求的公共函数
    func request(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        body: [String: Any]? = nil,
        bodyIsFormEncoded: Bool = false, // 是否将body编码为form表单格式
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // 设置 HTTP Header
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // 设置 Content-Type
        if bodyIsFormEncoded {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        
        // 设置 HTTP Body（仅 POST 和 PUT 支持）
        if let body = body, (method == .POST || method == .PUT) {
            if bodyIsFormEncoded {
                // 转换为 form-urlencoded 格式
                request.httpBody = bodyToFormData(body: body)
            } else {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                // 默认为 JSON 格式
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                    request.httpBody = jsonData
                } catch {
                    completion(.failure(error))
                    return
                }
            }
        }
        
        // 创建 URLSession 数据任务
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "USNetworkClientError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            }
        }
        
        task.resume()
    }
    
    // GET 请求
    func get(url: URL, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        request(url: url, method: .GET, headers: headers, completion: completion)
    }
    
    // POST 请求
    func post(url: URL, headers: [String: String]? = nil, body: [String: Any]? = nil, bodyIsFormEncoded: Bool = false, completion: @escaping (Result<Data, Error>) -> Void) {
        request(url: url, method: .POST, headers: headers, body: body, bodyIsFormEncoded: bodyIsFormEncoded, completion: completion)
    }
    
    // PUT 请求
    func put(url: URL, headers: [String: String]? = nil, body: [String: Any]? = nil, bodyIsFormEncoded: Bool = false, completion: @escaping (Result<Data, Error>) -> Void) {
        request(url: url, method: .PUT, headers: headers, body: body, bodyIsFormEncoded: bodyIsFormEncoded, completion: completion)
    }
    
    // DELETE 请求
    func delete(url: URL, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        request(url: url, method: .DELETE, headers: headers, completion: completion)
    }
    
    // 将字典编码为 form-urlencoded 格式
    private func bodyToFormData(body: [String: Any]) -> Data? {
        var components: [String] = []
        
        for (key, value) in body {
            debugPrint("USPictureSearchIntent request body key:\(key) value: \(value)")
            if let value = value as? String {
                components.append("\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
            } else if let value = value as? Int {
                components.append("\(key)=\(String(value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
            } else if let value = value as? Double {
                components.append("\(key)=\(String(value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
            } else if let array = value as? [[String: Any]] {
                let arrayString = convertToJSONString(array: array).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                components.append("\(key)=\(arrayString)")
            } else if let dict = value as? [String: Any] {
                let dictString = convertToJSONString(dict: dict).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                components.append("\(key)=\(dictString)")
            }
        
        }
        
        let bodyString = components.joined(separator: "&")
        return bodyString.data(using: .utf8)
    }
    
    private func convertToJSONString(dict: [String: Any]) -> String {
        do {
            // 将字典转换为 JSON 数据
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            
            // 将 JSON 数据转换为字符串
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            return jsonString ?? ""
        } catch {
            debugPrint("USPictureSearchIntent Error converting dictionary to JSON string: \(error)")
            return ""
        }
    }
    
    private func convertToJSONString(array: [[String: Any]]) -> String {
        do {
            // 将数组转换为 JSON 数据
            let jsonData = try JSONSerialization.data(withJSONObject: array, options: [])
            
            // 将 JSON 数据转换为字符串
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            return jsonString ?? ""
        } catch {
            debugPrint("Error converting array to JSON string: \(error)")
            return ""
        }
    }

}
