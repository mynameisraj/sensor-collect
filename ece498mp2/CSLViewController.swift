//
//  CSLViewController.swift
//  ece498mp2
//
//  Created by Raj Ramamurthy on 3/30/15.
//  Copyright (c) 2015 Raj Ramamurthy. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import AVFoundation

class CSLViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var degreesLabel: UILabel?
    @IBOutlet weak var stepsLabel: UILabel?

    var stepCount = 0
    var strideLength = 1.0
    var heading: CLLocationDirection?
    var locationManger = CLLocationManager()
    var totalDegrees = 0.0
    let pedometer = CMPedometer()
    let tmp = NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingPathComponent("tmp.caf"))
    let settings = []
    var recorder: AVAudioRecorder?
    var lastDecibel: Float?
    var lastHeading: CLLocationDirection?

    func getPedometerData() {
        let now = NSDate()
        self.pedometer.startPedometerUpdatesFromDate(now, withHandler: { data, error in
            // Got a pedometer update
            if (data != nil) {
                self.stepCount = data.numberOfSteps.integerValue
                self.stepsLabel!.text = "\(self.stepCount)"
            }
        })
    }

    // MARK - CLLocationmanagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        if (newHeading.headingAccuracy > 0) {
            var heading = newHeading.magneticHeading
            if (self.heading != nil) {
                // Reduce granularity of updates to 90 degrees
                var diff = abs(heading - self.heading!)

                // Difference is a bit subtle if the two values are between true north
                if (heading < 90 && self.heading > 270) {
                    diff = 360-self.heading! + heading
                } else if (heading > 270 && self.heading < 90) {
                    diff = 360-heading + self.heading!
                }
                if (diff >= 90) {
//                    println("new is \(Int(heading)), old is \(Int(self.heading!))")
                    self.totalDegrees += diff
                    self.heading = heading
                }
            } else {
                self.heading = heading
            }
            self.degreesLabel!.text = "\(Int(self.totalDegrees))"
        }
    }

    func refreshAudioData() {
        self.recorder!.updateMeters()
        let decibels = self.recorder!.averagePowerForChannel(0)
        println("Decibels is \(decibels)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.getPedometerData()
        self.locationManger.delegate = self
        self.locationManger.startUpdatingHeading()

        self.degreesLabel!.text = "0"
        self.stepsLabel!.text = "0"

        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord , error: nil)

        let settings:[NSObject : AnyObject] = [AVFormatIDKey: NSNumber(integer: kAudioFormatAppleIMA4), AVSampleRateKey: NSNumber(integer: 44100), AVNumberOfChannelsKey: NSNumber(integer: 1), AVLinearPCMBitDepthKey: NSNumber(integer: 1), AVLinearPCMIsBigEndianKey: NSNumber(bool: false), AVLinearPCMIsFloatKey: NSNumber(bool: false)]

        self.recorder = AVAudioRecorder(URL: self.tmp, settings: settings, error: nil)
        self.recorder!.meteringEnabled = true
        self.recorder!.record()

        var timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("refreshAudioData"), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

