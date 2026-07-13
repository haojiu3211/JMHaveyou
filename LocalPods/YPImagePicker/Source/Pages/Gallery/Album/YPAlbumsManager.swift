//
//  YPAlbumsManager.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 20/07/2017.
//  Copyright © 2017 Yummypets. All rights reserved.
//

import Foundation
import Photos
import UIKit

class YPAlbumsManager {
    
    private var cachedAlbums: [YPAlbum]?
    
    /// 系统相册英文名称到中文的映射
    private let albumNameMapping: [String: String] = [
        "Recents": "最近项目",
        "Favorites": "个人收藏",
        "Selfies": "自拍",
        "Live Photos": "实况照片",
        "Screenshots": "屏幕快照",
        "Recently Saved": "最近添加",
        "Camera Roll": "相机胶卷",
        "Panoramas": "全景照片",
        "Videos": "视频",
        "Bursts": "连拍快照",
        "Time-lapse": "延时摄影",
        "Slow-mo": "慢动作",
        "Portrait": "人像",
        "Albums": "相册",
        "All Photos": "所有照片"
    ]
    
    func fetchAlbums() -> [YPAlbum] {
        if let cachedAlbums = cachedAlbums {
            return cachedAlbums
        }
        
        var albums = [YPAlbum]()
        let options = PHFetchOptions()
        
        let smartAlbumsResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                        subtype: .any,
                                                                        options: options)
        let albumsResult = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                   subtype: .any,
                                                                   options: options)
        for result in [smartAlbumsResult, albumsResult] {
            result.enumerateObjects({ assetCollection, _, _ in
                var album = YPAlbum()
                let originalTitle = assetCollection.localizedTitle ?? ""
                // 将系统相册的英文名称映射为中文
                album.title = self.localizedAlbumTitle(originalTitle)
                album.numberOfItems = self.mediaCountFor(collection: assetCollection)
                if album.numberOfItems > 0 {
                    let r = PHAsset.fetchKeyAssets(in: assetCollection, options: nil)
                    if let first = r?.firstObject {
                        let windowScene = UIApplication.safeFirstWindowScene
                        let deviceScale = windowScene?.screen.scale ?? 1.0
                        let targetSize = CGSize(width: 78 * deviceScale, height: 78 * deviceScale)
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        options.deliveryMode = .opportunistic
                        PHImageManager.default().requestImage(for: first,
                                                              targetSize: targetSize,
                                                              contentMode: .aspectFill,
                                                              options: options,
                                                              resultHandler: { image, _ in
                                                                album.thumbnail = image
                        })
                    }
                    album.collection = assetCollection
                    
                    if YPConfig.library.mediaType == .photo {
                        if !(assetCollection.assetCollectionSubtype == .smartAlbumSlomoVideos
                            || assetCollection.assetCollectionSubtype == .smartAlbumVideos) {
                            albums.append(album)
                        }
                    } else {
                        albums.append(album)
                    }
                }
            })
        }
        cachedAlbums = albums
        return albums
    }
    
    /// 将系统相册名称本地化（英文转中文）
    private func localizedAlbumTitle(_ title: String) -> String {
        return albumNameMapping[title] ?? title
    }
    
    func mediaCountFor(collection: PHAssetCollection) -> Int {
        let options = PHFetchOptions()
        options.predicate = YPConfig.library.mediaType.predicate()
        let result = PHAsset.fetchAssets(in: collection, options: options)
        return result.count
    }
    
}

extension YPlibraryMediaType {
    func predicate() -> NSPredicate {
        switch self {
        case .photo:
            return NSPredicate(format: "mediaType = %d",
                               PHAssetMediaType.image.rawValue)
        case .video:
            return NSPredicate(format: "mediaType = %d",
                               PHAssetMediaType.video.rawValue)
        case .photoAndVideo:
            return NSPredicate(format: "mediaType = %d || mediaType = %d",
                               PHAssetMediaType.image.rawValue,
                               PHAssetMediaType.video.rawValue)
        }
    }
}
