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

    // Pedometer
    var stepCount = 0
    var strideLength = 1.0
    let pedometer = CMPedometer()

    // Motion manager
    let mManager = CMMotionManager()

    // Compass
    var locationManger = CLLocationManager()
    var heading: CLLocationDirection?
    var lastHeading: CLLocationDirection?
    var totalDegrees = 0.0

    // Audio recording
    let tmp = NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingPathComponent("tmp.caf"))
    let settings = []
    var recorder: AVAudioRecorder?
    var lastDecibel: Float?

    // Logging properties
    var startDate: NSDate?
    var timer: NSTimer?
    var log: String = "time,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,mag_x,mag_y,mag_z,compass,decibels\n"

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

    @IBAction func stop(sender: UIButton) {
        self.timer?.invalidate()
        self.recorder?.stop()
        self.locationManger.stopUpdatingHeading()
        self.pedometer.stopPedometerUpdates()
        self.mManager.stopAccelerometerUpdates()
        self.mManager.stopGyroUpdates()
        self.mManager.stopMagnetometerUpdates()

        let documentDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as! NSURL
        let fileDestinationUrl = documentDirectoryURL.URLByAppendingPathComponent("output.csv")
        log.writeToURL(fileDestinationUrl, atomically: true, encoding: NSUTF8StringEncoding, error: nil)

        // Send the file
        let activityViewController = UIActivityViewController(activityItems: [fileDestinationUrl], applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }

    // MARK - CLLocationmanagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        if (newHeading.headingAccuracy > 0) {
            var heading = newHeading.magneticHeading
            self.lastHeading = heading
            if (self.heading != nil) {
                // Reduce granularity of updates to avoid overcount
                let granularity = 90.0
                var diff = abs(heading - self.heading!)

                // Difference is a bit subtle if the two values are between true north
                if (heading < granularity && self.heading > 360-granularity) {
                    diff = 360-self.heading! + heading
                } else if (heading > 360-granularity && self.heading < granularity) {
                    diff = 360-heading + self.heading!
                }
                if (diff >= granularity) {
                    self.totalDegrees += diff
                    self.heading = heading
                }
            } else {
                self.heading = heading
            }
            self.degreesLabel!.text = "\(Int(self.totalDegrees))"
        }
    }

    func refreshData() {
        let now = NSDate()
        let ms = floor(now.timeIntervalSinceDate(startDate!)*1000)

        // Accelerometer and gyroscope
        let accelData: CMAccelerometerData? = self.mManager.accelerometerData
        let gyroData: CMGyroData? = self.mManager.gyroData
        let magData: CMMagnetometerData? = self.mManager.magnetometerData
        if (accelData == nil || gyroData == nil || magData == nil) {
            return
        }
        let accel = accelData!.acceleration
        let gyro = gyroData!.rotationRate
        let mag = magData!.magneticField

        // Get new audio data
        self.recorder!.updateMeters()
        let decibels = self.recorder!.averagePowerForChannel(0)

        let newString = "\(ms),\(accel.x),\(accel.y),\(accel.z),\(gyro.x),\(gyro.y),\(gyro.z),\(mag.x),\(mag.y),\(mag.z),\(self.lastHeading!),\(decibels)\n"
        log = log + newString

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

        self.mManager.startAccelerometerUpdates()
        self.mManager.startGyroUpdates()
        self.mManager.startMagnetometerUpdates()

        self.startDate = NSDate()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("refreshData"), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

