//
//  YPLibraryView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import Photos

internal final class YPLibraryView: UIView {

    // MARK: - Public vars

    internal let assetZoomableViewMinimalVisibleHeight: CGFloat  = 50
    internal var assetViewContainerConstraintTop: NSLayoutConstraint?
    internal let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.backgroundColor = YPConfig.colors.libraryScreenBackgroundColor
        v.collectionViewLayout = layout
        v.showsHorizontalScrollIndicator = false
        v.alwaysBounceVertical = true
        return v
    }()
    internal lazy var assetViewContainer: YPAssetViewContainer = {
        let v = YPAssetViewContainer(frame: .zero, zoomableView: assetZoomableView)
        v.accessibilityIdentifier = "assetViewContainer"
        return v
    }()
    internal let assetZoomableView: YPAssetZoomableView = {
        let v = YPAssetZoomableView(frame: .zero)
        v.accessibilityIdentifier = "assetZoomableView"
        return v
    }()
    /// At the bottom there is a view that is visible when selected a limit of items with multiple selection
    internal let maxNumberWarningView: UIView = {
        let v = UIView()
        v.backgroundColor = .ypSecondarySystemBackground
        v.isHidden = true
        return v
    }()
    internal let maxNumberWarningLabel: UILabel = {
        let v = UILabel()
        v.font = YPConfig.fonts.libaryWarningFont
        return v
    }()

    // MARK: - Private vars

    private let line: UIView = {
        let v = UIView()
        v.backgroundColor = .ypSystemBackground
        return v
    }()
    /// When video is processing this bar appears
    private let progressView: UIProgressView = {
        let v = UIProgressView()
        v.progressViewStyle = .bar
        v.trackTintColor = YPConfig.colors.progressBarTrackColor
        v.progressTintColor = YPConfig.colors.progressBarCompletedColor ?? YPConfig.colors.tintColor
        v.isHidden = true
        v.isUserInteractionEnabled = false
        return v
    }()
    private let collectionContainerView: UIView = {
        let v = UIView()
        v.accessibilityIdentifier = "collectionContainerView"
        return v
    }()
    private var shouldShowLoader = false {
        didSet {
            DispatchQueue.main.async {
                self.assetViewContainer.squareCropButton.isEnabled = !self.shouldShowLoader
                self.assetViewContainer.multipleSelectionButton.isEnabled = !self.shouldShowLoader
                self.assetViewContainer.spinnerIsShown = self.shouldShowLoader
                self.shouldShowLoader ? self.hideOverlayView() : ()
            }
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Only code layout.")
    }

    // MARK: - Public Methods

    // MARK: Overlay view

    func hideOverlayView() {
        assetViewContainer.itemOverlay?.alpha = 0
    }

    // MARK: Loader and progress

    func fadeInLoader() {
        shouldShowLoader = true
        // Only show loader if full res image takes more than 0.5s to load.
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            if self.shouldShowLoader == true {
                UIView.animate(withDuration: 0.2) {
                    self.assetViewContainer.spinnerView.alpha = 1
                }
            }
        }
    }

    func hideLoader() {
        shouldShowLoader = false
        assetViewContainer.spinnerView.alpha = 0
    }

    func updateProgress(_ progress: Float) {
        progressView.isHidden = progress > 0.99 || progress == 0
        progressView.progress = progress
        UIView.animate(withDuration: 0.1, animations: progressView.layoutIfNeeded)
    }

    // MARK: Crop Rect

    func currentCropRect() -> CGRect {
        // When the preview area is hidden, the zoomable view never displays the image,
        // so its contentSize/frame are zero. Returning a full-image rect avoids producing
        // an empty crop rect that would cause downstream image cropping to fail silently
        // (which leaves the Next button stuck in a loading state).
        if YPConfig.library.hidesPreview {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let cropView = assetZoomableView
        let normalizedX = min(1, cropView.contentOffset.x &/ cropView.contentSize.width)
        let normalizedY = min(1, cropView.contentOffset.y &/ cropView.contentSize.height)
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }

    // MARK: Curtain

    func refreshImageCurtainAlpha() {
        let denominator = assetViewContainer.frame.height - assetZoomableViewMinimalVisibleHeight
        guard denominator != 0 else { return }
        let imageCurtainAlpha = abs(assetViewContainerConstraintTop?.constant ?? 0) / denominator
        assetViewContainer.curtain.alpha = imageCurtainAlpha
    }

    func cellSize() -> CGSize {
        var screenWidth = window?.windowScene?.screen.bounds.width ?? 1.0
        let scale = window?.windowScene?.screen.scale ?? 1.0
        if UIDevice.current.userInterfaceIdiom == .pad && YPImagePickerConfiguration.widthOniPad > 0 {
            screenWidth =  YPImagePickerConfiguration.widthOniPad
        }
        let size = screenWidth / 4 * scale
        return CGSize(width: size, height: size)
    }

    // MARK: - Private Methods

    private func setupLayout() {
        subviews(
            collectionContainerView.subviews(
                collectionView
            ),
            line,
            assetViewContainer.subviews(
                assetZoomableView
            ),
            progressView,
            maxNumberWarningView.subviews(
                maxNumberWarningLabel
            )
        )

        if YPConfig.library.hidesPreview {
            // Grid-only mode: hide preview area, make collectionView fill the space
            collectionContainerView.fillContainer()
            collectionView.fillContainer()
            
            // Keep assetViewContainer in hierarchy but hidden (other code references it)
            assetViewContainer.isHidden = true
            assetViewContainer.top(0).fillHorizontally().height(0)
            assetZoomableView.fillContainer()
            
            line.isHidden = true
            line.height(0).fillHorizontally()
            
            progressView.isHidden = true
        } else {
            // Original layout: preview + grid
            collectionContainerView.fillContainer()
            collectionView.fillHorizontally().bottom(0)

            assetViewContainer.Bottom == line.Top
            line.height(1)
            line.fillHorizontally()

            assetViewContainer.top(0).fillHorizontally().heightEqualsWidth()
            self.assetViewContainerConstraintTop = assetViewContainer.topConstraint
            assetZoomableView.fillContainer().heightEqualsWidth()
            assetZoomableView.Bottom == collectionView.Top
            assetViewContainer.sendSubviewToBack(assetZoomableView)

            progressView.height(5).fillHorizontally()
            progressView.Bottom == line.Top
        }

        |maxNumberWarningView|.bottom(0)
        maxNumberWarningView.Top == safeAreaLayoutGuide.Bottom - 40
        maxNumberWarningLabel.centerHorizontally().top(11)
    }
}
