//
//  PeerSettingsView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

#if os(macOS)

import SwiftUI

//struct EditButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        HStack {
//            configuration.label
//                .padding(.horizontal, 4)
//        }
//        .background(.gray)
//        .foregroundColor(.white)
//        .border(.black)
//        .clipShape(Rectangle())
//    }
//}

struct PeerSettingsView: View {
    @Binding var directIPs: [String]
    @Environment(\.colorScheme) var colorScheme
    @State var selectedIndex = -1
    @State var editingIndex = -1
    
    var peerList: some View {
        ForEach(self.$directIPs.indices, id: \.self) { ind in
            HStack {
                if self.selectedIndex == ind && self.editingIndex == ind {
                    TextField("", text: self.$directIPs[ind])
                        .padding(.horizontal, 4)
                        .background(.background)
                        .foregroundColor(.primary)
                        .onSubmit {
                            self.editingIndex = -1
                        }
                } else {
                    HStack {
                        Text(self.directIPs[ind]).padding(.horizontal, 4)
                        Spacer()
                    }
                        .contentShape(Rectangle())
                        .foregroundColor(self.selectedIndex == ind ? .white : .black)
                        .onTapGesture {
                            if self.selectedIndex == ind {
                                self.editingIndex = ind
                            } else {
                                self.selectedIndex = ind
                                self.editingIndex = -1
                            }
                    }
                }
                Spacer()
            }
            .background(self.selectedIndex == ind ? (self.colorScheme == .light ? .blue : .orange) : .white)
            .frame(alignment: .leading)
        }
    }
    
    var mainFrame: some View {
        HStack {
            if !self.directIPs.isEmpty {
                ScrollView(showsIndicators: true) {
                    peerList
                }
                    .background(.white)
                    .onTapGesture {
                        self.selectedIndex = -1
                        self.editingIndex = -1
                    }
            } else {
                VStack {
                    Rectangle()
                        .fill(.white)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Configure Devices by IP:")
                Spacer()
            }
            if colorScheme == .light {
                mainFrame
            }
            else {
                mainFrame.colorInvert()
            }
            HStack {
                Button("+") {
                    self.directIPs.append("IP")
                }
                Button("-") {
                    if self.selectedIndex != -1 {
                        self.directIPs.remove(at: self.selectedIndex)
                        self.selectedIndex = -1
                    }
                }
                Spacer()
            }
        }
        .padding(.all)
    }
}

struct PeerSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PeerSettingsView(directIPs: .constant([ "127.0.0.1", "192.168.1.1" ]))
    }
}

#endif
