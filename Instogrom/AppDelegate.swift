//
//  AppDelegate.swift
//  Instogrom
//
//  Created by Michael Cheng on 07/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Override point for customization after application launch.
        FIRApp.configure()

        //switch rootViewController
        //1.how to get storyboard?
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        debugPrint(storyboard) //it would show UIStoryBoard: 0x......
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                print("user \(user.uid) has signed in")
                if let viewController = storyboard.instantiateInitialViewController(){
                    self.window?.rootViewController = viewController
                }
            }else{
                print ("user hasnt signed in")
                //2.upon getting, how to get view controller
                let viewController = storyboard.instantiateViewController(withIdentifier: "SignInOrSignUp")
                //3.set the desired view controller as window.rootViewController
                self.window?.rootViewController = viewController
            }
        }
        return true

    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

