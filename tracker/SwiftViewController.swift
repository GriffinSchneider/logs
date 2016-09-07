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

let SPACING: CGFloat = 5.0
let SECTION_INSETS = UIEdgeInsets(top: 30, left: 10, bottom: 0, right: 10)
let BUTTON_INSETS = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

enum SectionValue: IdentifiableType {
    case occurrence(String)
    case activeState(SEvent)
    case state(SStateSchema, isActive: Bool)
    case reading(String)
    
    var identity: Int {
        switch self {
        case .occurrence(let o):
            return o.hashValue
        case .activeState(let e):
            return e.hashValue
        case .state(let (s, isActive)):
            return s.hashValue // ^ isActive.hashValue
        case .reading(let r):
            return r.hashValue
        }
    }
}
func ==(lhs: SectionValue, rhs: SectionValue) -> Bool {
    switch (lhs, rhs) {
    case (.occurrence(let lhs), .occurrence(let rhs)):
        return lhs == rhs
    case (.activeState(let lhs), .activeState(let rhs)):
        return lhs == rhs
    case (.state(let (lhs, lia)), .state(let (rhs, ria))):
        return lhs == rhs // && lia == ria
    case (.reading(let lhs), .reading(let rhs)):
        return lhs == rhs
    default:
        return true
    }
}
extension SectionValue: Equatable { }

struct SectionOfCustomData: AnimatableSectionModelType {
    var items: [Item]
    typealias Item = SectionValue
    let identity: Int
    init(items: [Item], identity: Int) {
        self.identity = identity
        self.items = items
    }
    init(original: SectionOfCustomData, items: [Item]) {
        self = original
        self.items = items
    }
}

class SwiftViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.flatNavyBlueColorDark()
        
        let fl = UICollectionViewFlowLayout()
        fl.estimatedItemSize = CGSizeMake(30, 30)
        fl.sectionInset = SECTION_INSETS
        fl.scrollDirection = .Vertical;
        fl.minimumInteritemSpacing = SPACING
        fl.minimumLineSpacing = 5
        
        let collectionView = view.addSubview(
            UICollectionView(frame: CGRectZero, collectionViewLayout: fl)
        ) { v, make in
            v.delaysContentTouches = false
            v.backgroundColor = UIColor.flatNavyBlueColorDark()
            v.registerClass(ButtonCollectionViewCell.self, forCellWithReuseIdentifier: "id")
            make.edges.equalTo(v.superview!)
        }
        
        let dataSource = RxCollectionViewSectionedAnimatedDataSource<SectionOfCustomData>()
        
        dataSource.configureCell = { ds, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("id", forIndexPath: indexPath) as! ButtonCollectionViewCell
            cell.setup(UIEdgeInsetsInsetRect(collectionView.bounds, SECTION_INSETS))
            cell.update(item)
            return cell
        }
        
        Observable
            .combineLatest(SSyncManager.data.asObservable(), SSyncManager.schema.asObservable()) { ($0, $1) }
            .map { t -> [SectionOfCustomData] in
                let data = t.0, schema = t.1
                let active = data.activeStates()
                return [
                    SectionOfCustomData(items: schema.occurrences.map(SectionValue.occurrence), identity: 0),
                    SectionOfCustomData(items: active.map(SectionValue.activeState), identity: 1),
                    SectionOfCustomData(items: schema.states.map { s in
                        SectionValue.state(s, isActive: active.contains { a in
                            s.name == a.name
                        })
                    }, identity: 2),
                    SectionOfCustomData(items: schema.readings.map(SectionValue.reading), identity: 3),
                ]
            }
            .debug("refresh")
            .bindTo(collectionView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)
        
        collectionView
            .rx_modelSelected(SectionValue)
            .map { v in
                switch v {
                case .occurrence(let o):
                    return SEvent(
                        name: o,
                        date: NSDate(),
                        type: .Occurrence
                    )
                case .activeState(let s):
                    return SEvent(
                        name: s.name,
                        date: NSDate(),
                        type: .EndState
                    )
                case .state(let (s, isActive)):
                    return SEvent(
                        name: s.name,
                        date: NSDate(),
                        type: isActive ? .EndState : .StartState
                    )
                case .reading(let r):
                    return SEvent(
                        name: "TODO",
                        date: NSDate(),
                        type: SEventType.StartState
                    )
                }
            }
            .subscribeNext { SSyncManager.data.value.events.sortedAppend($0) }
            .addDisposableTo(disposeBag)
    }
}


class ButtonCollectionViewCell: UICollectionViewCell {
    private var label: UILabel!
    private var hasBeenSetup = false
    func setup(superBounds: CGRect) {
        guard !hasBeenSetup else { return }
        hasBeenSetup = true
//        self.translatesAutoresizingMaskIntoConstraints = false
//        contentView.translatesAutoresizingMaskIntoConstraints = false
        label = contentView.addSubview(Style.ButtonLabel) {v, make in
            make.edges.equalTo(v.superview!).inset(BUTTON_INSETS)
            make.width.greaterThanOrEqualTo(40)
        }
//        self.snp_makeConstraints { make in
//            make.size.equalTo(contentView)
//        }
    }
    
    override var highlighted: Bool {
        get { return super.highlighted }
        set {
            super.highlighted = newValue
            label?.backgroundColor = UIColor.randomFlatColor()
        }
    }
    
    func update(v: SectionValue) {
        switch v {
        case .occurrence(let o):
            label.text = o
            label.backgroundColor = UIColor.flatOrangeColorDark()
        case .activeState(let s):
            label.text = "\(s.name) \(formatDuration(NSDate().timeIntervalSinceDate(s.date)))"
            label.backgroundColor = UIColor.flatGreenColorDark()
        case .state(let (s, isActive)):
            label.text = s.icon
            label.backgroundColor = isActive ? UIColor.flatGreenColorDark() : UIColor.flatRedColorDark()
        case .reading(let r):
            label.text = r
            label.backgroundColor = UIColor.flatBlueColorDark()
        }
    }
}
