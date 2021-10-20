//
//  FiveDayWeatherViewModel.swift
//  WeatherForecast
//
//  Created by Soll on 2021/10/14.
//

import UIKit

class FiveDayWeatherListViewModel {
    
    var reloadTableView: (() -> Void)?
    var weatherService = WeatherService()
    var weathers: [FiveDayWeatherViewModel] = []
    
    var numberOfRowInSection: Int {
        return weathers.count
    }
    
    func mapFiveDayData() {
        weatherService.fetchByLocation { (fiveDayWeather: FiveDayWeatherData) in
            fiveDayWeather.intervalWeathers?.forEach({ data in
                guard let date = data.date?.format(),
                      let temperature = data.mainInformation?.temperature?.franctionDisits(),
                      let iconName = data.conditions?.first?.iconName else {
                    return
                }
                
                ImageLoader.shared.obtainImage(cacheKey: iconName, completion: { image in
                    guard let image = image else { return }
                    self.weathers.append(FiveDayWeatherViewModel(date, temperature, image))
                })
            })
            self.reloadTableView?()
        }
    }
    
    func getData(at index: Int) -> FiveDayWeatherViewModel {
        if weathers == [],
           let sampleImage = UIImage(systemName: "circle") {
            return FiveDayWeatherViewModel("-", "-", sampleImage)
        }
        let data = weathers[index]
        return FiveDayWeatherViewModel(data.dateThreeHour,
                                       data.temperatureThreeHour,
                                       data.imageThreeHour)
    }
}

struct FiveDayWeatherViewModel: Equatable {
    
    var dateThreeHour: String
    var temperatureThreeHour: String
    var imageThreeHour: UIImage
    
    init(_ date: String, _ temperature: String, _ image: UIImage) {
        self.dateThreeHour = date
        self.temperatureThreeHour = temperature
        self.imageThreeHour = image
    }
}
