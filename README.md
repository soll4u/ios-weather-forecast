# 날씨 정보

프로젝트 기간 (2021.9.27 ~ 2021.10.21)

## 기능

![Weather](https://user-images.githubusercontent.com/28389897/138698237-4e76ac4e-cce4-469a-b1f2-064240852072.gif)

- [Open Weather Map API](https://openweathermap.org/)를 이용해 현재 날씨와 5일치 날씨 예보 데이터를 가져온다.
- CoreLocation을 이용해 사용자의 현재 위치를 받아오고, 위도 경도를 이용해 날씨 정보를 받아오게 된다.
- TableViewHeader에는 현재 날씨와 위치 정보, 각 셀에는 5일치의 3시간 간격 날씨 정보를 보여준다.

<br>
<br>

## Step1

### 🔖 요약

- JSON 데이터와 매핑가능한 모델 설계
- API 서버와 통신하기 위한 타입 구현
- 라이브러리 없이 URL Session을 활용하여 테스트 가능한 네트워킹 타입 구현

<br>

### 📚 학습 내용

#### 1. APIKey를 hiding하는 방법

기존의 static 상수로 표시하던 APIKey 문자열을 외부 저장소에 올려 공유되는 형태를 방지하는 방식에 대해 접하고 적용해보았다.

현재 사용하는 APIKey를 이용해서 민감정보가 유출될 큰 위험성은 없지만, 추후에 민감한 정보가 유출될 위험이 있는 APIKey를 다루게 될 때 필요할 것 같아 공부했다.

> **참고자료**
> [애플리케이션의 민감한 정보를 보호하는 방법 nshispter.co.kr](https://nshipster.co.kr/secrets/)
> [Fetching API Keys from Property List Files](https://peterfriese.dev/reading-api-keys-from-plist-files/)

<br>

#### 2. Codingkeys에 이미 적용된 `convertFromSnakeCase` 속성

- `keyDecodingStrategy`의 `convertFromSnakeCase`를 사용하여 Snake-case로 넘어오는 key값을 Camel-case 이름으로 변환되도록 구현했다.
- JSON 데이터의 Key값 `temp_min`이 `tempMin`으로 변환되어 있었다.

```
private enum Codingkeys: String, CodingKey {
    // ...
    case minimumTemperature = "tempMin"
    // 예상 헸던 코드
    // case minimumTemperature = "temp_min"
}
```

<br>

#### 3. Decoderable 모델 구현 관련

- 전체 프로퍼티를 옵셔널로 만들어 보았다:
- API에서 제공하는 값들이 필수로 제공된다는 것을 보장하지 않았다. 데이터가 넘어오지 않을 것을 대비해 옵셔널로 선언했다.

<br>

#### 4. SwiftLint exclude 관련

❓`AppDelegate.swift`, `SceneDelegate` 파일을 `exclude` 할까?
`exclude` 하는 이유에 대해 추측했다.

- 가정1: 앱에 중요한 비즈니스 로직이 들어가지 않는다.
- 가정2: 앱 프로젝트의 공통의 영역이므로 파트별로 컨벤션이 다를 수 있는 영역이다.

그럼에도 컨벤션을 유지할 수 있는 장점이 있어서 이번 프로젝트에서 `exclude`에 포함하지 않았다.

<br>

#### 5. URLSessionDataTask의 초기화 문제

[![img](https://camo.githubusercontent.com/8bfe9b5e733e403a7be769d394f9b82e611be0f969c6645316c760787a951969/68747470733a2f2f692e696d6775722e636f6d2f4d675a726d6e6b2e706e67)](https://camo.githubusercontent.com/8bfe9b5e733e403a7be769d394f9b82e611be0f969c6645316c760787a951969/68747470733a2f2f692e696d6775722e636f6d2f4d675a726d6e6b2e706e67)

- `URLSessionDataTask`를 상속한 `MockURLSessionDataTask`의 init()이 iOS 13부터 deprecated 되기 때문에 다른 방식으로 구현을 고민했다.
- `URLSessionDataTaskProtocol` 을 정의하고, `URLSessionDataTask`가 프로토콜을 채택하도록 바꿨다.
- 새롭게 변형된 반환값을 맞추기위해 `makeCustomDataTask(_:_:) -> URLSessionDataTaskProtocol` 메서드를 `URLSessionProtocol`로 주입했다.

<br>

#### 6. API를 생성해주는 Enum 타입에서 타입프로퍼티 초기화 고민

- APIKey를 .plist의 형태로 코드가 아닌 문서로 저장하는 형태의 구현을 했는데. Enum 타입의 타입 프로퍼티로 읽어오는 과정을 고민해봤다.

```
private static var apiKey: String {
        // .. 파일 읽어오기
        return apiKey }
private static let appID = WeatherAPI.apiKey
```

- 실험을 통해 `appID` 호출은 최초 호출에만 연산프로퍼티가 동작하고 이후에는 저장된 값을 읽어오는 걸 확인 후 해당 방식으로 구현했다.

<br>

#### 7. UnitTest XCTestCase의 프로퍼티 초기화 고민

```
class DecodingTests: XCTestCase {
     var currentSut: CurrentData!
}
```

- 일반적으로 위 코드처럼 초기화 하고 `setUp()` 또는 `setUpWithError()` 메서드 재정의에서 위 프로퍼티를 초기화 하는 형태를 가지는데 왜 그렇게 하는지 또는 다른 초기화 방법은 없는지 고민해보았다. 해당 [PR Review Comment](https://github.com/yagom-academy/ios-weather-forecast/pull/40/files/a0cc11e3595da14ec4fe7c561162b715f5d80153#r721846246)와 답변

<br>
<br>


## Step2

### 🔖 요약

- CoreLocation을 이용해 현재 좌표를 얻음
- Geocoder를 이용해 현재 주소를 얻음
- 네트워크 통신을 통해 받은 JSON 데이터를 파싱하고 모델에 매칭
- NumberFormatter를 이용한 String 변환

<br>

### 📚 학습 내용

#### 1. CoreLocation을 이용한 현재 좌표를 가져오기

CoreLocation을 통한 위치 정보를 가져올 때 
`CLLocationManagerDelegate` 를 채택한 `LocationManager` 가 책임지도록 설계했다. 
내부에 `CLLocationManager`의 인스턴스를 가지고 있고, CL과 관련된 메서드들을 구현해주었다.

<br>

#### 2. 문자열 보간법을 쓰지 않고 Double -> String으로 변환하기

3가지 방법을 고려해보았고, 3번째 방법인 `NumberFormatter`  를 사용해서 String으로 변환했다.

1. LosslessStringConvertible 프로토콜 확장

```swift
extension LosslessStringConvertible { 
    var string: String { .init(self) } 
}

let double = 1.5 
let string = double.string  //  "1.5"
```

2. String- Format Specifier 고정된 소수 자릿수에 대해 FloatingPoint 프로토콜을 확장 C의 리터럴 중 하나인 포맷으로부터 문자열을 만듬 ⇒ Objective-C의 문자열 리터럴이기때문에 사용하지 않기로 함

```swift
extension FloatingPoint where Self: CVarArg {
    func fixedFraction(digits: Int = 1) -> String {
        .init(format: "%.*f", digits, self)
    }
}

temperature.fixedFraction() // 15.8
```

- [CVarArg](https://developer.apple.com/documentation/swift/cvararg)

- [FloatingPoint](https://developer.apple.com/documentation/swift/floatingpoint)

- [String .init(format:_:)](https://developer.apple.com/documentation/swift/string/3126742-init)

  ```swift
  init(format: String, _ arguments: CVarArg...)
  ```

- [String Format Specifiers](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html)

  ```swift
  %f
  
  64-bit floating-point number (double).
  ```

- 참고

  [25. String- Format Specifier](https://beepeach.tistory.com/53)

<br>

3.NumberFormatter 사용

```swift
extension Formatter {
    static let number = NumberFormatter()
}

extension FloatingPoint {
    func fractionDigits(min: Int = 2, max: Int = 2, roundingMode: NumberFormatter.RoundingMode = .halfEven) -> String {
        Formatter.number.minimumFractionDigits = min
        Formatter.number.maximumFractionDigits = max
        Formatter.number.roundingMode = roundingMode
        Formatter.number.numberStyle = .decimal
        return Formatter.number.string(for: self) ?? ""
    }
}

2.12345.fractionDigits()                                    // "2.12"
2.12345.fractionDigits(min: 3, max: 3, roundingMode: .up)   // "2.124"
```

<br> 
<br>

## Step3

### 🔖 요약

- UITableView HeaderView의 사용
- UITableView를 programmatically하게 구현
- Refresh Control을 사용
- UITableView 셀 이미지 지연 로딩 
- DateFormatter를 이용한 String 변환

<br>

### 📚 학습 내용

#### 1. 위치 서비스 권한 상태 변경에 따라 대응하기

`locationManager(_:didChangeAuthorization:)` 메서드를 이용하여 상태에 따라 어떻게 처리해줄지 고민했다.

- `denied`: 사용자가 앱에 대한 위치 서비스 사용을 거부했거나 앱이 설정에서 전체적으로 비활성화됨
- `restricted`: 앱이 위치 서비스를 사용할 수 있는 권한이 없음
- `notDetermined`: 위치 서비스를 사용할 수 있는지 여부를 선택하지 않음
- `authorizedAlways`, `authorizedWhenInUse`: 언제든지 , 사용중인 동안 서비스를 사용하도록 권한이 부여됨

`notDetermined` 일 때 권한을 요청하고 위치를 요청하는 메서드를 호출하도록 했다.
`notDetermined`, `restricted` 를 하나의 케이스로 보고 다시 권한을 요청했지만, `restricted` 는 권한을 사용자가 설정할 수 없을 수 있어 분리해서 처리해주었다.

```swift
switch status {
case .denied:
    print("권한 요청 거부됨")
    // TODO: - Alert + Error 처리
    return
case .restricted:
    print("권한이 제한됨")
case .notDetermined:
    print("권한 요청 되지 않음")
    manager.requestWhenInUseAuthorization()
    manager.requestLocation()
    return
case .authorizedAlways, .authorizedWhenInUse:
    print("권한 있음")
    guard let lastLocation = self.manager.location else {
        return
    }
    completion?(lastLocation)
@unknown default:
    break
}
```

<br>

#### 2. TableViewHeader와 TableView의 Section Header는 다르다

- Section Header는 `UITableViewHeaderFooterView` 를 상속받지만, TableViewHeader를 위해선 UIView를 상속받아 사용해도 된다.

- Section Header는 register해야 되지만 TableViewHeader는 register 할 필요 없다.

  ```swift
  // Section Header
  tableView.register(MyCustomHeader.self, 
         forHeaderFooterViewReuseIdentifier: "sectionHeader")
  ```

- Section Header는 테이블 뷰 delegate 객체 안에 `tableView(_:viewForHeaderInSection:)` 메서드를 이용해 구현해야 하고, TableViewHeader는 `tableHeaderView` 프로퍼티에 할당해주면 된다.

  ```swift
  // TableViewHeader
  tableView.tableHeaderView = headerView
  ```

<br>

#### 3. Cache 구현 방식 - 메모리 캐시 vs 디스크 캐시

리뷰어의 코멘트를 보고 캐시 구현방식에 대해 고민해보았다.

디스크 캐시와 메모리 캐시의 차이를 알고 계실것 같은데 혼합하여 사용할 수도 있고 아니면 디스크 캐시인 파일 매니저등을 통해 캐시를 사용할 수도 있는데 메모리 캐시인 NSCache를 사용한 이유가 궁금합니다🧐

=> 큰 이유없이 메모리 캐시로 구현했는데, 메모리 캐시가 디스크 캐시보다 저장공간이 작지만 처리속도가 빠르다는 점이 장점이라고 생각했다. 반영구적으로 해당 날씨 데이터를 가지고 있을 필요는 없어서 디스크 캐시 구현은 필요하지 않을 것 같다.

