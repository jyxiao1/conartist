//
//  RecordListViewController.swift
//  ConArtist
//
//  Created by Cameron Eldridge on 2017-12-23.
//  Copyright © 2017 Cameron Eldridge. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class RecordListViewController : ConArtistViewController {
    @IBOutlet weak var recordsTableView: UITableView!
    @IBOutlet weak var navBar: FakeNavBar!

    fileprivate var convention: Convention!
    fileprivate let records = BehaviorRelay<[Record]>(value: [])
    fileprivate let products = BehaviorRelay<[Product]>(value: [])

    fileprivate var after: Date?
    fileprivate var before: Date?

    fileprivate let disposeBag = DisposeBag()

    fileprivate let refreshControl = UIRefreshControl()
}

// MARK: - Lifecycle
extension RecordListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        convention.records
            .map { [after, before] records in records.filter { record in (after.map { record.time >= $0 } ?? true) && (before.map { record.time <= $0 } ?? true) } }
            .bind(to: records)
            .disposed(by: disposeBag)

        convention.products
            .bind(to: products)
            .disposed(by: disposeBag)

        navBar.leftButton.rx.tap
            .subscribe(onNext: { ConArtist.model.navigate(back: 1) })
            .disposed(by: disposeBag)

        Observable.merge(products.asObservable().discard(), records.asObservable().discard())
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [recordsTableView] in recordsTableView?.reloadData() })
            .disposed(by: disposeBag)

        navBar.title = convention.name
        navBar.subtitle = after?.toString("MMM. d, yyyy"¡)

        setupRefreshControl()
    }

    private func setupRefreshControl() {
        recordsTableView.refreshControl = refreshControl
        refreshControl.rx.controlEvent([.valueChanged])
            .flatMapLatest { [convention] _ in convention!.fill(true) }
            .subscribe(onNext: { [refreshControl] in refreshControl.endRefreshing() })
            .disposed(by: disposeBag)
    }
}

// MARK: - UITableViewDataSource
extension RecordListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? records.value.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordTableViewCell.ID, for: indexPath) as! RecordTableViewCell
        if let record = records.value.nth(indexPath.row) {
            cell.setup(for: record, with: products.value)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension RecordListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let record = records.value.nth(indexPath.row) {
            RecordDetailsOverlayViewController.show(for: record, in: convention, after: after)
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isHighlighted = true
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isHighlighted = false
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let record = records.value[indexPath.row]
        var actions: [UIContextualAction] = []
        if !convention.isEnded {
            let deleteAction = UIContextualAction(style: .normal, title: "Delete"¡) { [convention] _, _, reset in
                let _ = convention?.deleteRecord(record).subscribe()
                reset(true)
            }
            deleteAction.backgroundColor = .warn
            actions.append(deleteAction)
        }
        let config = UISwipeActionsConfiguration(actions: actions)
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}

// MARK: - Navigation
extension RecordListViewController: ViewControllerNavigation {
    static let Storyboard: Storyboard = .records
    static let ID = "RecordList"

    static func show(for convention: Convention, after: Date, before: Date) {
        let controller = instantiate()
        controller.convention = convention
        controller.after = after
        controller.before = before

        ConArtist.model.navigate(push: controller)
    }
}
