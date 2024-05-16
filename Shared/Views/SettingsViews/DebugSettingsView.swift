//
//  DebugSettingsView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 18.06.22.
//

import SwiftUI
import CoreData

struct DebugSettingsView: View {
    
    @ObservedObject var settings = Settings.sharedInstance
    
    var body: some View {
        
        NavigationSubView {
            
            CustomSection {
                
                LUIButton(action: {
                    
                    guard let fileURL = LogManager.sharedInstance.logFileURL else  {return}
                    
                    
                    let shareActivity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    
                    if let vc = UIApplication.shared.windows.first?.rootViewController{
                        shareActivity.popoverPresentationController?.sourceView = vc.view
                        
                        shareActivity.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height, width: 0, height: 0)
                        shareActivity.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
                        vc.present(shareActivity, animated: true, completion: {
                        })
                    }
                    
                }, label: {
                    SettingsLabel(imageName: "square.and.arrow.up", text: "Share logs", backgroundColor: .orange)
                })
                
                
                Toggle(isOn: $settings.debugMode) {
                    SettingsLabel(imageName: "curlybraces", text: "Debug Mode")
                }
                
                Toggle(isOn: $settings.debugPush) {
                    SettingsLabel(imageName: "bell", text: "Debug Push", backgroundColor: .red)
                }
                
                
                LUIButton(action: {
                    
                    BluetoothManager.sharedInstance.reset()
                    
                }) {
                    SettingsLabel(imageName: "arrow.counterclockwise", text: "Reset Bluetooth Manager", backgroundColor: .yellow)
                }
                
                
                LUIButton(action: {
                    PersistenceController.sharedInstance.modifyDatabase { context in
                        addFakeNotification(context: context)
                    }
                   
                }) {
                    SettingsLabel(imageName: "bell", text: "Fake Notification", backgroundColor: .green)
                }
                
                LUIButton(action: {
                    let statsController = SendStatisticsController(lastDataDonation: Date.distantPast)
                    Task{
                        try? await statsController.sendStats()
                    }
                   
                }) {
                    SettingsLabel(imageName: "arrow.up.square.fill", text: "Send Statistics", backgroundColor: .orange)
                }
            }
            
            CustomSection {
                
                LUIButton(action: {
                    addDummyData()
                }) {
                    SettingsLabel(imageName: "plus", text: "Simulate Database Overload", backgroundColor: .gray)
                }
                
                LUIButton(action: {
                    PersistenceController.sharedInstance.modifyDatabase { context in
                        cleanDatabase(context: context)
                    }
           
                }) {
                    SettingsLabel(imageName: "minus", text: "Clean Old Tracker Data", backgroundColor: .gray)
                }
            }
            
            CustomSection {
                
                LUILink(destination:
                    DebugMapView()
                        .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
                        .navigationBarTitleDisplayMode(.inline)
                        .background(ProgressView()), label:
                {
                    SettingsLabel(imageName: "map.fill", text: "Show all locations", backgroundColor: .green)
                })
                
                LUIButton(action: {
                    
                    settings.tutorialCompleted = false
                    
                }) {
                    SettingsLabel(imageName: "arrow.counterclockwise", text: "Reset To Tutorial", backgroundColor: .purple)
                }
            }
            
            CustomSection {

                DeleteElemView(name: "BaseDevices", type: BaseDevice.self)
                DeleteElemView(name: "DetectionEvents", type: DetectionEvent.self)
                DeleteElemView(name: "Locations", type: Location.self)
                DeleteElemView(name: "Alerts", type: TrackerNotification.self)
                
            }
            
            Spacer()
        }
        .navigationTitle("Debug Settings")
    }
}


struct DeleteElemView<T: NSManagedObject>: View {
    
    let name: String
    let type: T.Type
    
    @FetchRequest(
        sortDescriptors: []
    ) var elems: FetchedResults<T>
    
    var body: some View {
        
        LUIButton {
            PersistenceController.sharedInstance.modifyDatabase { context in
                delete(entries: Array(elems), context: context)
            }
            
        } label: {
            SettingsLabel(imageName: "trash", text: "Remove \(elems.count) \(name)", backgroundColor: .red)
            
        }
    }
}


struct Previews_DebugSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DebugSettingsView()
    }
}
