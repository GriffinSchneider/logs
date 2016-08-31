//
//  SwiftViewController.swift
//  tracker
//
//  Created by Griffin on 8/25/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import DRYUI
import SnapKit

let SPACING: CGFloat = 5.0
let SECTION_INSETS = UIEdgeInsets(top: 30, left: 10, bottom: 0, right: 10)
let BUTTON_INSETS = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

enum SectionValue {
    case occurrence(String)
    case activeState(SEvent)
    case state(SStateSchema)
    case reading(String)
}

struct SectionOfCustomData {
    var items: [Item]
}
extension SectionOfCustomData: SectionModelType {
    typealias Item = SectionValue
    
    init(original: SectionOfCustomData, items: [Item]) {
        self = original
        self.items = items
    } 
}

class SwiftViewController: UIViewController {
    
    override func loadView() {
        view = UIView()
    }
    
    override func viewDidLoad() {
//        guard DBSession.sharedSession().isLinked() else {
//            dispatch_async(dispatch_get_main_queue()) {
//                DBSession.sharedSession().linkFromController(self)
//            }
//            return
//        }
        
        let schema = SSyncManager.loadFromDisk()
        
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        let fl = UICollectionViewFlowLayout()
        fl.estimatedItemSize = CGSizeMake(10, 10)
        fl.sectionInset = SECTION_INSETS
        fl.scrollDirection = .Vertical;
        fl.minimumInteritemSpacing = SPACING
        fl.minimumLineSpacing = 5
        let cv = view.addSubview(UICollectionView(frame: CGRectZero, collectionViewLayout: fl)) { v, make in
            v.delaysContentTouches = false
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            v.registerClass(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: "id")
            make.edges.equalTo(v.superview!)
        }
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfCustomData>()
        
        dataSource.configureCell = { ds, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("id", forIndexPath: indexPath) as! ButtonCollectionViewCell
            cell.setup(UIEdgeInsetsInsetRect(collectionView.bounds, SECTION_INSETS))
            cell.update(item)
            return cell
        }
        
        let sections = [
            SectionOfCustomData(items: schema.occurrences.map(SectionValue.occurrence)),
//            SectionOfCustomData(items: SyncManager.i().data().activeStates().map(SectionValue.activeStates)),
            SectionOfCustomData(items: schema.states.map(SectionValue.state)),
            SectionOfCustomData(items: schema.readings.map(SectionValue.reading)),
        ]
        
        _ = Observable.just(sections)
            .takeUntil(rx_deallocated)
            .bindTo(cv.rx_itemsWithDataSource(dataSource))
    }
}

extension ButtonCollectionViewCell {
    
    func update(v: SectionValue) {
        switch v {
        case .occurrence(let o):
            label.text = o
            label.backgroundColor = UIColor.flatOrangeColorDark()
        case .activeState(let s):
            label.text = "\(s.name) \(formatDuration(NSDate().timeIntervalSinceDate(s.date)))"
            label.backgroundColor = UIColor.flatGreenColorDark()
        case .state(let s):
            label.text = s.icon
            label.backgroundColor =
//                SyncManager.i().data().activeStates().contains { $0.name == state.name } ?
//                    UIColor.flatGreenColorDark() :
                UIColor.flatRedColorDark()
        case .reading(let r):
            label.text = r
            label.backgroundColor = UIColor.flatBlueColorDark()
        }
        
    }
}

class ButtonCollectionViewCell: UICollectionViewCell {
    
    private var label: UILabel!
    private var hasBeenSetup = false
    func setup(superBounds: CGRect) {
        guard !hasBeenSetup else { return }
        hasBeenSetup = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        label = contentView.addSubview(Style.ButtonLabel) {v, make in
            make.edges.equalTo(v.superview!).inset(BUTTON_INSETS)
            make.width.greaterThanOrEqualTo(40)
        }
    }
    
    override var highlighted: Bool {
        get { return super.highlighted }
        set {
            super.highlighted = newValue
            label?.backgroundColor = UIColor.randomFlatColor()
        }
    }
}
