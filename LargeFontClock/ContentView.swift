//
//  ContentView.swift
//  clock
//
//  Created by GeXiangDong on 2022/9/24.
//

import SwiftUI

struct ContentView: View {
  @State private var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
  @State private var hour:Int?
  @State private var minute:Int?
  @State private var second:Int?
  @State private var dateNow = ""
  @State private var ampm = ""
  @State private var orientation = UIDeviceOrientation.unknown
  @State private var parameter = Parameter()
  @State private var brightness:CGFloat = 0
  
  let TWENTY_FOUR_HOUR_KEY = "twenty_four_key"
  let SHOW_SECOND_KEY = "show_second"
  let PARAMETER_KEY = "clock_parameter"
  let CLOCK_BRIGHTNESS = 0.1;
  
  @State private var timeFont:Font = Font.largeTitle
  @State private var timeSepatorColor = Color.white
  
  @State private var showingSettingSheet = false
  
  
  var textColor:Color = Color.white
  let dateFormatter = DateFormatter()
  
  var body: some View {
    ZStack {
      if(parameter.showDate){
        Text("\(dateNow)").foregroundColor(textColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
          .padding(.top, UIScreen.main.bounds.width < UIScreen.main.bounds.height ? 60 : 5) //avoid not safe area top
      }
      VStack{
        if(!parameter.twentyFourHours){
          Text("\(ampm)")
            .font(.system(size: 40, weight: .bold, design: .monospaced))
            .foregroundColor(textColor)
        }
        if(hour != nil && minute != nil && second != nil){
          HStack{
            Text( String(format: "%02d", hour!))
              .font(timeFont)
              .foregroundColor(textColor)
            Text(":").font(timeFont)
              .foregroundColor(timeSepatorColor)
            Text(String(format: "%02d", minute!))
              .font(timeFont)
              .foregroundColor(textColor)
            if(parameter.showSecondInOrientation(orientation)){
              Text(":").font(timeFont)
                .foregroundColor(textColor)
              Text(String(format: "%02d", second!) )
                .font(timeFont)
                .foregroundColor(textColor)
            }
          }
        }
      }.padding(.bottom, parameter.twentyFourHours ? 5 : 30)
      
      if(UIScreen.main.bounds.width < UIScreen.main.bounds.height ){
        //竖屏显示设置按钮
        HStack{
          Image(systemName: "gear").foregroundColor( .gray).fixedSize().frame( width:36, height:36)
            .font(.system(size: 32)).onTapGesture {
              showSettingSheet()
            }
        }.frame(maxHeight: .infinity, alignment: .bottom)
          .padding(.bottom, 40) //avoid not safe area bottom
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
      //            print("To the background!")
      clockDisappear()
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
      //        print("To the foreground!")
      clockAppear()
    }
    .onReceive(timer) { _ in
      let now = Date()
      self.dateNow = dateFormatter.string(from: now)
      let calendar = Calendar.current
      let hour = calendar.component(.hour, from: now)
      self.minute = calendar.component(.minute, from: now)
      self.second = calendar.component(.second, from: now)
      if(parameter.showSecondInOrientation(orientation)){
        timeSepatorColor = Color.white
      }else{
        if(timeSepatorColor == Color.white){
          timeSepatorColor = Color.black
        }else{
          timeSepatorColor = Color.white
        }
      }
      if(hour >= 12){
        self.ampm = NSLocalizedString("PM", comment: "")
      }else{
        self.ampm = NSLocalizedString("AM", comment: "")
      }
      if(parameter.twentyFourHours || hour < 13){
        self.hour = hour
      }else{
        self.hour = hour % 12
      }
    }
    .onAppear(perform: {
      dateFormatter.dateStyle = .long // set as desired
      dateFormatter.timeStyle = .none // set as desired
      do{
        let userDefaults = UserDefaults.standard
        let savedJson = userDefaults.string(forKey: PARAMETER_KEY)
        if(savedJson == nil){
          parameter = Parameter()
        }else{
          let decoder = JSONDecoder()
          parameter = try decoder.decode(Parameter.self, from: savedJson!.data(using: .utf8)!)
        }
      }catch {
        print("Unexpected error: \(error).")
        parameter = Parameter()
      }
      
      calTimeFont()
      self.brightness = UIScreen.main.brightness
      clockAppear()
    })
    .onDisappear(perform: {
      print("onDisappear")
      clockDisappear()
    })
    .onRotate { newOrientation in
      self.orientation = newOrientation
      calTimeFont()
    }
    .sheet(isPresented: $showingSettingSheet, onDismiss: didDismiss) { settingSheet }
    
  }
  
  
  var settingSheet : some View{
    NavigationView {
      VStack(alignment: .leading, spacing: 10) {
        List{
          Toggle(isOn: $parameter.showDate ) {
            Text("Show Date")
          }.onChange(of: parameter.showDate) { value in
            saveParameters()
          }
          Toggle(isOn: $parameter.twentyFourHours ) {
            Text("24 Hours")
          }.onChange(of: parameter.twentyFourHours) { value in
            saveParameters()
          }
          VStack(alignment: .leading, spacing: 20) {
            Text("Show Seconds")
            Picker("Show Seconds", selection: $parameter.showSecond) {
              Text("Landspace only").tag(1)
              Text("All").tag(2)
              Text("None").tag(3)
            }
            .pickerStyle(.segmented)
            .onChange(of: parameter.showSecond) { value in
              saveParameters()
            }
          }
        }
      }
      .onAppear(perform: {
        clockDisappear()
      })
      .navigationBarTitle("Settings", displayMode: .inline)
      .navigationBarItems( trailing: Button("Done", action: { closeSettingSheet() })
      )
    }
  }
  
  func clockAppear(){
    UIScreen.main.brightness = CLOCK_BRIGHTNESS
    UIApplication.shared.isIdleTimerDisabled = true  //disable idel and lock screen
  }
  func clockDisappear(){
    UIScreen.main.brightness = brightness  //恢复原有设定亮度
    UIApplication.shared.isIdleTimerDisabled = false  //enable idel and lock screen
  }
  
  func saveParameters() {
    do{
      let userDefaults = UserDefaults.standard
      let encodedData = try JSONEncoder().encode(parameter)
      let jsonString = String(data: encodedData,  encoding: .utf8)
      if(jsonString != nil){
        userDefaults.set(jsonString!, forKey: PARAMETER_KEY)
        userDefaults.synchronize()
      }else{
        print("json string is null \(encodedData)")
      }
    }catch {
      print("Unexpected error while save: \(error).")
    }
    calTimeFont()
  }
  
  func calTimeFont(){
    let w =  UIScreen.main.bounds.width
    var fontSize:CGFloat!
    if(parameter.showSecondInOrientation(orientation)){
      fontSize = w / 8
    }else{
      fontSize = w / 5
    }
    timeFont = Font.system(size:fontSize, weight: .bold, design: .monospaced)
  }
  
  private func didDismiss(){
    print("settingSheet dismiss")
    clockAppear()
  }
  
  private func closeSettingSheet(){
    self.showingSettingSheet = false
  }
  
  private func showSettingSheet(){
    print("setting tap")
    self.showingSettingSheet = true
  }
}



struct DeviceRotationViewModifier: ViewModifier {
  let action: (UIDeviceOrientation) -> Void
  
  func body(content: Content) -> some View {
    content
      .onAppear()
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
        action(UIDevice.current.orientation)
      }
  }
}

class Parameter: Equatable, Encodable, Decodable{
  var showSecond = 1 //1: landspace only; 2: all; 3: none
  var twentyFourHours = false
  var showDate = true
  
  
  func showSecondInOrientation(_ orientation:UIDeviceOrientation) -> Bool {
    //    print("showSecondInOrientation \(orientation.rawValue) \(showSecond)")
    if(showSecond == 2 || (showSecond == 1 && UIScreen.main.bounds.width > UIScreen.main.bounds.height)){
      return true
    }else{
      return false
    }
  }
  
  static func == (lhs: Parameter, rhs: Parameter) -> Bool {
    if(lhs.twentyFourHours == rhs.twentyFourHours &&
       lhs.showDate == rhs.showDate &&
       lhs.showSecond == rhs.showSecond){
      return true;
    }else{
      return false;
    }
  }
}

// A View wrapper to make the modifier easier to use
extension View {
  func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
    self.modifier(DeviceRotationViewModifier(action: action))
  }
}



struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
