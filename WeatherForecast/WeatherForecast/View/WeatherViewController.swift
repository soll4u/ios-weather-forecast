//
//  WeatherForecast - WeatherViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

class WeatherViewController: UIViewController {
    
    private var currentWeatherViewModel = CurrentWeatherViewModel()
    private var fiveDayListViewModel = FiveDayWeatherListViewModel()
    private var weatherTableView = UITableView()
    private let headerView = CurrentWeatherTableViewHeaderView()
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(updateViewModels), for: .valueChanged)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initBackgroundView()
        updateViewModels()
        configureTableView()
        initTableHeaderView()
    }
    
    private func initBackgroundView() {
        let width = view.bounds.size.width
        let height = view.bounds.size.height
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        imageView.image = UIImage(named: "seoul.jpeg")
        imageView.mask = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        imageView.mask?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        
        view.addSubview(imageView)
    }
    
    @objc private func updateViewModels() {
        let refreshGroup = DispatchGroup()
        
        currentWeatherViewModel.mapCurrentData()
        currentWeatherViewModel.reloadTableView = {
            DispatchQueue.main.async {
                self.updateTableHeaderView()
                DispatchQueue.global().async(group: refreshGroup) {
                    self.reloadTableView()
                }
            }
        }
        fiveDayListViewModel.mapFiveDayData()
        fiveDayListViewModel.reloadTableView = {
            DispatchQueue.global().async(group: refreshGroup) {
                self.reloadTableView()
            }
        }
        refreshGroup.notify(queue: .main) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    private func configureTableView() {
        weatherTableView.delegate = self
        weatherTableView.dataSource = self
        view.addSubview(weatherTableView)
        weatherTableView.register(WeatherTableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        
        weatherTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            weatherTableView.topAnchor.constraint(equalTo: view.topAnchor),
            weatherTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            weatherTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            weatherTableView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
        weatherTableView.backgroundColor = nil
        weatherTableView.refreshControl = refreshControl
    }
    
    private func initTableHeaderView() {
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 100)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        weatherTableView.tableHeaderView = headerView
    }
    
    private func updateTableHeaderView() {
        headerView.configureContents(
            image: currentWeatherViewModel.weatherImage,
            address: currentWeatherViewModel.address,
            minMaxTemperature: currentWeatherViewModel.minMaxTamperature,
            temperature: currentWeatherViewModel.currentTemperature
        )
    }
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            self.weatherTableView.reloadData()
        }
    }
}

extension WeatherViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fiveDayListViewModel.numberOfRowInSection
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = weatherTableView.dequeueReusableCell(withIdentifier: "cell") as? WeatherTableViewCell else {
            return WeatherTableViewCell()
        }
        let viewModel = fiveDayListViewModel.getData(at: indexPath.row)
        
        cell.configureLabels(with: viewModel)
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        return cell
    }
}
