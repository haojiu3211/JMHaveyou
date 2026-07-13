//
//  CacheManager.swift
//  haveseeyou
//
//  缓存管理器 - 计算和清理应用缓存
//

import Foundation
import UIKit
import WebKit

final class CacheManager {
    
    static let shared = CacheManager()
    
    private init() {}
    
    // MARK: - 计算缓存大小
    
    /// 计算总缓存大小（返回格式化的字符串，如 "14.5M"）
    func calculateCacheSize() -> String {
        let cacheSize = getCacheSizeInBytes()
        return formatBytes(cacheSize)
    }
    
    /// 获取缓存大小（字节）
    private func getCacheSizeInBytes() -> Int64 {
        var totalSize: Int64 = 0
        
        // 1. 计算 Library/Caches 目录大小
        if let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            totalSize += folderSize(atPath: cachesPath)
        }
        
        // 2. 计算 tmp 目录大小
        let tmpPath = NSTemporaryDirectory()
        totalSize += folderSize(atPath: tmpPath)
        
        // 3. URLCache 大小（网络请求缓存）
        totalSize += Int64(URLCache.shared.currentDiskUsage)
        
        return totalSize
    }
    
    /// 计算文件夹大小
    private func folderSize(atPath path: String) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return 0
        }
        
        for case let fileName as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(fileName)
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            } catch {
                // 忽略无法访问的文件
                continue
            }
        }
        
        return totalSize
    }
    
    /// 格式化字节大小
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        
        // 如果小于 1KB，显示 0KB
        if bytes < 1024 {
            return "0KB"
        }
        
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - 清理缓存
    
    /// 清理所有缓存（异步执行）
    func clearCache(completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var success = true
            var clearedSize: Int64 = 0
            
            // 1. 清理 Library/Caches 目录（保留目录本身）
            if let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
                let size = self.folderSize(atPath: cachesPath)
                if self.clearFolder(atPath: cachesPath) {
                    clearedSize += size
                } else {
                    success = false
                }
            }
            
            // 2. 清理 tmp 目录
            let tmpPath = NSTemporaryDirectory()
            let tmpSize = self.folderSize(atPath: tmpPath)
            if self.clearFolder(atPath: tmpPath) {
                clearedSize += tmpSize
            } else {
                success = false
            }
            
            // 3. 清理 URLCache（网络请求缓存）
            let urlCacheSize = Int64(URLCache.shared.currentDiskUsage)
            URLCache.shared.removeAllCachedResponses()
            clearedSize += urlCacheSize
            
            // 4. 清理图片缓存（如果使用了 Kingfisher 或 SDWebImage）
            self.clearImageCache()
            
            // 5. 清理 WebView 缓存
            self.clearWebViewCache()
            
            let message = self.formatBytes(clearedSize)
            
            DispatchQueue.main.async {
                completion(success, message)
            }
        }
    }
    
    /// 清理文件夹内容（保留文件夹本身）
    private func clearFolder(atPath path: String) -> Bool {
        let fileManager = FileManager.default
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            return false
        }
        
        var allSuccess = true
        
        for fileName in contents {
            let filePath = (path as NSString).appendingPathComponent(fileName)
            
            do {
                try fileManager.removeItem(atPath: filePath)
            } catch {
                print("清理失败: \(filePath), 错误: \(error)")
                allSuccess = false
            }
        }
        
        return allSuccess
    }
    
    /// 清理图片缓存
    private func clearImageCache() {
        // 如果使用了 Kingfisher
        // ImageCache.default.clearCache()
        
        // 如果使用了 SDWebImage
        // SDImageCache.shared.clearDisk()
        // SDImageCache.shared.clearMemory()
    }
    
    /// 清理 WebView 缓存
    private func clearWebViewCache() {
        if #available(iOS 9.0, *) {
            let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            let dateFrom = Date(timeIntervalSince1970: 0)
//            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) { }
        }
    }
}
