//
//  MultiTextPickerViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-01-03.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import UIKit
import SnapKit
import RaceSyncAPI

typealias ItemsUpdateBlock = (_ item: [String]) -> Void

class MultiTextPickerViewController: UIViewController {

    // MARK: - Public Variables

    public let items: [String]
    public var selectedItems: [String]
    public var itemWithItems: [String: [String]]?
    public var minSelectedItems: Int = 2
    public var maxSelectedItems: Int = 3

    public var didSelectItem: ItemSelectionBlock?
    public var didDeselectItem: ItemSelectionBlock?
    public var didUpdateItems: ItemsUpdateBlock?

    // MARK: - Private Variables

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.register(cellType: FormTableViewCell.self)

        let backgroundView = UIView()
        backgroundView.backgroundColor = Color.gray20
        tableView.backgroundView = backgroundView

        return tableView
    }()

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let cellHeight: CGFloat = 60
    }

    // MARK: - Initialization

    init(with items: [String], selectedItems: [String]) {
        self.items = items
        self.selectedItems = selectedItems
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Layout

    fileprivate func setupLayout() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension MultiTextPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]

        if let withItems = itemWithItems, let subItems = withItems[item] {

            let vc = MultiTextPickerViewController(with: subItems, selectedItems: selectedItems)
            vc.minSelectedItems = 0
            vc.maxSelectedItems = 1
            vc.title = item
            navigationController?.pushViewController(vc, animated: true)

            vc.didDeselectItem = { item in
                self.selectedItems.removeAll { $0 == item }
                self.tableView.reloadData()

                self.didUpdateItems?(self.selectedItems)
            }

            vc.didSelectItem = { item in
                if self.selectedItems.count == self.maxSelectedItems {
                    self.selectedItems.removeFirst()
                }

                self.selectedItems.insert(item, at: self.selectedItems.count)
                self.tableView.reloadData()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.navigationController?.popViewController(animated: true)
                }

                self.didUpdateItems?(self.selectedItems)
            }

        } else if selectedItems.contains(item) {

            guard selectedItems.count != minSelectedItems else { return }
            selectedItems.removeAll { $0 == item }
            tableView.reloadData()

            didDeselectItem?(item)
            didUpdateItems?(selectedItems)

        } else if !selectedItems.contains(item) {

            if selectedItems.count == maxSelectedItems {
                selectedItems.removeFirst()
            }
            selectedItems.insert(item, at: selectedItems.count)
            tableView.reloadData()

            didSelectItem?(item)
            didUpdateItems?(selectedItems)
        }
    }
}

extension MultiTextPickerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIdx: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return formTableViewCell(for: indexPath)
    }

    func formTableViewCell(for indexPath: IndexPath) -> FormTableViewCell {
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FormTableViewCell
        let item = items[indexPath.row]

        cell.textLabel?.text = item
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .none
        cell.accessoryView = nil

        if let withItems = itemWithItems, let subItems = withItems[item] {
            cell.accessoryType = .disclosureIndicator

            let matchingItems = subItems.filter { str1 in
                selectedItems.contains { str2 in
                    str1.contains(str2)
                }
            }
            cell.detailTextLabel?.text = matchingItems.joined(separator: ", ")

        } else if selectedItems.contains(item) {
            let imageView = UIImageView(image: UIImage(named: "icn_cell_checkmark"))
            imageView.tintColor = Color.blue
            cell.accessoryView = imageView
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIdx: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }
}
