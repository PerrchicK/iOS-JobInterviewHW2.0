//
//  PredictionsView.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 02/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

protocol PredictionsViewDelegate: class {
    func didScroll(_ predictionsView: PredictionsView)
    func didSelectPrediction(_ predictionsView: PredictionsView, dataIndex: Int)
    func dataTitle(_ predictionsView: PredictionsView, dataIndex: Int) -> String
    func dataCount(_ predictionsView: PredictionsView) -> Int
}

class PredictionsView: UIView, UITableViewDelegate, UITableViewDataSource {
    static let PredictionCellIdentifier: String = "PredictionTableViewCell"
    static let PredictionCellHeight: CGFloat = 50

    weak var delegate: PredictionsViewDelegate?
    lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PredictionsView.PredictionCellIdentifier)
        tableView.backgroundColor = UIColor.clear
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = UIColor.clear
        addSubview(tableView)
        tableView.stretchToSuperViewEdges()
        return tableView
    }()

    func refresh() {
        tableView.reloadData()
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectPrediction(self, dataIndex: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.didScroll(self)
    }

    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PredictionsView.PredictionCellIdentifier, for: indexPath) // Yes, I would like the app to crash when this expression is not retunring an instance. Because it will crash only in development time. The risk is good here.
        cell.textLabel?.text = delegate?.dataTitle(self, dataIndex: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PredictionsView.PredictionCellHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.dataCount(self) ?? 0
    }
}
