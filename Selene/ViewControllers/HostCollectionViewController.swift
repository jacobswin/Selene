//
//  HostCollectionViewController.swift
//  Selene
//
//  Created by True砖家 on 2025/5/28.
//  Copyright 2025 True砖家 @ Bilibili. All rights reserved.
//

import UIKit

@objcMembers
class HostCell: UICollectionViewCell {
#if os(tvOS)
    // Focus the actionable buttons inside the card, not the inert cell.
    override var canBecomeFocused: Bool { false }
#endif
    var cardView: HostCardView?
    private weak var parentVC: UIViewController?

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView?.removeFromSuperview()
        cardView = nil
    }

    private func getHostCardSizeFactor() -> CGFloat {
        let dummyHost = TemporaryHost()
        let dummyCard = HostCardView(host: dummyHost)
        return contentView.bounds.size.height / dummyCard.size.height
    }

    private func viewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }

    private func assignDelegateForHostCard() {
        parentVC = viewController()?.parent
        if let parentVC, parentVC.conforms(to: HostCardActionDelegate.self) {
            cardView?.delegate = parentVC as? HostCardActionDelegate
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        assignDelegateForHostCard()
    }

    @objc(configureWithHost:)
    func configure(with host: TemporaryHost) {
#if os(tvOS)
        clipsToBounds = false
        contentView.clipsToBounds = false
#endif
        if cardView == nil {
            cardView = HostCardView(host: host, andSizeFactor: getHostCardSizeFactor())
            assignDelegateForHostCard()
            if let cardView, cardView.superview == nil {
                contentView.addSubview(cardView)
                NSLayoutConstraint.activate([
                    cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
                ])
            }
        }
    }
}

@objcMembers
class HostCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var interItemMinimumSpacing: CGFloat = 10
    var minimumLineSpacing: CGFloat = 10
    var cellSize: CGSize = .zero
    private(set) var items = NSMutableArray()

    @objc(focusViewForHostUUID:)
    func focusView(forHostUUID uuid: String?) -> UIView? {
        guard items.count > 0 else { return nil }
        let index = (items as? [TemporaryHost])?.firstIndex(where: { $0.uuid == uuid }) ?? min(lastFocusedIndex, items.count - 1)
        let path = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: path, at: .centeredVertically, animated: false)
        collectionView.layoutIfNeeded()
        return (collectionView.cellForItem(at: path) as? HostCell)?.cardView?.preferredActionView
    }
    private var lastFocusedIndex = 0
    override func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let path = context.nextFocusedIndexPath { lastFocusedIndex = path.item }
    }

    private var collectionViewHeightConstraint: NSLayoutConstraint?
    private var superViewBottomConstraint: NSLayoutConstraint?
    private let flowLayout: UICollectionViewFlowLayout
    private var horizontalPadding: CGFloat

    @objc init() {
        let layout = UICollectionViewFlowLayout()
        flowLayout = layout

        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            horizontalPadding = 5
        case .pad:
            fallthrough
        default:
            horizontalPadding = 75
        }

        layout.sectionInset = UIEdgeInsets(top: 7, left: horizontalPadding, bottom: 0, right: horizontalPadding)
        super.init(collectionViewLayout: layout)

        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 50)
        collectionViewHeightConstraint?.isActive = true
    }

    required init?(coder: NSCoder) {
        flowLayout = UICollectionViewFlowLayout()
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            horizontalPadding = 5
        case .pad:
            fallthrough
        default:
            horizontalPadding = 75
        }
        super.init(coder: coder)
    }

    func updateTheme() {
        collectionView.backgroundColor = ThemeManager.hostViewBackgroundColor
        for case let cell as HostCell in collectionView.visibleCells {
            cell.cardView?.updateTheme()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(HostCell.self, forCellWithReuseIdentifier: "HostCell")
#if os(tvOS)
        collectionView.clipsToBounds = false
        collectionView.remembersLastFocusedIndexPath = true
#endif
        collectionView.alwaysBounceVertical = false
        collectionView.showsVerticalScrollIndicator = false
        updateTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
    }

    func addHost(_ host: TemporaryHost) {
        if !items.contains(host) {
            items.add(host)
            collectionView.reloadData()
        }
    }

    func removeHost(_ host: TemporaryHost) {
        if items.contains(host) {
            items.remove(host)
            collectionView.reloadData()
        }
    }

    func removeLastItem() {
        if items.count > 0 {
            items.removeLastObject()
            collectionView.reloadData()
        }
    }

    private func numberOfRowsInCollectionView() -> Int {
        let itemCount = collectionView.numberOfItems(inSection: 0)
        if itemCount == 0 {
            return 0
        }

        var rowYs = Set<NSNumber>()
        for index in 0..<itemCount {
            let indexPath = IndexPath(item: index, section: 0)
            if let attr = flowLayout.layoutAttributesForItem(at: indexPath) {
                let y = attr.frame.minY
                rowYs.insert(NSNumber(value: Double(round(y))))
            }
        }

        return rowYs.count
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        if let superview = view.superview {
            let contentExceedsView = contentHeight > superview.bounds.size.height - view.frame.origin.y
            if contentExceedsView {
                if superViewBottomConstraint == nil {
                    superViewBottomConstraint = view.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor)
                    superViewBottomConstraint?.isActive = true
                }
            } else {
                collectionViewHeightConstraint?.constant = contentHeight
            }
        } else {
            collectionViewHeightConstraint?.constant = contentHeight
        }
        
        if PublicUtils.isTVOS {
            flowLayout.sectionInset = UIEdgeInsets(top: PublicUtils.tvOS26Aavailable ? 43 : 30, left: horizontalPadding, bottom: 0, right: horizontalPadding)
            return
        }

        switch numberOfRowsInCollectionView() {
        case 1:
            flowLayout.sectionInset = UIEdgeInsets(top: 50, left: horizontalPadding, bottom: 0, right: horizontalPadding)
        case 2:
            flowLayout.sectionInset = UIEdgeInsets(top: 17, left: horizontalPadding, bottom: 0, right: horizontalPadding)
        default:
            flowLayout.sectionInset = UIEdgeInsets(top: 10, left: horizontalPadding, bottom: 0, right: horizontalPadding)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HostCell", for: indexPath) as! HostCell
        if let host = items[indexPath.item] as? TemporaryHost {
            cell.configure(with: host)
        }
        if #available(iOS 13.0, *) {
            applyControllerNavigationHighlight(to: cell, highlighted: indexPath == controllerNavigationSelectedIndexPath)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        cellSize
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        interItemMinimumSpacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        minimumLineSpacing
    }
}
