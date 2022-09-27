//
//  LargeFontClockApp.swift
//  LargeFontClock
//
//  Created by GeXiangDong on 2022/9/27.
//

import SwiftUI

@main
struct LargeFontClockApp: App {
    var body: some Scene {
        WindowGroup {
          ContentView().frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.black)
                     .edgesIgnoringSafeArea(.all)
                     .statusBar(hidden: true)

        }
    }
}
