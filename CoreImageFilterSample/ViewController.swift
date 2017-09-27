//
//  ViewController.swift
//  CoreImageFilterSample
//
//  Created by Tadashi on 2017/09/27.
//  Copyright © 2017 UBUNIFU Incorporated. All rights reserved.
//

import UIKit
import GLKit
import Photos

class ViewController: UIViewController, GLKViewDelegate {

	var ciFilter : CIFilter!
	var ciContext : CIContext!
	var nativeSize : CGSize!
	var renderedImage : CIImage!
	var indicatorView : UIActivityIndicatorView!

	@IBOutlet weak var glkView: GLKView!

	@IBOutlet weak var saturation: UISlider!
	@IBOutlet weak var brightness: UISlider!
	@IBOutlet weak var contrast: UISlider!
	@IBOutlet weak var temperature: UISlider!
	@IBOutlet weak var tint: UISlider!

	@IBOutlet weak var saturationValue: UILabel!
	@IBOutlet weak var brightnessValue: UILabel!
	@IBOutlet weak var contrastValue: UILabel!
	@IBOutlet weak var temperatureValue: UILabel!
	@IBOutlet weak var tintValue: UILabel!
	
	@IBAction func saturation(_ sender: Any) {
		self.saturationValue?.text = String(format: "%.1f", self.saturation.value)
		self.glkView.setNeedsDisplay()
	}
	@IBAction func brightness(_ sender: Any) {
		self.brightnessValue?.text = String(format: "%.1f", self.brightness.value)
		self.glkView.setNeedsDisplay()
	}
	@IBAction func contrast(_ sender: Any) {
		self.contrastValue?.text = String(format: "%.1f", self.contrast.value)
		self.glkView.setNeedsDisplay()
	}
	@IBAction func temperature(_ sender: Any) {
		self.temperatureValue?.text = String(format: "%.f", self.temperature.value)
		self.glkView.setNeedsDisplay()
	}
	@IBAction func tint(_ sender: Any) {
		self.tintValue?.text = String(format: "%.f", self.tint.value)
		self.glkView.setNeedsDisplay()
	}

	@IBAction func cancel(_ sender: Any) {
		self.setup()
	}

	@IBAction func save(_ sender: Any) {

		let button = sender as! UIBarButtonItem
		DispatchQueue.main.async {
			self.indicatorView.isHidden = false
		}
		let context = CIContext(options: nil)
		let jpeg = context.jpegRepresentation(of: self.renderedImage!, colorSpace: (self.ciFilter.outputImage?.colorSpace)!, options: [kCGImageDestinationLossyCompressionQuality: NSNumber(value: 1.0)])
		PHPhotoLibrary.shared().performChanges( {
			let creationRequest = PHAssetCreationRequest.forAsset()
			creationRequest.addResource(with: PHAssetResourceType.photo, data: jpeg!, options: nil)
		}, completionHandler: { (ok, error) in
			DispatchQueue.main.async {
				self.indicatorView.isHidden = true
			}
			button.isEnabled = true
		})
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.glkView.delegate = self
		self.glkView.context = EAGLContext(api : .openGLES3)!
		self.ciContext = CIContext(eaglContext: self.glkView.context,
		                           options:[ kCIContextWorkingFormat : Int(kCIFormatRGBAh)])

		let rect = CGRect.init(x: (self.view.bounds.width / 2) - (37/2),
			y: (self.view.bounds.height / 2) - (37/2) - 64,
			width: 37, height: 37)
		self.indicatorView = UIActivityIndicatorView.init(frame: rect)
		self.indicatorView.activityIndicatorViewStyle = .whiteLarge
		self.indicatorView.backgroundColor = UIColor.lightGray
		self.indicatorView.layer.cornerRadius = 3
		self.indicatorView.startAnimating()
		self.view.addSubview(self.indicatorView)
		DispatchQueue.main.async {
			self.indicatorView.isHidden = true
		}

		self.temperature.minimumValue = 3000
		self.temperature.maximumValue = 8000
		self.tint.minimumValue = -150
		self.tint.maximumValue = 150
		self.saturation.minimumValue = 0.0
		self.brightness.minimumValue = -1.0
		self.contrast.minimumValue = 0.0
		self.saturation.maximumValue = 2.0
		self.brightness.maximumValue = 1.0
		self.contrast.maximumValue = 4.0

		self.setThumb(slider: self.saturation)
		self.setThumb(slider: self.brightness)
		self.setThumb(slider: self.contrast)
		self.setThumb(slider: self.temperature)
		self.setThumb(slider: self.tint)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		checkPhotoLibraryAuthorization { authorized in
			if !authorized {
				print("Permission to use Library denied.")
			}
		}
		self.setup()
	}
	
	func setup() {
		let url = URL(fileURLWithPath: Bundle.main.path(forResource: "PIC00074", ofType: "dng")!)
		self.ciFilter = CIFilter(imageURL: url, options:nil)
		let value = self.ciFilter.value(forKey: kCIOutputNativeSizeKey) as! CIVector
		self.nativeSize = CGSize(width: value.x, height: value.y)

		self.temperature.value = self.ciFilter.value(forKey: kCIInputNeutralTemperatureKey) as! Float
		self.tint.value = self.ciFilter.value(forKey: kCIInputNeutralTintKey) as! Float
		self.temperatureValue?.text = String(format: "%.f", self.temperature.value)
		self.tintValue?.text = String(format: "%.f", self.tint.value)

		self.saturation.value = 1.0
		self.brightness.value = 0.0
		self.contrast.value = 1.0

		self.saturationValue?.text = String(format: "%.1f", self.saturation.value)
		self.brightnessValue?.text = String(format: "%.1f", self.brightness.value)
		self.contrastValue?.text = String(format: "%.1f", self.contrast.value)

		self.glkView.setNeedsDisplay()
	}

	func setThumb(slider: UISlider) {
		slider.setThumbImage(UIImage(named: "thumb-20.png"), for: .normal)
		slider.setThumbImage(UIImage(named: "thumb-50.png"), for: .highlighted)
	}

    func glkView(_ view: GLKView, drawIn rect: CGRect) {

		if isSimulator() {
			return
		}

		let start = NSDate()

        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))

		let contentScaledRect = rect.applying(CGAffineTransform(scaleX: view.contentScaleFactor, y: view.contentScaleFactor))
        let scale = min(contentScaledRect.width / self.nativeSize.width, contentScaledRect.height / self.nativeSize.height)
        self.ciFilter.setValue(scale, forKey: kCIInputScaleFactorKey)

        var displayRect : CGRect! = CGRect(x:0, y:0, width:self.nativeSize.width, height:self.nativeSize.height).applying(CGAffineTransform(scaleX: scale, y: scale))

        displayRect.origin.x = (contentScaledRect.width - displayRect.width) / 2.0
        displayRect.origin.y = (contentScaledRect.height - displayRect.height) / 2.0

		self.ciFilter.setValue(self.temperature.value, forKey: kCIInputNeutralTemperatureKey)
		self.ciFilter.setValue(self.tint.value, forKey: kCIInputNeutralTintKey)
		let filter = CIFilter(name: "CIColorControls")
		filter?.setValue(self.ciFilter.outputImage!, forKey: kCIInputImageKey)
		filter?.setValue(self.saturation.value, forKey: kCIInputSaturationKey)
		filter?.setValue(self.brightness.value, forKey: kCIInputBrightnessKey)
		filter?.setValue(self.contrast.value, forKey: kCIInputContrastKey)
		self.renderedImage = (filter?.outputImage)!

		self.ciContext.draw(self.renderedImage, in:displayRect, from:(self.renderedImage.extent))

		print(NSDate().timeIntervalSince(start as Date))
	}

	func checkPhotoLibraryAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {

		switch PHPhotoLibrary.authorizationStatus() {
			case .authorized:
				completionHandler(true)
				break
			case .notDetermined:
				PHPhotoLibrary.requestAuthorization({ status in
					completionHandler((status == .authorized))
				})
				break
			case .denied:
				completionHandler(false)
				break
			case .restricted:
				completionHandler(false)
				break
		}
	}

	func isSimulator() -> Bool {
		return TARGET_OS_SIMULATOR != 0
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

