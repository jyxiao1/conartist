//
//  ProductTypeListViewController.swift
//  ConArtist
//
//  Created by Cameron Eldridge on 2017-12-23.
//  Copyright © 2017 Cameron Eldridge. All rights reserved.
//

import UIKit
import RxSwift
import SVGKit

class ProductTypeListViewController: UIViewController {
    fileprivate static let ID = "ProductTypeList"
    @IBOutlet weak var navBar: FakeNavBar!
    @IBOutlet weak var productTypeTableView: UITableView!
    @IBOutlet weak var priceField: FancyTextField!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var infoExpandButton: UIButton!
    @IBOutlet weak var infoExpandButtonImage: SVGKImageView!
    @IBOutlet weak var infoViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteLabel: UILabel!

    fileprivate let disposeBag = DisposeBag()
    fileprivate let øproductTypes = Variable<[ProductType]>([])
    fileprivate let øproducts = Variable<[Product]>([])
    fileprivate let øprices = Variable<[Price]>([])
    fileprivate let øselected = Variable<[Product]>([])

    fileprivate var convention: Convention!
    fileprivate let results = PublishSubject<([Product], Money, String)>()

    fileprivate let øexpectedInfoViewBottomConstraintConstant = Variable<CGFloat>(-150)
}

// MARK: - Lifecycle
extension ProductTypeListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalization()
        setupSubscriptions()
        infoExpandButtonImage.image = ConArtist.Images.SVG.Chevron.Down
        noteLabel.font = noteLabel.font.usingFeatures([.smallCaps])
        priceField.format = { Money.parse(as: ConArtist.model.settings.value.currency, $0)?.toString() ?? $0 }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAdjustingForKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Localization
extension ProductTypeListViewController {
    fileprivate func setupLocalization() {
        navBar.leftButtonTitle = "Cancel"¡
        navBar.rightButtonTitle = "Save"¡
        priceField.title = "Price"¡
        priceField.placeholder = "Price"¡
        noteLabel.text = "Note"¡
    }
}

// MARK: - Subscriptions
extension ProductTypeListViewController {
    fileprivate func setupSubscriptions() {
        øproductTypes.asDriver()
            .drive(onNext: { [productTypeTableView] _ in productTypeTableView?.reloadData() })
            .disposed(by: disposeBag)

        navBar.leftButton.rx.tap
            .subscribe(onNext: { _ in ConArtist.model.navigate(back: 1) })
            .disposed(by: disposeBag)

        let ømoney = priceField.rx.text
            .map { [weak self] text -> Money? in
                guard let text = text, !text.isEmpty else { return self?.calculatePrice(self!.øselected.value) }
                return Money.parse(as: ConArtist.model.settings.value.currency, text)
            }

        Observable
            .combineLatest(
                øselected.asObservable().map { !$0.isEmpty },
                ømoney.map { $0 != nil }
            )
            .map { $0 && $1 }
            .bind(to: navBar.rightButton.rx.isEnabled)
            .disposed(by: disposeBag)

        navBar.rightButton.rx.tap
            .withLatestFrom(
                Observable.combineLatest(
                    øselected.asObservable(),
                    ømoney.filterMap(identity),
                    infoTextView.rx.text.map { $0 ?? "" }
                )
            )
            .subscribe(onNext: { [results] products, money, note in
                results.onNext((products, money, note))
                ConArtist.model.navigate(back: 1)
            })
            .disposed(by: disposeBag)

        øselected
            .asObservable()
            .map(calculatePrice)
            .map { [placeholder = priceField.placeholder] money in
                if money == Money.zero { return placeholder }
                return money.toString()
            }
            .asDriver(onErrorJustReturn: priceField.placeholder)
            .drive(onNext: { [priceField] text in priceField?.placeholder = text })
            .disposed(by: disposeBag)

        øselected
            .asObservable()
            .subscribe(onNext: { [productTypeTableView] _ in productTypeTableView?.reloadData() })
            .disposed(by: disposeBag)

        infoExpandButton.rx.tap
            .subscribe(onNext: { [view, øexpectedInfoViewBottomConstraintConstant] _ in
                view?.endEditing(true)
                øexpectedInfoViewBottomConstraintConstant.value = øexpectedInfoViewBottomConstraintConstant.value >= 0 ? -150 : 0
            })
            .disposed(by: disposeBag)

        øexpectedInfoViewBottomConstraintConstant
            .asObservable()
            .subscribe(onNext: { [view, infoViewBottomConstraint, infoExpandButtonImage] amount in
                infoViewBottomConstraint?.constant = amount
                infoExpandButtonImage?.image = amount == 0 ? ConArtist.Images.SVG.Chevron.Down : ConArtist.Images.SVG.Chevron.Up
                UIView.animate(withDuration: 0.25) { view?.layoutIfNeeded() }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Keyboard handling
extension ProductTypeListViewController {
    fileprivate func startAdjustingForKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        let keyboardScreenEndFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == Notification.Name.UIKeyboardWillHide {
            infoViewBottomConstraint.constant = øexpectedInfoViewBottomConstraintConstant.value
        } else {
            infoViewBottomConstraint.constant = øexpectedInfoViewBottomConstraintConstant.value + keyboardViewEndFrame.height
        }
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

// MARK: - UITableViewDataSource
extension ProductTypeListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? øproductTypes.value.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductTypeTableViewCell.ID, for: indexPath) as! ProductTypeTableViewCell
        if indexPath.row < øproductTypes.value.count {
            let item = øproductTypes.value[indexPath.row]
            cell.fill(with: item, selected: øselected.value)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ProductTypeListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let productType = øproductTypes.value[indexPath.row]
        let products = øproducts.value.filter { $0.typeId == productType.id }
        ProductListViewController.show(for: productType, and: products, selected: øselected)
    }
}

// MARK: - Price calculation
extension ProductTypeListViewController {
    enum Key: Equatable, Hashable {
        case Product(Int)
        case ProductType(Int)

        static func ==(a: Key, b: Key) -> Bool {
            switch (a, b) {
            case (.Product(let a), .Product(let b)),
                 (.ProductType(let a), .ProductType(let b)): return a == b
            default: return false
            }
        }

        var hashValue: Int {
            switch self {
            case .Product(let id): return id
            case .ProductType(let id): return -id
            }
        }
    }

    fileprivate func calculatePrice(_ selected: [Product]) -> Money {
        let prices = øprices.value
        guard prices.count > 0 else { return Money.zero }
        let matters = prices.filterMap { $0.productId }
        let items: [Key: Int] = selected.reduce([:]) { counts, product in
            let id: Key = matters.contains(product.id) ? .Product(product.id) : .ProductType(product.typeId)
            var updated = counts
            updated[id] = 1 + (counts[id] ?? 0)
            return updated
        }
        return items.reduce(Money.zero) { price, item in
            let key = item.key
            var count = item.value
            let relevantPrices = prices
                .filter { price in price.productId.map(Key.Product).map((==) <- key) ?? (Key.ProductType(price.typeId) == key) }
                .sorted { $0.quantity < $1.quantity }
            var newPrice = price
            while count > 0 {
                let price = relevantPrices
                    .reduce(nil) { best, price -> Price? in
                        if price.quantity <= count && price.quantity > best?.quantity ?? 0 {
                            return price
                        } else {
                            return best
                        }
                }
                guard let bestPrice = price else { return newPrice }
                count -= bestPrice.quantity
                newPrice = newPrice + bestPrice.price
            }
            return newPrice
        }
    }
}

// MARK: Navigation
extension ProductTypeListViewController {
    class func show(for convention: Convention) -> Observable<([Product], Money, String)> {
        let controller: ProductTypeListViewController = ProductTypeListViewController.instantiate(withId: ProductTypeListViewController.ID)

        controller.convention = convention
        convention.products
            .bind(to: controller.øproducts)
            .disposed(by: controller.disposeBag)
        convention.productTypes
            .bind(to: controller.øproductTypes)
            .disposed(by: controller.disposeBag)
        convention.prices
            .bind(to: controller.øprices)
            .disposed(by: controller.disposeBag)

        ConArtist.model.navigate(present: controller)
        return controller.results.asObservable()
    }
}
