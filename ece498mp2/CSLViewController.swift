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
    let settings:[NSObject : AnyObject] = [AVFormatIDKey: NSNumber(kAudioFormatAppleIMA4),
        AVSampleRateKey: NSNumber(44100), AVNumberOfChannelsKey: NSNumber(1), AVLinearPCMBitDepthKey: NSNumber(1), AVLinearPCMIsBigEndianKey: NSNumber(false), AVLinearPCMIsFloatKey: NSNumber(false)]
    var recorder = AVAudioRecorder(tmp, settings, nil)
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
                    println("new is \(Int(heading)), old is \(Int(self.heading!))")
                    self.totalDegrees += diff
                    self.heading = heading
                }
            } else {
                self.heading = heading
            }
            self.degreesLabel!.text = "\(Int(self.totalDegrees))"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.getPedometerData()
        self.locationManger.delegate = self
        self.locationManger.startUpdatingHeading()

        self.degreesLabel!.text = "0"
        self.stepsLabel!.text = "0"

        self.recorder.meteringEnabled = true
        recorder.record()
        recorder.updateMeters()
        let decibels = recorder.averagePowerForChannel(0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

