//
//  Helpers.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 03/12/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import UserNotifications
import Cocoa

// Displays an alert and option to check the logs
func showAlertFailedAndCheckLogs(message: String, informativeMsg: String) {
    NSApplication.shared.activate(ignoringOtherApps: true)
    
    let alert: NSAlert = NSAlert()
    alert.messageText = message
    alert.informativeText = informativeMsg
    alert.alertStyle = NSAlert.Style.warning
    alert.addButton(withTitle: "Check Logs")
    alert.addButton(withTitle: "Not now")
    if alert.runModal() == .alertFirstButtonReturn {
        // Open logs file
        print("Check Logs button clicked")
        let logFilePath: URL = userHomePath.appendingPathComponent(".crc").appendingPathComponent("crc").appendingPathExtension("log")
        NSWorkspace.shared.open(logFilePath)
    } else {
        print("Not now button clicked")
    }
}

// Displays a success notification
func displayNotification(title: String, body: String) {
    let center = UNUserNotificationCenter.current()
    if notificationAllowed {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: body,
                                                                arguments: nil)
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: title, content: content, trigger: trigger)
        center.add(request) { (error) in
            if error != nil {
                print(error?.localizedDescription ?? "No Error")
            }
        }
    }
}

struct ClusterStatus: Decodable {
    let Name: String
    let CrcStatus: String
    let OpenshiftStatus: String
    let DiskUse: Int64
    let DiskSize: Int64
    let Error: String
    let Success: Bool
}

// Get the status of the cluster from the daemon
func clusterStatus() -> String {
    let status = SendCommandToDaemon(command: Request(command: "status", args: nil))
    guard let data = status else { return "Unknown" }
    print(String(bytes: data, encoding: .utf8)!)
    if String(bytes: data, encoding: .utf8) == "Failed" {
        print("In failed")
        return "Unknown"
    }
    do {
        let st = try JSONDecoder().decode(ClusterStatus.self, from: data)
        if st.OpenshiftStatus.contains("Running") {
            return "Running"
        }
        if st.OpenshiftStatus == "Stopped" {
            return "Stopped"
        }
    } catch let jsonERR {
        print(jsonERR.localizedDescription)
    }
    return "Unknown"
}
