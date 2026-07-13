import Foundation
import Combine
import CryptoKit
import Alamofire

/// OSS STS 凭证数据
struct STSData {
    let accessKeyId: String
    let accessKeySecret: String
    let securityToken: String
    let expiration: String
    let bucketName: String
    let endpoint: String
    let dir: String
    let statusCode: Int
}

/// STS 接口响应模型
struct STSResponse: Decodable {
    let code: Int?
    let message: String?
    let data: STSDataPayload?
}

/// STS data 字段
struct STSDataPayload: Decodable {
    let AccessKeyId: String?
    let AccessKeySecret: String?
    let SecurityToken: String?
    let Expiration: String?
    let BucketName: String?
    let Endpoint: String?
    let dir: String?
    let StatusCode: Int?
}

/// OSS 上传工具类
class OssUploadUtil {
    /// 用于保存网络请求的订阅，防止被释放
    private static var cancellables = Set<AnyCancellable>()
    
    /// 步骤1：获取STS凭证
    static func getSTS(type: String, completion: @escaping (STSData?) -> Void) {
        let params: [String: Any] = ["type": type]
        NetworkManager.shared.post("/sts/index", parameters: params, as: STSDataPayload.self)
            .sink(receiveCompletion: { (result: Subscribers.Completion<APIError>) in
                switch result {
                case .failure(let error):
                    #if DEBUG
                    print("❌ [OSS] 获取STS失败: \(error.localizedDescription)")
                    #endif
                    completion(nil)
                case .finished:
                    break
                }
            }, receiveValue: { payload in
                #if DEBUG
                print("✅ [OSS] STS凭证获取成功")
                print("   ├─ AccessKeyId: \(payload.AccessKeyId ?? "nil")")
                print("   ├─ BucketName: \(payload.BucketName ?? "nil")")
                print("   ├─ Endpoint: \(payload.Endpoint ?? "nil")")
                print("   └─ dir: \(payload.dir ?? "nil")")
                #endif
                let sts = STSData(
                    accessKeyId: payload.AccessKeyId ?? "",
                    accessKeySecret: payload.AccessKeySecret ?? "",
                    securityToken: payload.SecurityToken ?? "",
                    expiration: payload.Expiration ?? "",
                    bucketName: payload.BucketName ?? "",
                    endpoint: payload.Endpoint ?? "",
                    dir: payload.dir ?? "",
                    statusCode: payload.StatusCode ?? 200
                )
                completion(sts)
            })
            .store(in: &cancellables)
    }
    
    /// 步骤2：使用STS上传到OSS
    /// - Parameters:
    ///   - sts: STS凭证
    ///   - filePaths: 要上传的文件路径数组
    ///   - completion: 完成回调，返回上传成功的文件名数组
    static func uploadToOSS(sts: STSData, filePaths: [String], completion: @escaping ([String]?) -> Void) {
        var uploadedKeys: [String] = []
        let group = DispatchGroup()
        
        for filePath in filePaths {
            group.enter()
            uploadSingleFile(sts: sts, filePath: filePath) { key in
                if let key = key {
                    uploadedKeys.append(key)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // 如果有任何一个上传失败，返回 nil
            if uploadedKeys.count == filePaths.count {
                completion(uploadedKeys)
            } else {
                completion(nil)
            }
        }
    }
    
    /// 上传单个文件到OSS
    private static func uploadSingleFile(sts: STSData, filePath: String, completion: @escaping (String?) -> Void) {
        #if DEBUG
        print("📤 [OSS] 开始上传文件: \(filePath)")
        #endif
        
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            #if DEBUG
            print("❌ [OSS] 无法读取文件: \(filePath)")
            #endif
            completion(nil)
            return
        }
        
        #if DEBUG
        print("📦 [OSS] 文件大小: \(fileData.count) bytes")
        #endif
        
        // 生成文件路径
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())
        let randomStr = getRandom(length: 12)
        let fileType = getFileType(path: filePath)
        let key = "\(sts.dir)/\(dateStr)\(randomStr).\(fileType)"
        
        #if DEBUG
        print("🔑 [OSS] 生成的 key: \(key)")
        print("🔗 [OSS] 上传地址: https://\(sts.bucketName).\(sts.endpoint)")
        #endif
        
        // 构造 policy
        let policyText = """
        {"expiration": "\(sts.expiration)","conditions": [{"bucket": "\(sts.bucketName)"},["content-length-range", 0, 1048576000]]}
        """
        
        // 计算签名
        let signature = signPolicy(policyText: policyText, accessKeySecret: sts.accessKeySecret)
        let policyBase64 = base64Encode(string: policyText)
        
        // 上传URL
        let url = "https://\(sts.bucketName).\(sts.endpoint)"
        
        // 使用 Alamofire 上传
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(key.data(using: .utf8)!, withName: "key")
            multipartFormData.append(policyBase64.data(using: .utf8)!, withName: "policy")
            multipartFormData.append(sts.accessKeyId.data(using: .utf8)!, withName: "OSSAccessKeyId")
            multipartFormData.append("\(sts.statusCode)".data(using: .utf8)!, withName: "success_action_status")
            multipartFormData.append(signature.data(using: .utf8)!, withName: "signature")
            multipartFormData.append(sts.securityToken.data(using: .utf8)!, withName: "x-oss-security-token")
            multipartFormData.append("multipart/form-data".data(using: .utf8)!, withName: "contentType")
            multipartFormData.append(fileData, withName: "file", fileName: (filePath as NSString).lastPathComponent, mimeType: "application/octet-stream")
        }, to: url)
        .validate(statusCode: 200..<300)
        .response { response in
            #if DEBUG
            print("📡 [OSS] 上传响应: statusCode=\(response.response?.statusCode ?? -1)")
            if let data = response.data, let str = String(data: data, encoding: .utf8) {
                print("📝 [OSS] 响应内容: \(str)")
            }
            #endif
            
            switch response.result {
            case .success:
                #if DEBUG
                print("✅ [OSS] 上传成功: \(key)")
                #endif
                completion(key)
            case .failure(let error):
                #if DEBUG
                print("❌ [OSS] 上传失败: \(error.localizedDescription)")
                if let underlyingError = error.underlyingError {
                    print("   底层错误: \(underlyingError.localizedDescription)")
                }
                #endif
                completion(nil)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取文件后缀
    private static func getFileType(path: String) -> String {
        let array = path.components(separatedBy: ".")
        return array.last ?? ""
    }
    
    /// Base64 编码
    private static func base64Encode(string: String) -> String {
        let data = string.data(using: .utf8)!
        return data.base64EncodedString()
    }
    
    /// 计算 OSS 签名 (HMAC-SHA1)
    private static func signPolicy(policyText: String, accessKeySecret: String) -> String {
        // 先将 policy 进行 base64 编码
        let policyBase64 = base64Encode(string: policyText)
        // 对 base64 后的 policy 计算 HMAC-SHA1
        let key = SymmetricKey(data: accessKeySecret.data(using: .utf8)!)
        let signature = HMAC<Insecure.SHA1>.authenticationCode(
            for: policyBase64.data(using: .utf8)!,
            using: key
        )
        return Data(signature).base64EncodedString()
    }
    
    /// 生成随机字符串
    private static func getRandom(length: Int) -> String {
        let alphabet = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"
        var result = ""
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<alphabet.count)
            let index = alphabet.index(alphabet.startIndex, offsetBy: randomIndex)
            result.append(alphabet[index])
        }
        return result
    }
}