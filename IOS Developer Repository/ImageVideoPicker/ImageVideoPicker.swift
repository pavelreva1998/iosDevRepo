//
//  PhotoVideoPicker
//  IOSDevRepository
//
//  Created by Pavel Reva on 02/10/19.
//  Copyright © 2018 Pavel Reva. All rights reserved.
//

import UIKit
import AVFoundation

/// Protocol for handling **ImageVideoPicker** events
@objc protocol ImageVideoPickerDelegate {
    
    /// Implement this callback to get picked photo
    @objc optional func photoDidPicked(_ picker: ImageVideoPicker, image: UIImage)
    /// Implement this callback to get picked video url
    @objc optional func videoDidPicked(_ picker: ImageVideoPicker, videoUrl: URL)
    /// Implement this callback to handle the case when user deny permission for usage camera/library
    @objc optional func pickerDidRejected(_ picker: ImageVideoPicker)
}

/// The enum describes media types which you can get via the picker
public enum ImageVideoPickerMediaType: String {
    
    case photo = "public.image"
    case video = "public.movie"
}

/**
 
 Via the class you have ability to pick image and video from library and camera
 
 ## Important notes: ##
 
1. If you want to use the class you have to add next items in your *Info.plist*: **Privacy – Photo Library Usage Description**, **Privacy - Camera Usage Description** to access library and camera respectively
 
2. For video you also have to add to your *Info.plist* **Privacy - Microphone Usage Description**

*/

class ImageVideoPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private weak var vc: UIViewController?
    private var mediaType: ImageVideoPickerMediaType = .photo
    private var alertTitle: String?
    private var alertMessage: String?
    
    /// You can handle croping behaviour, be default it equals **false**
    var useCrop: Bool = false
    
    /// If you use alert/actionSheet behaviour of the picker, via the **cameraButtonTitle** property you can set label for corresponding button of the picker, by default it equals **Open Camera**
    var cameraButtonTitle: String? = "Open Camera"
    /// If you use alert/actionSheet behaviour of the picker, via the **chooseFromLibraryButtonTitle** property you can set label for corresponding button of the picker, by default it equals **Open library**
    var chooseFromLibraryButtonTitle: String? = "Open library"
    /// If you use alert/actionSheet behaviour of the picker, via the **cancelButtonTitle** property you can set label for corresponding button of the picker, by default it equals **Cancel**
    var cancelButtonTitle: String? = "Cancel"
    
     /// If you use alert/actionSheet behaviour of the picker, via the *alertStyle* property you can style of the alert, by default it equals **actionSheet**
    var alertStyle: UIAlertController.Style = .actionSheet

    /// The delegate for **ImageVideoPicker**
    weak var delegate: ImageVideoPickerDelegate?
    
    
    /// If you don't want to use alert to pick image/video, you can assign this property **true** and only camera will open to pick, by default it equals **false**
    var useCameraOnly: Bool = false {
        
        didSet {
            
            if useCameraOnly {
                
                useLibraryOnly = false
            }
        }
    }
    
    /// If you don't want to use alert to pick image/video, you can assign this property **true** and only library will open to pick, by default it equals **false**
    var useLibraryOnly: Bool = false {
        
        didSet {
            
            if useLibraryOnly {
                
                useCameraOnly = false
            }
        }
    }

    /**
 
     #The initializer for **ImageVideoPicker**#
     
     *Parameters:*
     
     - Parameter vc: The viewController, which will *take* **ImageVideoPicker**
     - Parameter alertTitle: The title of the alert/actionSheet, which will present for choosing the way of picking image/video
     - Parameter alertMessage: The message of the alert, which will present for choosing the way of picking image/video, by default it equals **nil**
     - Parameter useCrop: The option, which incapsulate *property* **allowsEditing** of the class **UIImagePickerController**, by default if equals **false**
     - Parameter aMediaType: The type of media, which will be picked, by default it equals **.photo**
     
    */
    
    init(vc aVc: UIViewController, alertTitle aAlertTitle: String, alertMessage aAlertMessage: String? = nil, useCrop aUseCrop: Bool = false, mediaType aMediaType: ImageVideoPickerMediaType = .photo) {
        
        vc = aVc
        
        useCrop = aUseCrop
        mediaType = aMediaType
        
        alertMessage = aAlertMessage
        alertTitle = aAlertTitle
        
        super.init()
    }
    
    /// The method, which start picking process, just show alert/open camera or library
    func pick() {
        
        assert(!(useCameraOnly && useLibraryOnly), "Only one of the params can be true in function -  \(#function), line - \(#line)")
        
        if !useCameraOnly && !useLibraryOnly {
            
            assert(alertTitle != nil || alertMessage != nil, "Title or message shouldn't be nil for showing alert in function -  \(#function), line - \(#line)")
            
            let alertController: UIAlertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: alertStyle)
            
            alertController.addAction(UIAlertAction(title: cameraButtonTitle, style: .default) { _ in
                self.takePhoto(aSourceType: .camera)
            })
            
            alertController.addAction(UIAlertAction(title: chooseFromLibraryButtonTitle, style: .default) { _ in
                self.takePhoto(aSourceType: .photoLibrary)
            })
            
            alertController.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel))
            
            vc?.present(alertController, animated: true, completion: nil)
            
        } else if useCameraOnly {
            
            takePhoto(aSourceType: .camera)
        } else if useLibraryOnly {
            
            takePhoto(aSourceType: .photoLibrary)
        }
    }
    
    /// The method for checking the permission for access library/camera
    func takePhoto(aSourceType: UIImagePickerController.SourceType) {
        
        if !UIImagePickerController.isSourceTypeAvailable(aSourceType) {
            
            delegate?.pickerDidRejected?(self)
            
            return
        }
        
        let imageVideoPickerController: UIImagePickerController = UIImagePickerController()
        
        imageVideoPickerController.delegate = self
        imageVideoPickerController.sourceType = aSourceType
        imageVideoPickerController.allowsEditing = true
        imageVideoPickerController.mediaTypes = [mediaType.rawValue]
        imageVideoPickerController.allowsEditing = useCrop
        
        let authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
            
        case .authorized:
            
            vc?.present(imageVideoPickerController, animated: true, completion: nil)
        case .notDetermined:
            
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    
                    if granted {
                        
                        strongSelf.vc?.present(imageVideoPickerController, animated: true, completion: nil)
                    } else {
                        
                        self?.delegate?.pickerDidRejected?(strongSelf)
                    }
                }
            })
        default:
            
            delegate?.pickerDidRejected?(self)
        }
    }
    
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if mediaType == .photo {
            
            let key: UIImagePickerController.InfoKey = useCrop ? .editedImage : .originalImage
            
            if let image: UIImage = info[key] as? UIImage {
                
                delegate?.photoDidPicked?(self, image: image)
            }
            
        } else {
            
            if let videoURL: URL = info[.mediaURL] as? URL {
                
                delegate?.videoDidPicked?(self, videoUrl: videoURL)
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
}
